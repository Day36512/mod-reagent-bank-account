// SPDX-License-Identifier: AGPL-3.0-or-later
/*
 * AzerothCore module: Standalone Reagent Bank Account
 *
 * This version intentionally does not require a spawned banker NPC.
 * Players and addons use the SEC_PLAYER chat command API:
 *
 *   .rbank
 *   .rbank open
 *   .rbank list <categoryId> [page] [id|name|amount|amount_asc]
 *   .rbank preview deposit all
 *   .rbank preview deposit category <categoryId>
 *   .rbank check recipe <requestId> <itemEntry> <amountPerCraft> [itemEntry amountPerCraft ...]
 *   .rbank deposit all
 *   .rbank deposit category <categoryId>
 *   .rbank deposit item <itemEntry> <amount>
 *   .rbank deposit items <itemEntry> <amount> [itemEntry amount ...]
 *   .rbank withdraw all
 *   .rbank withdraw category <categoryId>
 *   .rbank withdraw item <itemEntry> <one|stack|all> [categoryId] [page]
 *   .rbank withdraw item <itemEntry> exact <amount> [categoryId] [page]
 *   .rbank withdraw needed <itemEntry> <amount> [itemEntry amount ...]
 *
 *
 * The matching addon listens for hidden RBANK:* system protocol lines.
 * Transaction details are emitted as:
 *   RBANK:TX:BEGIN:<deposit|withdraw>:<total>:<itemCount>
 *   RBANK:TX:ITEM:<itemEntry>:<amount>
 *   RBANK:TX:END:<deposit|withdraw>:<total>:<itemCount>
 * Deposit preview is emitted as:
 *   RBANK:PREVIEW:BEGIN:<all|category>:<categoryId>:<total>:<itemCount>
 *   RBANK:PREVIEW:ITEM:<itemEntry>:<amount>
 *   RBANK:PREVIEW:END:<all|category>:<categoryId>:<total>:<itemCount>
 * Recipe bank-count checks are emitted as:
 *   RBANK:CHECK:BEGIN:<requestId>:<itemCount>
 *   RBANK:CHECK:ITEM:<itemEntry>:<storedAmount>
 *   RBANK:CHECK:END:<requestId>:<itemCount>
 */

#include "ReagentBankAccount.h"

#include "Bag.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cerrno>
#include <cctype>
#include <cstdlib>
#include <limits>
#include <map>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

uint32 g_reagentBankMaxItemsPerPage = DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;
bool g_accountWideReagentBank = false;
bool g_reagentBankEnabled = true;
bool g_reagentBankAutoMigrate = true;

static bool g_reagentBankStorageReady = false;
static bool g_reagentBankSharingEnabled = false;
static std::unordered_set<uint32> g_reagentBankDepositExclusions;
static std::unordered_map<uint32, uint32> g_shareOwnerByKey;

using Acore::ChatCommands::ChatCommandTable;
using Acore::ChatCommands::Console;

namespace ReagentBank
{
    struct CategoryInfo
    {
        uint32 SubClass;
        char const* Name;
        uint32 SampleItem;
    };

    static constexpr std::array<CategoryInfo, 15> Categories =
    { {
        { ITEM_SUBCLASS_CLOTH,              "Cloth",             2589  },
        { ITEM_SUBCLASS_MEAT,               "Meat",              12208 },
        { ITEM_SUBCLASS_METAL_STONE,        "Metal & Stone",     2772  },
        { ITEM_SUBCLASS_ENCHANTING,         "Enchanting",        10940 },
        { ITEM_SUBCLASS_ELEMENTAL,          "Elemental",         7068  },
        { ITEM_SUBCLASS_PARTS,              "Parts",             4359  },
        { ITEM_SUBCLASS_TRADE_GOODS_OTHER,  "Other Trade Goods", 2604  },
        { ITEM_SUBCLASS_HERB,               "Herb",              2453  },
        { ITEM_SUBCLASS_LEATHER,            "Leather",           2318  },
        { ITEM_SUBCLASS_JEWELCRAFTING,      "Jewelcrafting",     1206  },
        { ITEM_SUBCLASS_EXPLOSIVES,         "Explosives",        4358  },
        { ITEM_SUBCLASS_DEVICES,            "Devices",           4388  },
        { ITEM_SUBCLASS_MATERIAL,           "Nether Material",   23572 },
        { ITEM_SUBCLASS_ARMOR_ENCHANTMENT,  "Armor Vellum",      38682 },
        { ITEM_SUBCLASS_WEAPON_ENCHANTMENT, "Weapon Vellum",     39349 }
    } };

    struct StoredItem
    {
        uint32 ItemEntry = 0;
        uint32 ItemSubclass = 0;
        uint32 Amount = 0;
    };

    enum class WithdrawMode : uint8
    {
        One,
        Stack,
        All
    };

    enum class SortMode : uint8
    {
        Id,
        Name,
        AmountDesc,
        AmountAsc
    };

    static constexpr uint32 MAX_REAGENT_BANK_STORED_AMOUNT = std::numeric_limits<uint32>::max();
    static constexpr std::size_t MAX_REAGENT_BANK_ITEM_AMOUNT_PAIRS = 80;

    using ItemAmountMap = std::map<uint32, uint32>;

    static std::string ToLower(std::string value)
    {
        for (char& c : value)
            c = char(std::tolower(static_cast<unsigned char>(c)));

        return value;
    }

    static std::vector<std::string> Tokenize(char const* args)
    {
        std::vector<std::string> tokens;

        if (!args)
            return tokens;

        std::istringstream stream(args);
        std::string token;
        while (stream >> token)
            tokens.push_back(token);

        return tokens;
    }

    static bool TryParseUInt32(std::string const& text, uint32& value)
    {
        value = 0;

        if (text.empty())
            return false;

        for (char c : text)
            if (!std::isdigit(static_cast<unsigned char>(c)))
                return false;

        errno = 0;
        char* end = nullptr;
        unsigned long long parsed = std::strtoull(text.c_str(), &end, 10);
        if (errno == ERANGE || !end || *end != '\0' || parsed > std::numeric_limits<uint32>::max())
            return false;

        value = uint32(parsed);
        return true;
    }

    static bool AddAmountChecked(uint32 current, uint32 add, uint32& out)
    {
        if (add > MAX_REAGENT_BANK_STORED_AMOUNT - current)
            return false;

        out = current + add;
        return true;
    }

    static bool AddToItemAmountMapChecked(ItemAmountMap& map, uint32 itemEntry, uint32 amount)
    {
        if (!itemEntry || !amount)
            return false;

        uint32 updated = 0;
        if (!AddAmountChecked(map[itemEntry], amount, updated))
            return false;

        map[itemEntry] = updated;
        return true;
    }

    static uint64 SumItemAmountMap(ItemAmountMap const& items)
    {
        uint64 total = 0;
        for (std::pair<uint32 const, uint32> const& item : items)
            total += item.second;

        return total;
    }

    static std::string SanitizeProtocolText(std::string text)
    {
        for (char& c : text)
            if (c == '\r' || c == '\n')
                c = ' ';

        return text;
    }

    static char const* SortModeToString(SortMode mode)
    {
        switch (mode)
        {
        case SortMode::Name:       return "name";
        case SortMode::AmountDesc: return "amount";
        case SortMode::AmountAsc:  return "amount_asc";
        case SortMode::Id:
        default:                   return "id";
        }
    }

    static SortMode ParseSortMode(std::string const& text)
    {
        std::string lower = ToLower(text);

        if (lower == "name" || lower == "alpha" || lower == "alphabetical")
            return SortMode::Name;

        if (lower == "amount" || lower == "amount_desc" || lower == "count" || lower == "count_desc")
            return SortMode::AmountDesc;

        if (lower == "amount_asc" || lower == "count_asc")
            return SortMode::AmountAsc;

        return SortMode::Id;
    }

    static bool TryParseItemAmountPairs(std::vector<std::string> const& tokens, std::size_t startIndex, std::vector<std::pair<uint32, uint32>>& pairs)
    {
        pairs.clear();

        if (startIndex >= tokens.size())
            return false;

        std::size_t const tokenCount = tokens.size() - startIndex;
        if ((tokenCount % 2) != 0)
            return false;

        std::size_t const pairCount = tokenCount / 2;
        if (pairCount == 0 || pairCount > MAX_REAGENT_BANK_ITEM_AMOUNT_PAIRS)
            return false;

        ItemAmountMap aggregated;
        for (std::size_t index = startIndex; index < tokens.size(); index += 2)
        {
            uint32 itemEntry = 0;
            uint32 amount = 0;

            if (!TryParseUInt32(tokens[index], itemEntry) || !TryParseUInt32(tokens[index + 1], amount))
                return false;

            if (!itemEntry || !amount)
                return false;

            if (!AddToItemAmountMapChecked(aggregated, itemEntry, amount))
                return false;
        }

        for (std::pair<uint32 const, uint32> const& pair : aggregated)
            pairs.emplace_back(pair.first, pair.second);

        return !pairs.empty();
    }

    static bool IsCategory(uint32 itemSubclass)
    {
        for (CategoryInfo const& category : Categories)
            if (category.SubClass == itemSubclass)
                return true;

        return false;
    }

    static CategoryInfo const* GetCategory(uint32 itemSubclass)
    {
        for (CategoryInfo const& category : Categories)
            if (category.SubClass == itemSubclass)
                return &category;

        return nullptr;
    }

    static uint32 NormalizePage(uint32 page)
    {
        return page > MAX_REAGENT_BANK_PAGE_NUMBER ? MAX_REAGENT_BANK_PAGE_NUMBER : page;
    }

    static uint32 GetPageSize()
    {
        if (g_reagentBankMaxItemsPerPage == 0)
            return DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;

        return std::min<uint32>(g_reagentBankMaxItemsPerPage, 50);
    }

    static void GetStorageKeys(Player const* player, uint32& accountKey, uint32& guidKey)
    {
        if (g_accountWideReagentBank)
        {
            uint32 const accountId = player->GetSession()->GetAccountId();
            auto const it = g_shareOwnerByKey.find(accountId);
            accountKey = it != g_shareOwnerByKey.end() ? it->second : accountId;
            guidKey = 0;
        }
        else
        {
            accountKey = 0;
            guidKey = uint32(player->GetGUID().GetCounter());
            auto const it = g_shareOwnerByKey.find(guidKey);
            if (it != g_shareOwnerByKey.end())
                guidKey = it->second;
        }
    }

    static char const* GetDesiredStorageModeName()
    {
        return g_accountWideReagentBank ? "account" : "character";
    }

    static void LoadConfig()
    {
        g_reagentBankEnabled = sConfigMgr->GetOption<bool>("ReagentBankAccount.Enable", true);
        g_accountWideReagentBank = sConfigMgr->GetOption<bool>("ReagentBankAccount.AccountWide", false);
        g_reagentBankMaxItemsPerPage = sConfigMgr->GetOption<uint32>("ReagentBankAccount.MaxItemsPerPage", DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE);
        g_reagentBankAutoMigrate = sConfigMgr->GetOption<bool>("ReagentBankAccount.AutoMigrate", true);
        g_reagentBankSharingEnabled = sConfigMgr->GetOption<bool>("ReagentBankAccount.EnableSharing", false);

        if (g_reagentBankMaxItemsPerPage == 0)
            g_reagentBankMaxItemsPerPage = DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;

        if (g_reagentBankMaxItemsPerPage > 50)
            g_reagentBankMaxItemsPerPage = 50;
    }

    static uint64 QueryUInt64(char const* sql)
    {
        QueryResult result = CharacterDatabase.Query(sql);
        if (!result)
            return 0;

        return (*result)[0].Get<uint64>();
    }

    static void EnsureStorageTables()
    {
        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account` ("
            "`account_id` INT UNSIGNED NOT NULL DEFAULT 0,"
            "`guid` INT UNSIGNED NOT NULL DEFAULT 0,"
            "`item_entry` INT UNSIGNED NOT NULL,"
            "`item_subclass` INT UNSIGNED NOT NULL,"
            "`amount` INT UNSIGNED NOT NULL DEFAULT 0,"
            "PRIMARY KEY (`account_id`, `guid`, `item_entry`),"
            "KEY `idx_mod_reagent_bank_owner_subclass` (`account_id`, `guid`, `item_subclass`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account_meta` ("
            "`setting` VARCHAR(64) NOT NULL,"
            "`value` VARCHAR(64) NOT NULL,"
            "`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`setting`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        WorldDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account_deposit_exclusions_zz_custom` ("
            "`item_entry` INT UNSIGNED NOT NULL,"
            "`comment` VARCHAR(255) NULL DEFAULT NULL,"
            "PRIMARY KEY (`item_entry`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_share_members` ("
            "`member_key` INT UNSIGNED NOT NULL,"
            "`owner_key`  INT UNSIGNED NOT NULL,"
            "`joined_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`member_key`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_share_invites` ("
            "`inviter_key` INT UNSIGNED NOT NULL,"
            "`invitee_key` INT UNSIGNED NOT NULL,"
            "`created_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`invitee_key`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        // One-time column rename for installs created before dual-mode (AccountWide=0/1) support
        QueryResult oldCol = CharacterDatabase.Query(
            "SELECT COUNT(*) FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mod_reagent_bank_share_members' "
            "AND COLUMN_NAME = 'member_account_id'");

        if (oldCol && (*oldCol)[0].Get<uint64>() > 0)
        {
            CharacterDatabase.DirectExecute(
                "ALTER TABLE `mod_reagent_bank_share_members` "
                "CHANGE COLUMN `member_account_id` `member_key` INT UNSIGNED NOT NULL, "
                "CHANGE COLUMN `owner_account_id`  `owner_key`  INT UNSIGNED NOT NULL");

            CharacterDatabase.DirectExecute(
                "ALTER TABLE `mod_reagent_bank_share_invites` "
                "CHANGE COLUMN `inviter_account_id` `inviter_key` INT UNSIGNED NOT NULL, "
                "CHANGE COLUMN `invitee_account_id` `invitee_key` INT UNSIGNED NOT NULL");

            LOG_INFO("module", "ReagentBankAccount: migrated share table columns to generic key names.");
        }
    }

    static void LoadDepositExclusions()
    {
        g_reagentBankDepositExclusions.clear();

        QueryResult result = WorldDatabase.Query(
            "SELECT `item_entry` FROM `mod_reagent_bank_account_deposit_exclusions_zz_custom`");

        if (!result)
        {
            LOG_INFO("module", "ReagentBankAccount: loaded 0 reagent bank deposit exclusion item(s).");
            return;
        }

        do
        {
            if (uint32 itemEntry = (*result)[0].Get<uint32>())
                g_reagentBankDepositExclusions.insert(itemEntry);
        } while (result->NextRow());

        LOG_INFO("module", "ReagentBankAccount: loaded {} reagent bank deposit exclusion item(s).", g_reagentBankDepositExclusions.size());
    }

    static bool IsDepositExcluded(uint32 itemEntry)
    {
        return itemEntry && g_reagentBankDepositExclusions.contains(itemEntry);
    }

    static bool IsValidCharacterName(std::string const& name)
    {
        if (name.empty() || name.size() > 12)
            return false;

        for (char c : name)
            if (!std::isalpha(static_cast<unsigned char>(c)))
                return false;

        return true;
    }

    static std::string NormalizeCharacterName(std::string name)
    {
        if (!name.empty())
        {
            name[0] = char(std::toupper(static_cast<unsigned char>(name[0])));
            for (std::size_t i = 1; i < name.size(); ++i)
                name[i] = char(std::tolower(static_cast<unsigned char>(name[i])));
        }

        return name;
    }

    static std::string GetAccountDisplayName(uint32 accountId)
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT name FROM characters WHERE account = {} ORDER BY guid ASC LIMIT 1",
            accountId);

        if (!result)
            return "";

        return (*result)[0].Get<std::string>();
    }

    // Returns the key used to identify a player's share slot.
    // AccountWide=1: account_id (all chars on the account share one bank)
    // AccountWide=0: character guid (each character has their own bank)
    static uint32 GetShareKey(Player const* player)
    {
        return g_accountWideReagentBank
            ? player->GetSession()->GetAccountId()
            : uint32(player->GetGUID().GetCounter());
    }

    static std::string GetDisplayNameByKey(uint32 key)
    {
        if (g_accountWideReagentBank)
            return GetAccountDisplayName(key);

        QueryResult r = CharacterDatabase.Query(
            "SELECT name FROM characters WHERE guid = {}", key);

        if (!r)
            return "";

        return (*r)[0].Get<std::string>();
    }

    static void LoadShareMembers()
    {
        g_shareOwnerByKey.clear();

        QueryResult result = CharacterDatabase.Query(
            "SELECT member_key, owner_key FROM mod_reagent_bank_share_members");

        if (!result)
            return;

        uint32 count = 0;
        do
        {
            uint32 const member = (*result)[0].Get<uint32>();
            uint32 const owner  = (*result)[1].Get<uint32>();

            if (member && owner && member != owner)
            {
                g_shareOwnerByKey[member] = owner;
                ++count;
            }
        } while (result->NextRow());

        if (count)
            LOG_INFO("module", "ReagentBankAccount: loaded {} reagent bank share member(s).", count);
    }

    static std::string GetStoredStorageMode()
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT `value` FROM `mod_reagent_bank_account_meta` WHERE `setting` = 'storage_mode'");

        if (!result)
            return "";

        return (*result)[0].Get<std::string>();
    }

    static void SetStoredStorageMode()
    {
        CharacterDatabase.DirectExecute(
            "INSERT INTO `mod_reagent_bank_account_meta` (`setting`, `value`) "
            "VALUES ('storage_mode', '{}') "
            "ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
            GetDesiredStorageModeName());
    }

    static void MigrateCharacterRowsToAccountRows()
    {
        uint64 const sourceRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` = 0 AND `guid` <> 0");

        if (!sourceRows)
            return;

        uint64 const orphanRows = QueryUInt64(
            "SELECT COUNT(*) "
            "FROM `mod_reagent_bank_account` r "
            "LEFT JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0 AND c.`guid` IS NULL");

        auto trans = CharacterDatabase.BeginTransaction();

        // Merge every character-scoped row into its owning account, preserving total amounts.
        trans->Append(
            "INSERT INTO `mod_reagent_bank_account` (`account_id`, `guid`, `item_entry`, `item_subclass`, `amount`) "
            "SELECT c.`account`, 0, r.`item_entry`, MIN(r.`item_subclass`), SUM(r.`amount`) "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0 "
            "GROUP BY c.`account`, r.`item_entry` "
            "ON DUPLICATE KEY UPDATE "
            "`amount` = LEAST(4294967295, `amount` + VALUES(`amount`)), "
            "`item_subclass` = VALUES(`item_subclass`)");

        trans->Append(
            "DELETE r "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0");

        CharacterDatabase.CommitTransaction(trans);

        LOG_INFO("module", "ReagentBankAccount: migrated {} character-scoped reagent bank row(s) into account-scoped storage.", sourceRows - orphanRows);

        if (orphanRows)
        {
            LOG_ERROR("module", "ReagentBankAccount: {} character-scoped reagent bank row(s) had no matching characters.guid and were left untouched.", orphanRows);
        }
    }

    static void MigrateAccountRowsToCharacterRows()
    {
        uint64 const sourceRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` <> 0 AND `guid` = 0");

        if (!sourceRows)
            return;

        uint64 const orphanRows = QueryUInt64(
            "SELECT COUNT(*) "
            "FROM `mod_reagent_bank_account` r "
            "LEFT JOIN (SELECT `account`, MIN(`guid`) AS `owner_guid` FROM `characters` GROUP BY `account`) c "
            "ON c.`account` = r.`account_id` "
            "WHERE r.`account_id` <> 0 AND r.`guid` = 0 AND c.`owner_guid` IS NULL");

        auto trans = CharacterDatabase.BeginTransaction();

        // There is no safe way to reconstruct the original character ownership once rows were merged
        // account-wide. Preserve item totals by assigning each account bank to the account's lowest GUID.
        trans->Append(
            "INSERT INTO `mod_reagent_bank_account` (`account_id`, `guid`, `item_entry`, `item_subclass`, `amount`) "
            "SELECT 0, owner.`owner_guid`, r.`item_entry`, r.`item_subclass`, r.`amount` "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN (SELECT `account`, MIN(`guid`) AS `owner_guid` FROM `characters` GROUP BY `account`) owner "
            "ON owner.`account` = r.`account_id` "
            "WHERE r.`account_id` <> 0 AND r.`guid` = 0 "
            "ON DUPLICATE KEY UPDATE "
            "`amount` = LEAST(4294967295, `amount` + VALUES(`amount`)), "
            "`item_subclass` = VALUES(`item_subclass`)");

        trans->Append(
            "DELETE FROM `mod_reagent_bank_account` "
            "WHERE `account_id` <> 0 AND `guid` = 0 "
            "AND `account_id` IN (SELECT DISTINCT `account` FROM `characters`)");

        CharacterDatabase.CommitTransaction(trans);

        LOG_INFO("module", "ReagentBankAccount: migrated {} account-scoped reagent bank row(s) into character-scoped storage.", sourceRows - orphanRows);

        if (orphanRows)
        {
            LOG_ERROR("module", "ReagentBankAccount: {} account-scoped reagent bank row(s) had no matching characters.account and were left untouched.", orphanRows);
        }
    }

    static void EnsureStorageModeMatchesConfig()
    {
        EnsureStorageTables();

        if (!g_reagentBankAutoMigrate)
        {
            LOG_INFO("module", "ReagentBankAccount: automatic storage migration is disabled. Active storage mode: {}.", GetDesiredStorageModeName());
            return;
        }

        std::string storedMode = GetStoredStorageMode();
        std::string desiredMode = GetDesiredStorageModeName();

        bool const hasCharacterRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` = 0 AND `guid` <> 0") != 0;
        bool const hasAccountRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` <> 0 AND `guid` = 0") != 0;

        if (storedMode.empty())
        {
            if (desiredMode == "account" && hasCharacterRows)
                MigrateCharacterRowsToAccountRows();
            else if (desiredMode == "character" && hasAccountRows)
                MigrateAccountRowsToCharacterRows();

            SetStoredStorageMode();
            LOG_INFO("module", "ReagentBankAccount: initialized storage mode metadata as '{}'.", desiredMode);
            return;
        }

        if (storedMode == desiredMode)
        {
            // Also heal mixed tables from older/manual edits if the active mode is clear.
            if (desiredMode == "account" && hasCharacterRows)
                MigrateCharacterRowsToAccountRows();
            else if (desiredMode == "character" && hasAccountRows)
                MigrateAccountRowsToCharacterRows();

            return;
        }

        LOG_INFO("module", "ReagentBankAccount: storage mode changed from '{}' to '{}'; migrating stored rows.", storedMode, desiredMode);

        if (desiredMode == "account")
            MigrateCharacterRowsToAccountRows();
        else
            MigrateAccountRowsToCharacterRows();

        SetStoredStorageMode();

        // Share keys (account_id vs char guid) are mode-specific — always clear on mode
        // change regardless of EnableSharing, as stale keys from the old mode are invalid
        CharacterDatabase.DirectExecute("DELETE FROM `mod_reagent_bank_share_members`");
        CharacterDatabase.DirectExecute("DELETE FROM `mod_reagent_bank_share_invites`");
        LOG_WARN("module", "ReagentBankAccount: storage mode changed from '{}' to '{}' — all share relationships cleared. Members must re-invite.", storedMode, desiredMode);
    }

    static void SendProtocol(ChatHandler* handler, std::string const& line)
    {
        if (!handler)
            return;

        handler->SendSysMessage(line.c_str());
    }

    static void SendOk(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:OK:{}", SanitizeProtocolText(message)));
    }

    static void SendError(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:ERR:{}", SanitizeProtocolText(message)));
    }

    static void NotifyOnlineAccountPlayers(uint32 targetAccountId, std::string const& protocolLine); // defined below
    static void NotifyPlayersByKey(uint32 key, std::string const& protocolLine);                    // defined below

    static void SendTransaction(ChatHandler* handler, char const* action, ItemAmountMap const& items)
    {
        if (!handler || !action || items.empty())
            return;

        uint64 const total = SumItemAmountMap(items);

        SendProtocol(handler, Acore::StringFormat("RBANK:TX:BEGIN:{}:{}:{}", action, total, uint32(items.size())));

        for (std::pair<uint32 const, uint32> const& item : items)
            SendProtocol(handler, Acore::StringFormat("RBANK:TX:ITEM:{}:{}", item.first, item.second));

        SendProtocol(handler, Acore::StringFormat("RBANK:TX:END:{}:{}:{}", action, total, uint32(items.size())));

        if (!g_reagentBankSharingEnabled || !handler->GetSession() || !handler->GetSession()->GetPlayer())
            return;

        uint32 const actorKey = GetShareKey(handler->GetSession()->GetPlayer());
        auto const it = g_shareOwnerByKey.find(actorKey);
        uint32 const ownerKey = it != g_shareOwnerByKey.end() ? it->second : actorKey;

        if (ownerKey != actorKey)
            NotifyPlayersByKey(ownerKey, "RBANK:SHARE:REFRESH");

        QueryResult members = CharacterDatabase.Query(
            "SELECT member_key FROM mod_reagent_bank_share_members WHERE owner_key = {}",
            ownerKey);

        if (members)
        {
            do
            {
                uint32 const memberKey = (*members)[0].Get<uint32>();
                if (memberKey != actorKey)
                    NotifyPlayersByKey(memberKey, "RBANK:SHARE:REFRESH");
            } while (members->NextRow());
        }
    }

    static void SendDepositPreview(ChatHandler* handler, char const* scope, uint32 category, ItemAmountMap const& items)
    {
        if (!handler || !scope)
            return;

        uint64 const total = SumItemAmountMap(items);

        SendProtocol(handler, Acore::StringFormat("RBANK:PREVIEW:BEGIN:{}:{}:{}:{}", scope, category, total, uint32(items.size())));

        for (std::pair<uint32 const, uint32> const& item : items)
            SendProtocol(handler, Acore::StringFormat("RBANK:PREVIEW:ITEM:{}:{}", item.first, item.second));

        SendProtocol(handler, Acore::StringFormat("RBANK:PREVIEW:END:{}:{}:{}:{}", scope, category, total, uint32(items.size())));
    }

    static bool IsStorableReagent(ItemTemplate const* proto, uint32& itemEntry, uint32& itemSubclass)
    {
        if (!proto)
            return false;

        if (!(proto->Class == ITEM_CLASS_TRADE_GOODS || proto->Class == ITEM_CLASS_GEM))
            return false;

        if (proto->GetMaxStackSize() <= 1)
            return false;

        itemEntry = proto->ItemId;
        itemSubclass = proto->Class == ITEM_CLASS_GEM ? ITEM_SUBCLASS_JEWELCRAFTING : proto->SubClass;

        return IsCategory(itemSubclass);
    }

    static void LoadStoredItems(Player const* player, std::map<uint32, StoredItem>& items)
    {
        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {}",
            accountKey, guidKey);

        if (!result)
            return;

        do
        {
            StoredItem item;
            item.ItemEntry = (*result)[0].Get<uint32>();
            item.ItemSubclass = (*result)[1].Get<uint32>();
            item.Amount = (*result)[2].Get<uint32>();

            if (item.ItemEntry && item.Amount && IsCategory(item.ItemSubclass))
                items[item.ItemEntry] = item;
        } while (result->NextRow());
    }

    static void SaveStoredItems(Player const* player, std::map<uint32, StoredItem> const& changedItems)
    {
        if (changedItems.empty())
            return;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        auto trans = CharacterDatabase.BeginTransaction();

        for (std::pair<uint32 const, StoredItem> const& pair : changedItems)
        {
            StoredItem const& item = pair.second;

            trans->Append(
                "DELETE FROM mod_reagent_bank_account "
                "WHERE account_id = {} AND guid = {} AND item_entry = {}",
                accountKey, guidKey, item.ItemEntry);

            if (item.Amount)
            {
                trans->Append(
                    "INSERT INTO mod_reagent_bank_account "
                    "(account_id, guid, item_entry, item_subclass, amount) "
                    "VALUES ({}, {}, {}, {}, {})",
                    accountKey, guidKey, item.ItemEntry, item.ItemSubclass, item.Amount);
            }
        }

        CharacterDatabase.CommitTransaction(trans);
    }

    static void QueryCategoryTotals(Player const* player, uint32 category, uint32& typeCount, uint64& totalAmount)
    {
        typeCount = 0;
        totalAmount = 0;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT COUNT(*), COALESCE(SUM(amount), 0) "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {}",
            accountKey, guidKey, category);

        if (!result)
            return;

        uint64 const rawTypeCount = (*result)[0].Get<uint64>();
        typeCount = rawTypeCount > std::numeric_limits<uint32>::max() ? std::numeric_limits<uint32>::max() : uint32(rawTypeCount);
        totalAmount = (*result)[1].Get<uint64>();
    }

    static void SendRoot(ChatHandler* handler, Player const* player)
    {
        if (!handler || !player)
            return;

        SendProtocol(handler, Acore::StringFormat("RBANK:BEGIN:ROOT:{}", g_accountWideReagentBank ? 1 : 0));
        SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:FEATURE:{}", g_reagentBankSharingEnabled ? 1 : 0));

        for (CategoryInfo const& category : Categories)
        {
            uint32 typeCount = 0;
            uint64 totalAmount = 0;
            QueryCategoryTotals(player, category.SubClass, typeCount, totalAmount);

            SendProtocol(handler, Acore::StringFormat(
                "RBANK:CAT:{}:{}:{}:{}",
                category.SubClass,
                category.SampleItem,
                typeCount,
                totalAmount));
        }

        SendProtocol(handler, "RBANK:END:ROOT");
    }

    static void SendCategory(ChatHandler* handler, Player const* player, uint32 category, uint32 requestedPage, SortMode sortMode = SortMode::Id)
    {
        if (!handler || !player)
            return;

        CategoryInfo const* categoryInfo = GetCategory(category);
        if (!categoryInfo)
        {
            SendError(handler, "Unknown reagent category.");
            SendRoot(handler, player);
            return;
        }

        uint32 typeCount = 0;
        uint64 totalAmount = 0;
        QueryCategoryTotals(player, category, typeCount, totalAmount);

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        std::vector<StoredItem> items;
        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {}",
            accountKey, guidKey, category);

        if (result)
        {
            do
            {
                StoredItem item;
                item.ItemEntry = (*result)[0].Get<uint32>();
                item.ItemSubclass = (*result)[1].Get<uint32>();
                item.Amount = (*result)[2].Get<uint32>();

                if (item.ItemEntry && item.Amount && IsCategory(item.ItemSubclass))
                    items.push_back(item);
            } while (result->NextRow());
        }

        std::stable_sort(items.begin(), items.end(), [sortMode](StoredItem const& left, StoredItem const& right)
            {
                if (sortMode == SortMode::AmountDesc)
                {
                    if (left.Amount != right.Amount)
                        return left.Amount > right.Amount;
                }
                else if (sortMode == SortMode::AmountAsc)
                {
                    if (left.Amount != right.Amount)
                        return left.Amount < right.Amount;
                }
                else if (sortMode == SortMode::Name)
                {
                    ItemTemplate const* leftProto = sObjectMgr->GetItemTemplate(left.ItemEntry);
                    ItemTemplate const* rightProto = sObjectMgr->GetItemTemplate(right.ItemEntry);

                    std::string const leftName = leftProto ? leftProto->Name1 : "";
                    std::string const rightName = rightProto ? rightProto->Name1 : "";
                    if (leftName != rightName)
                        return leftName < rightName;
                }

                return left.ItemEntry < right.ItemEntry;
            });

        uint32 const pageSize = GetPageSize();
        uint32 totalPages = typeCount == 0 ? 1 : ((typeCount + pageSize - 1) / pageSize);
        uint32 page = NormalizePage(requestedPage);
        if (page >= totalPages)
            page = totalPages - 1;

        uint32 offset = page * pageSize;

        SendProtocol(handler, Acore::StringFormat(
            "RBANK:BEGIN:CATEGORY:{}:{}:{}:{}:{}:{}",
            category,
            page,
            totalPages,
            typeCount,
            totalAmount,
            SortModeToString(sortMode)));

        for (uint32 index = offset; index < items.size() && index < offset + pageSize; ++index)
        {
            StoredItem const& item = items[index];
            SendProtocol(handler, Acore::StringFormat("RBANK:ITEM:{}:{}", item.ItemEntry, item.Amount));
        }

        SendProtocol(handler, "RBANK:END:CATEGORY");
    }

    static uint32 DepositFromSlot(Player* player, uint8 bagSlot, uint8 itemSlot, uint32 onlyCategory, std::map<uint32, StoredItem>& storedItems, ItemAmountMap& deposited, bool& overflowed)
    {
        Item* item = player->GetItemByPos(bagSlot, itemSlot);
        if (!item)
            return 0;

        uint32 itemEntry = 0;
        uint32 itemSubclass = 0;
        if (!IsStorableReagent(item->GetTemplate(), itemEntry, itemSubclass))
            return 0;

        if (IsDepositExcluded(itemEntry))
            return 0;

        if (onlyCategory && itemSubclass != onlyCategory)
            return 0;

        uint32 const count = item->GetCount();
        if (!count)
            return 0;

        StoredItem& stored = storedItems[itemEntry];
        stored.ItemEntry = itemEntry;
        stored.ItemSubclass = itemSubclass;

        uint32 updatedStoredAmount = 0;
        if (!AddAmountChecked(stored.Amount, count, updatedStoredAmount) || !AddToItemAmountMapChecked(deposited, itemEntry, count))
        {
            overflowed = true;
            LOG_ERROR("module", "ReagentBankAccount: refused deposit overflow for player {} item {} count {} stored {}.",
                player->GetGUID().ToString(), itemEntry, count, stored.Amount);
            return 0;
        }

        stored.Amount = updatedStoredAmount;

        player->DestroyItem(bagSlot, itemSlot, true);
        return count;
    }

    static uint32 Deposit(Player* player, uint32 onlyCategory, ItemAmountMap& deposited, bool& overflowed)
    {
        deposited.clear();
        overflowed = false;

        if (!player)
            return 0;

        std::map<uint32, StoredItem> storedItems;
        LoadStoredItems(player, storedItems);

        uint32 totalDeposited = 0;

        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        {
            uint32 const depositedFromSlot = DepositFromSlot(player, INVENTORY_SLOT_BAG_0, slot, onlyCategory, storedItems, deposited, overflowed);
            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalDeposited, depositedFromSlot, updatedTotal))
                totalDeposited = updatedTotal;
            else
            {
                overflowed = true;
                break;
            }
        }

        for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        {
            Bag* bag = player->GetBagByPos(bagSlot);
            if (!bag)
                continue;

            for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
            {
                uint32 const depositedFromSlot = DepositFromSlot(player, bagSlot, uint8(slot), onlyCategory, storedItems, deposited, overflowed);
                uint32 updatedTotal = 0;
                if (AddAmountChecked(totalDeposited, depositedFromSlot, updatedTotal))
                    totalDeposited = updatedTotal;
                else
                {
                    overflowed = true;
                    break;
                }
            }

            if (overflowed)
                break;
        }

        std::map<uint32, StoredItem> changedItems;
        for (std::pair<uint32 const, uint32> const& pair : deposited)
        {
            std::map<uint32, StoredItem>::const_iterator storedItr = storedItems.find(pair.first);
            if (storedItr != storedItems.end())
                changedItems[pair.first] = storedItr->second;
        }

        SaveStoredItems(player, changedItems);
        return totalDeposited;
    }


    static uint32 PreviewDepositFromSlot(Player* player, uint8 bagSlot, uint8 itemSlot, uint32 onlyCategory, std::map<uint32, StoredItem>& simulatedStoredItems, ItemAmountMap& previewItems, bool& overflowed)
    {
        Item* item = player->GetItemByPos(bagSlot, itemSlot);
        if (!item)
            return 0;

        uint32 itemEntry = 0;
        uint32 itemSubclass = 0;
        if (!IsStorableReagent(item->GetTemplate(), itemEntry, itemSubclass))
            return 0;

        if (IsDepositExcluded(itemEntry))
            return 0;

        if (onlyCategory && itemSubclass != onlyCategory)
            return 0;

        uint32 const count = item->GetCount();
        if (!count)
            return 0;

        StoredItem& stored = simulatedStoredItems[itemEntry];
        stored.ItemEntry = itemEntry;
        stored.ItemSubclass = itemSubclass;

        uint32 updatedStoredAmount = 0;
        if (!AddAmountChecked(stored.Amount, count, updatedStoredAmount) || !AddToItemAmountMapChecked(previewItems, itemEntry, count))
        {
            overflowed = true;
            return 0;
        }

        stored.Amount = updatedStoredAmount;
        return count;
    }

    static uint32 CollectDepositPreview(Player* player, uint32 onlyCategory, ItemAmountMap& previewItems, bool& overflowed)
    {
        previewItems.clear();
        overflowed = false;

        if (!player)
            return 0;

        std::map<uint32, StoredItem> simulatedStoredItems;
        LoadStoredItems(player, simulatedStoredItems);

        uint32 totalPreviewed = 0;

        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        {
            uint32 const previewedFromSlot = PreviewDepositFromSlot(player, INVENTORY_SLOT_BAG_0, slot, onlyCategory, simulatedStoredItems, previewItems, overflowed);
            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalPreviewed, previewedFromSlot, updatedTotal))
                totalPreviewed = updatedTotal;
            else
            {
                overflowed = true;
                break;
            }
        }

        for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        {
            Bag* bag = player->GetBagByPos(bagSlot);
            if (!bag)
                continue;

            for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
            {
                uint32 const previewedFromSlot = PreviewDepositFromSlot(player, bagSlot, uint8(slot), onlyCategory, simulatedStoredItems, previewItems, overflowed);
                uint32 updatedTotal = 0;
                if (AddAmountChecked(totalPreviewed, previewedFromSlot, updatedTotal))
                    totalPreviewed = updatedTotal;
                else
                {
                    overflowed = true;
                    break;
                }
            }

            if (overflowed)
                break;
        }

        return totalPreviewed;
    }

    static uint32 DepositSpecificItems(Player* player, std::vector<std::pair<uint32, uint32>> const& requestedItems, ItemAmountMap& deposited, bool& overflowed)
    {
        deposited.clear();
        overflowed = false;

        if (!player || requestedItems.empty())
            return 0;

        std::map<uint32, StoredItem> storedItems;
        LoadStoredItems(player, storedItems);

        uint32 totalDeposited = 0;

        for (std::pair<uint32, uint32> const& requested : requestedItems)
        {
            uint32 const requestedItemEntry = requested.first;
            uint32 const requestedAmount = requested.second;

            if (!requestedItemEntry || !requestedAmount)
                continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(requestedItemEntry);
            uint32 itemEntry = 0;
            uint32 itemSubclass = 0;
            if (!IsStorableReagent(proto, itemEntry, itemSubclass))
                continue;

            if (IsDepositExcluded(itemEntry))
                continue;

            uint32 const availableInBags = player->GetItemCount(itemEntry, false);
            uint32 const amountToDeposit = std::min<uint32>(requestedAmount, availableInBags);
            if (!amountToDeposit)
                continue;

            StoredItem& stored = storedItems[itemEntry];
            stored.ItemEntry = itemEntry;
            stored.ItemSubclass = itemSubclass;

            uint32 updatedStoredAmount = 0;
            if (!AddAmountChecked(stored.Amount, amountToDeposit, updatedStoredAmount) || !AddToItemAmountMapChecked(deposited, itemEntry, amountToDeposit))
            {
                overflowed = true;
                LOG_ERROR("module", "ReagentBankAccount: refused specific deposit overflow for player {} item {} count {} stored {}.",
                    player->GetGUID().ToString(), itemEntry, amountToDeposit, stored.Amount);
                continue;
            }

            // Match the existing deposit behavior: remove bag items, then persist the virtual balance.
            player->DestroyItemCount(itemEntry, amountToDeposit, true);
            stored.Amount = updatedStoredAmount;

            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalDeposited, amountToDeposit, updatedTotal))
                totalDeposited = updatedTotal;
            else
            {
                overflowed = true;
                break;
            }
        }

        std::map<uint32, StoredItem> changedItems;
        for (std::pair<uint32 const, uint32> const& pair : deposited)
        {
            std::map<uint32, StoredItem>::const_iterator storedItr = storedItems.find(pair.first);
            if (storedItr != storedItems.end())
                changedItems[pair.first] = storedItr->second;
        }

        SaveStoredItems(player, changedItems);
        return totalDeposited;
    }

    static bool LoadStoredItem(Player const* player, uint32 itemEntry, StoredItem& item)
    {
        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_entry = {}",
            accountKey, guidKey, itemEntry);

        if (!result)
            return false;

        item.ItemEntry = (*result)[0].Get<uint32>();
        item.ItemSubclass = (*result)[1].Get<uint32>();
        item.Amount = (*result)[2].Get<uint32>();

        return item.ItemEntry && item.Amount && IsCategory(item.ItemSubclass);
    }


    static void SendRecipeCheck(ChatHandler* handler, Player const* player, uint32 requestId, std::vector<std::pair<uint32, uint32>> const& requestedItems)
    {
        if (!handler || !player)
            return;

        SendProtocol(handler, Acore::StringFormat("RBANK:CHECK:BEGIN:{}:{}", requestId, uint32(requestedItems.size())));

        for (std::pair<uint32, uint32> const& requested : requestedItems)
        {
            uint32 const itemEntry = requested.first;
            uint32 storedAmount = 0;

            StoredItem stored;
            if (itemEntry && LoadStoredItem(player, itemEntry, stored))
                storedAmount = stored.Amount;

            SendProtocol(handler, Acore::StringFormat("RBANK:CHECK:ITEM:{}:{}", itemEntry, storedAmount));
        }

        SendProtocol(handler, Acore::StringFormat("RBANK:CHECK:END:{}:{}", requestId, uint32(requestedItems.size())));
    }

    static uint32 WithdrawExact(Player* player, StoredItem& stored, uint32 requestedAmount, bool& stoppedForBagSpace, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(stored.ItemEntry);
        if (!proto)
            return 0;

        uint32 remainingRequest = std::min<uint32>(requestedAmount, stored.Amount);
        uint32 withdrawnAmount = 0;
        uint32 stackSize = std::max<uint32>(1, proto->GetMaxStackSize());

        while (remainingRequest)
        {
            uint32 toGive = std::min<uint32>(stackSize, remainingRequest);

            ItemPosCountVec dest;
            InventoryResult msg = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, stored.ItemEntry, toGive);
            if (msg != EQUIP_ERR_OK)
            {
                player->SendEquipError(msg, nullptr, nullptr, stored.ItemEntry);
                stoppedForBagSpace = true;
                break;
            }

            Item* item = player->StoreNewItem(dest, stored.ItemEntry, true);
            if (!item)
            {
                stoppedForBagSpace = true;
                break;
            }

            player->SendNewItem(item, toGive, true, false);

            uint32 updatedWithdrawnAmount = 0;
            if (!AddAmountChecked(withdrawnAmount, toGive, updatedWithdrawnAmount) || !AddToItemAmountMapChecked(withdrawn, stored.ItemEntry, toGive))
            {
                LOG_ERROR("module", "ReagentBankAccount: transaction amount overflow while withdrawing player {} item {} count {}.",
                    player->GetGUID().ToString(), stored.ItemEntry, toGive);
                break;
            }

            withdrawnAmount = updatedWithdrawnAmount;
            remainingRequest -= toGive;
            stored.Amount -= toGive;
        }

        std::map<uint32, StoredItem> changed;
        changed[stored.ItemEntry] = stored;
        SaveStoredItems(player, changed);

        return withdrawnAmount;
    }

    static uint32 WithdrawItem(Player* player, uint32 itemEntry, WithdrawMode mode, bool& stoppedForBagSpace, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;

        StoredItem stored;
        if (!LoadStoredItem(player, itemEntry, stored))
            return 0;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemEntry);
        if (!proto)
            return 0;

        uint32 requested = 0;
        switch (mode)
        {
        case WithdrawMode::One:
            requested = 1;
            break;
        case WithdrawMode::Stack:
            requested = std::max<uint32>(1, proto->GetMaxStackSize());
            break;
        case WithdrawMode::All:
            requested = stored.Amount;
            break;
        }

        return WithdrawExact(player, stored, requested, stoppedForBagSpace, withdrawn);
    }

    static uint32 WithdrawItemAmount(Player* player, uint32 itemEntry, uint32 requestedAmount, bool& stoppedForBagSpace, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;

        if (!requestedAmount)
            return 0;

        StoredItem stored;
        if (!LoadStoredItem(player, itemEntry, stored))
            return 0;

        return WithdrawExact(player, stored, requestedAmount, stoppedForBagSpace, withdrawn);
    }

    static uint32 WithdrawSpecificItems(Player* player, std::vector<std::pair<uint32, uint32>> const& requestedItems, bool& stoppedForBagSpace, uint32& incompleteItems, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;
        incompleteItems = 0;

        if (!player || requestedItems.empty())
            return 0;

        uint32 totalWithdrawn = 0;

        for (std::pair<uint32, uint32> const& requested : requestedItems)
        {
            uint32 const itemEntry = requested.first;
            uint32 const requestedAmount = requested.second;

            if (!itemEntry || !requestedAmount)
                continue;

            bool full = false;
            uint32 const itemWithdrawn = WithdrawItemAmount(player, itemEntry, requestedAmount, full, withdrawn);

            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalWithdrawn, itemWithdrawn, updatedTotal))
                totalWithdrawn = updatedTotal;
            else
                break;

            if (itemWithdrawn < requestedAmount)
                ++incompleteItems;

            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        }

        return totalWithdrawn;
    }

    static uint32 WithdrawCategory(Player* player, uint32 category, bool& stoppedForBagSpace, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;

        if (!IsCategory(category))
            return 0;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {} "
            "ORDER BY item_entry ASC",
            accountKey, guidKey, category);

        if (!result)
            return 0;

        uint32 totalWithdrawn = 0;

        do
        {
            StoredItem stored;
            stored.ItemEntry = (*result)[0].Get<uint32>();
            stored.ItemSubclass = (*result)[1].Get<uint32>();
            stored.Amount = (*result)[2].Get<uint32>();

            bool full = false;
            uint32 const itemWithdrawn = WithdrawExact(player, stored, stored.Amount, full, withdrawn);

            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalWithdrawn, itemWithdrawn, updatedTotal))
                totalWithdrawn = updatedTotal;
            else
                break;

            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        } while (result->NextRow());

        return totalWithdrawn;
    }

    static uint32 WithdrawAll(Player* player, bool& stoppedForBagSpace, ItemAmountMap& withdrawn)
    {
        stoppedForBagSpace = false;

        uint32 totalWithdrawn = 0;
        for (CategoryInfo const& category : Categories)
        {
            bool full = false;
            uint32 const categoryWithdrawn = WithdrawCategory(player, category.SubClass, full, withdrawn);

            uint32 updatedTotal = 0;
            if (AddAmountChecked(totalWithdrawn, categoryWithdrawn, updatedTotal))
                totalWithdrawn = updatedTotal;
            else
                break;

            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        }

        return totalWithdrawn;
    }

    static bool ParseWithdrawMode(std::string const& text, WithdrawMode& mode)
    {
        std::string lower = ToLower(text);

        if (lower == "one" || lower == "1")
        {
            mode = WithdrawMode::One;
            return true;
        }

        if (lower == "stack")
        {
            mode = WithdrawMode::Stack;
            return true;
        }

        if (lower == "all")
        {
            mode = WithdrawMode::All;
            return true;
        }

        return false;
    }

    static void SendShareOk(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:OK:{}", SanitizeProtocolText(message)));
    }

    static void SendShareError(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:ERR:{}", SanitizeProtocolText(message)));
    }

    static void NotifyOnlineAccountPlayers(uint32 targetAccountId, std::string const& protocolLine)
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT guid FROM characters WHERE account = {}",
            targetAccountId);

        if (!result)
            return;

        do
        {
            uint32 const lowGuid = (*result)[0].Get<uint32>();
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(lowGuid);
            Player* target = ObjectAccessor::FindPlayer(guid);

            if (target && target->GetSession())
            {
                ChatHandler targetHandler(target->GetSession());
                SendProtocol(&targetHandler, protocolLine);
            }
        } while (result->NextRow());
    }

    // Notifies the player(s) represented by key.
    // AccountWide=1: notifies all online characters on that account.
    // AccountWide=0: notifies that specific character by guid.
    static void NotifyPlayersByKey(uint32 key, std::string const& protocolLine)
    {
        if (g_accountWideReagentBank)
        {
            NotifyOnlineAccountPlayers(key, protocolLine);
            return;
        }

        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(key);
        Player* target = ObjectAccessor::FindPlayer(guid);
        if (target && target->GetSession())
        {
            ChatHandler targetHandler(target->GetSession());
            SendProtocol(&targetHandler, protocolLine);
        }
    }

    static void SendShareOpen(ChatHandler* handler, Player const* player)
    {
        uint32 const playerKey = GetShareKey(player);

        auto const memberIt = g_shareOwnerByKey.find(playerKey);
        if (memberIt != g_shareOwnerByKey.end())
        {
            std::string const ownerName = GetDisplayNameByKey(memberIt->second);
            SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:BEGIN:member:{}", SanitizeProtocolText(ownerName)));
            SendProtocol(handler, "RBANK:SHARE:END");
            return;
        }

        SendProtocol(handler, "RBANK:SHARE:BEGIN:owner:");

        QueryResult result = CharacterDatabase.Query(
            "SELECT member_key FROM mod_reagent_bank_share_members WHERE owner_key = {} ORDER BY joined_at ASC",
            playerKey);

        if (result)
        {
            do
            {
                uint32 const memberKey = (*result)[0].Get<uint32>();
                SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:ITEM:{}", SanitizeProtocolText(GetDisplayNameByKey(memberKey))));
            } while (result->NextRow());
        }

        SendProtocol(handler, "RBANK:SHARE:END");
    }

    static void HandleShareInvite(ChatHandler* handler, Player* player, std::string const& inviteeNameRaw)
    {
        if (!IsValidCharacterName(inviteeNameRaw))
        {
            SendShareError(handler, "Invalid character name.");
            return;
        }

        std::string const inviteeName = NormalizeCharacterName(inviteeNameRaw);
        uint32 const inviterKey = GetShareKey(player);

        if (g_shareOwnerByKey.count(inviterKey))
        {
            SendShareError(handler, "You are a member of another shared bank. Leave it before inviting others.");
            return;
        }

        // AccountWide=1: key is account_id; AccountWide=0: key is character guid
        QueryResult charResult = CharacterDatabase.Query(
            "SELECT account, guid FROM characters WHERE name = '{}'", inviteeName);

        if (!charResult)
        {
            SendShareError(handler, Acore::StringFormat("Character '{}' not found.", inviteeName));
            return;
        }

        uint32 const inviteeKey = g_accountWideReagentBank
            ? (*charResult)[0].Get<uint32>()  // account_id
            : (*charResult)[1].Get<uint32>(); // char guid

        if (inviteeKey == inviterKey)
        {
            SendShareError(handler, "You cannot invite yourself.");
            return;
        }

        if (g_shareOwnerByKey.count(inviteeKey))
        {
            SendShareError(handler, Acore::StringFormat("{} is already part of another shared bank arrangement.", inviteeName));
            return;
        }

        QueryResult memberCheck = CharacterDatabase.Query(
            "SELECT COUNT(*) FROM mod_reagent_bank_share_members WHERE owner_key = {}",
            inviteeKey);

        if (memberCheck && (*memberCheck)[0].Get<uint64>() > 0)
        {
            SendShareError(handler, Acore::StringFormat("{} is already part of another shared bank arrangement.", inviteeName));
            return;
        }

        CharacterDatabase.DirectExecute(
            "INSERT INTO mod_reagent_bank_share_invites (inviter_key, invitee_key) "
            "VALUES ({}, {}) "
            "ON DUPLICATE KEY UPDATE inviter_key = {}, created_at = CURRENT_TIMESTAMP",
            inviterKey, inviteeKey, inviterKey);

        std::string const inviterName = GetDisplayNameByKey(inviterKey);
        NotifyPlayersByKey(inviteeKey, Acore::StringFormat("RBANK:SHARE:INVITE:{}", SanitizeProtocolText(inviterName)));

        SendShareOk(handler, Acore::StringFormat("Invite sent to {}.", inviteeName));
        SendShareOpen(handler, player);
    }

    static void HandleShareAccept(ChatHandler* handler, Player* player)
    {
        uint32 const memberKey = GetShareKey(player);

        if (g_shareOwnerByKey.count(memberKey))
        {
            SendShareError(handler, "You are already a member of a shared bank.");
            return;
        }

        QueryResult inviteResult = CharacterDatabase.Query(
            "SELECT inviter_key FROM mod_reagent_bank_share_invites WHERE invitee_key = {}",
            memberKey);

        if (!inviteResult)
        {
            SendShareError(handler, "You have no pending invite to accept.");
            return;
        }

        uint32 const ownerKey = (*inviteResult)[0].Get<uint32>();

        if (g_shareOwnerByKey.count(ownerKey))
        {
            CharacterDatabase.DirectExecute(
                "DELETE FROM mod_reagent_bank_share_invites WHERE invitee_key = {}",
                memberKey);
            SendShareError(handler, "The inviter is no longer available as a bank owner. Invite cancelled.");
            return;
        }

        auto trans = CharacterDatabase.BeginTransaction();

        // Merge member's bank into owner's bank.
        // VALUES() is ambiguous in INSERT...SELECT ON DUPLICATE KEY in MySQL 8.0, so use UPDATE+JOIN.
        // AccountWide=1: storage key = account_id, guid column = 0
        // AccountWide=0: storage key = char guid,  account_id column = 0
        if (g_accountWideReagentBank)
        {
            trans->Append(
                "UPDATE mod_reagent_bank_account tgt "
                "JOIN mod_reagent_bank_account src "
                "  ON src.account_id = {} AND src.guid = 0 AND tgt.item_entry = src.item_entry "
                "SET tgt.amount = LEAST(4294967295, tgt.amount + src.amount), "
                "    tgt.item_subclass = src.item_subclass "
                "WHERE tgt.account_id = {} AND tgt.guid = 0",
                memberKey, ownerKey);

            trans->Append(
                "INSERT INTO mod_reagent_bank_account (account_id, guid, item_entry, item_subclass, amount) "
                "SELECT {}, 0, src.item_entry, src.item_subclass, src.amount "
                "FROM mod_reagent_bank_account src "
                "LEFT JOIN mod_reagent_bank_account tgt "
                "  ON tgt.account_id = {} AND tgt.guid = 0 AND tgt.item_entry = src.item_entry "
                "WHERE src.account_id = {} AND src.guid = 0 "
                "  AND tgt.item_entry IS NULL",
                ownerKey, ownerKey, memberKey);

            trans->Append(
                "DELETE FROM mod_reagent_bank_account WHERE account_id = {} AND guid = 0",
                memberKey);
        }
        else
        {
            trans->Append(
                "UPDATE mod_reagent_bank_account tgt "
                "JOIN mod_reagent_bank_account src "
                "  ON src.account_id = 0 AND src.guid = {} AND tgt.item_entry = src.item_entry "
                "SET tgt.amount = LEAST(4294967295, tgt.amount + src.amount), "
                "    tgt.item_subclass = src.item_subclass "
                "WHERE tgt.account_id = 0 AND tgt.guid = {}",
                memberKey, ownerKey);

            trans->Append(
                "INSERT INTO mod_reagent_bank_account (account_id, guid, item_entry, item_subclass, amount) "
                "SELECT 0, {}, src.item_entry, src.item_subclass, src.amount "
                "FROM mod_reagent_bank_account src "
                "LEFT JOIN mod_reagent_bank_account tgt "
                "  ON tgt.account_id = 0 AND tgt.guid = {} AND tgt.item_entry = src.item_entry "
                "WHERE src.account_id = 0 AND src.guid = {} "
                "  AND tgt.item_entry IS NULL",
                ownerKey, ownerKey, memberKey);

            trans->Append(
                "DELETE FROM mod_reagent_bank_account WHERE account_id = 0 AND guid = {}",
                memberKey);
        }

        trans->Append(
            "INSERT INTO mod_reagent_bank_share_members (member_key, owner_key) "
            "VALUES ({}, {}) "
            "ON DUPLICATE KEY UPDATE owner_key = {}, joined_at = CURRENT_TIMESTAMP",
            memberKey, ownerKey, ownerKey);

        trans->Append(
            "DELETE FROM mod_reagent_bank_share_invites WHERE invitee_key = {}",
            memberKey);

        CharacterDatabase.CommitTransaction(trans);

        g_shareOwnerByKey[memberKey] = ownerKey;

        std::string const ownerName = GetDisplayNameByKey(ownerKey);
        SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:ACCEPTED:{}", SanitizeProtocolText(ownerName)));

        std::string const memberName = GetDisplayNameByKey(memberKey);
        NotifyPlayersByKey(ownerKey, Acore::StringFormat("RBANK:SHARE:JOINED:{}", SanitizeProtocolText(memberName)));

        LOG_INFO("module", "ReagentBankAccount: key {} joined key {}'s shared bank.", memberKey, ownerKey);
    }

    static void HandleShareDecline(ChatHandler* handler, Player* player)
    {
        uint32 const inviteeKey = GetShareKey(player);

        QueryResult result = CharacterDatabase.Query(
            "SELECT inviter_key FROM mod_reagent_bank_share_invites WHERE invitee_key = {}",
            inviteeKey);

        if (!result)
        {
            SendShareError(handler, "You have no pending invite to decline.");
            return;
        }

        CharacterDatabase.DirectExecute(
            "DELETE FROM mod_reagent_bank_share_invites WHERE invitee_key = {}",
            inviteeKey);

        SendShareOk(handler, "Invite declined.");
    }

    static void HandleShareLeave(ChatHandler* handler, Player* player)
    {
        uint32 const memberKey = GetShareKey(player);

        auto const it = g_shareOwnerByKey.find(memberKey);
        if (it == g_shareOwnerByKey.end())
        {
            SendShareError(handler, "You are not a member of any shared bank.");
            return;
        }

        uint32 const ownerKey = it->second;

        CharacterDatabase.DirectExecute(
            "DELETE FROM mod_reagent_bank_share_members WHERE member_key = {}",
            memberKey);

        g_shareOwnerByKey.erase(memberKey);

        std::string const ownerName = GetDisplayNameByKey(ownerKey);
        SendProtocol(handler, Acore::StringFormat("RBANK:SHARE:LEFT_SELF:{}", SanitizeProtocolText(ownerName)));

        std::string const memberName = GetDisplayNameByKey(memberKey);
        NotifyPlayersByKey(ownerKey, Acore::StringFormat("RBANK:SHARE:LEFT:{}", SanitizeProtocolText(memberName)));

        LOG_INFO("module", "ReagentBankAccount: key {} left key {}'s shared bank.", memberKey, ownerKey);
    }

    static void HandleShareKick(ChatHandler* handler, Player* player, std::string const& memberNameRaw)
    {
        if (!IsValidCharacterName(memberNameRaw))
        {
            SendShareError(handler, "Invalid character name.");
            return;
        }

        std::string const memberName = NormalizeCharacterName(memberNameRaw);
        uint32 const ownerKey = GetShareKey(player);

        if (g_shareOwnerByKey.count(ownerKey))
        {
            SendShareError(handler, "You are a member of another shared bank and cannot kick members.");
            return;
        }

        // AccountWide=1: key is account_id; AccountWide=0: key is character guid
        QueryResult charResult = CharacterDatabase.Query(
            "SELECT account, guid FROM characters WHERE name = '{}'", memberName);

        if (!charResult)
        {
            SendShareError(handler, Acore::StringFormat("Character '{}' not found.", memberName));
            return;
        }

        uint32 const memberKey = g_accountWideReagentBank
            ? (*charResult)[0].Get<uint32>()  // account_id
            : (*charResult)[1].Get<uint32>(); // char guid

        auto const it = g_shareOwnerByKey.find(memberKey);
        if (it == g_shareOwnerByKey.end() || it->second != ownerKey)
        {
            SendShareError(handler, Acore::StringFormat("{} is not a member of your shared bank.", memberName));
            return;
        }

        CharacterDatabase.DirectExecute(
            "DELETE FROM mod_reagent_bank_share_members WHERE member_key = {}",
            memberKey);

        g_shareOwnerByKey.erase(memberKey);

        SendShareOk(handler, Acore::StringFormat("{} has been removed from your shared bank.", memberName));
        SendShareOpen(handler, player);

        std::string const ownerName = GetDisplayNameByKey(ownerKey);
        NotifyPlayersByKey(memberKey, Acore::StringFormat("RBANK:SHARE:KICKED:{}", SanitizeProtocolText(ownerName)));

        LOG_INFO("module", "ReagentBankAccount: key {} was removed from key {}'s shared bank.", memberKey, ownerKey);
    }

    static void SendUsage(ChatHandler* handler)
    {
        SendError(handler, "Usage: .rbank open | list <categoryId> [page] [id|name|amount|amount_asc] | preview deposit all|category <categoryId> | check recipe <requestId> <itemEntry> <amountPerCraft> [...] | deposit all|category <categoryId>|item <itemEntry> <amount>|items <itemEntry> <amount> [...] | withdraw all|category <categoryId>|item <itemEntry> <one|stack|all|exact <amount>>|needed <itemEntry> <amount> [...] | share [open|invite <name>|accept|decline|leave|kick <name>]");
    }
}

class mod_reagent_bank_account_commandscript : public CommandScript
{
public:
    mod_reagent_bank_account_commandscript() : CommandScript("mod_reagent_bank_account_commandscript") {}

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "rbank", HandleRBankCommand, SEC_PLAYER, Console::No }
        };

        return commandTable;
    }

private:
    static bool HandleRBankCommand(ChatHandler* handler, char const* args)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (!g_reagentBankStorageReady)
        {
            ReagentBank::SendError(handler, "Reagent bank storage is not initialized yet.");
            return true;
        }

        if (!g_reagentBankEnabled)
        {
            ReagentBank::SendError(handler, "The reagent bank is disabled.");
            return true;
        }

        std::vector<std::string> tokens = ReagentBank::Tokenize(args);

        if (tokens.empty() || ReagentBank::ToLower(tokens[0]) == "open" || ReagentBank::ToLower(tokens[0]) == "root")
        {
            ReagentBank::SendRoot(handler, player);
            return true;
        }

        std::string command = ReagentBank::ToLower(tokens[0]);

        if (command == "list")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendRoot(handler, player);
                return true;
            }

            uint32 category = 0;
            if (!ReagentBank::TryParseUInt32(tokens[1], category) || !ReagentBank::IsCategory(category))
            {
                ReagentBank::SendError(handler, "Unknown reagent category.");
                ReagentBank::SendRoot(handler, player);
                return true;
            }

            uint32 page = 0;
            if (tokens.size() >= 3 && !ReagentBank::TryParseUInt32(tokens[2], page))
                page = 0;

            ReagentBank::SortMode sortMode = ReagentBank::SortMode::Id;
            if (tokens.size() >= 4)
                sortMode = ReagentBank::ParseSortMode(tokens[3]);

            ReagentBank::SendCategory(handler, player, category, page, sortMode);
            return true;
        }


        if (command == "preview")
        {
            if (tokens.size() < 3 || ReagentBank::ToLower(tokens[1]) != "deposit")
            {
                ReagentBank::SendError(handler, "Usage: .rbank preview deposit all|category <categoryId>");
                return true;
            }

            std::string scope = ReagentBank::ToLower(tokens[2]);

            if (scope == "all")
            {
                ReagentBank::ItemAmountMap previewItems;
                bool overflowed = false;
                uint32 total = ReagentBank::CollectDepositPreview(player, 0, previewItems, overflowed);

                ReagentBank::SendDepositPreview(handler, "all", 0, previewItems);

                if (!total && overflowed)
                    ReagentBank::SendError(handler, "No reagents can be deposited because the reagent bank cap was reached for the matching item(s).");

                return true;
            }

            if (scope == "category")
            {
                if (tokens.size() < 4)
                {
                    ReagentBank::SendError(handler, "Usage: .rbank preview deposit category <categoryId>");
                    return true;
                }

                uint32 category = 0;
                if (!ReagentBank::TryParseUInt32(tokens[3], category) || !ReagentBank::IsCategory(category))
                {
                    ReagentBank::SendError(handler, "Unknown reagent category.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                ReagentBank::ItemAmountMap previewItems;
                bool overflowed = false;
                uint32 total = ReagentBank::CollectDepositPreview(player, category, previewItems, overflowed);

                ReagentBank::SendDepositPreview(handler, "category", category, previewItems);

                if (!total && overflowed)
                    ReagentBank::SendError(handler, "No reagents can be deposited because the reagent bank cap was reached for the matching item(s).");

                return true;
            }

            ReagentBank::SendError(handler, "Usage: .rbank preview deposit all|category <categoryId>");
            return true;
        }

        if (command == "check")
        {
            if (tokens.size() < 5 || ReagentBank::ToLower(tokens[1]) != "recipe")
            {
                ReagentBank::SendError(handler, "Usage: .rbank check recipe <requestId> <itemEntry> <amountPerCraft> [itemEntry amountPerCraft ...]");
                return true;
            }

            uint32 requestId = 0;
            if (!ReagentBank::TryParseUInt32(tokens[2], requestId))
            {
                ReagentBank::SendError(handler, "Invalid recipe check request id.");
                return true;
            }

            std::vector<std::pair<uint32, uint32>> requestedItems;
            if (!ReagentBank::TryParseItemAmountPairs(tokens, 3, requestedItems))
            {
                ReagentBank::SendError(handler, "Usage: .rbank check recipe <requestId> <itemEntry> <amountPerCraft> [itemEntry amountPerCraft ...]");
                return true;
            }

            ReagentBank::SendRecipeCheck(handler, player, requestId, requestedItems);
            return true;
        }

        if (command == "deposit")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendUsage(handler);
                return true;
            }

            std::string scope = ReagentBank::ToLower(tokens[1]);

            if (scope == "all")
            {
                ReagentBank::ItemAmountMap deposited;
                bool overflowed = false;
                uint32 total = ReagentBank::Deposit(player, 0, deposited, overflowed);

                ReagentBank::SendTransaction(handler, "deposit", deposited);

                if (total)
                    ReagentBank::SendOk(handler, overflowed
                        ? Acore::StringFormat("Deposited {} reagent(s). Some stacks were skipped because the bank cap was reached.", total)
                        : Acore::StringFormat("Deposited {} reagent(s).", total));
                else if (overflowed)
                    ReagentBank::SendError(handler, "No reagents were deposited because the reagent bank cap was reached for the matching item(s).");
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                ReagentBank::SendRoot(handler, player);
                return true;
            }

            if (scope == "category")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 category = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], category) || !ReagentBank::IsCategory(category))
                {
                    ReagentBank::SendError(handler, "Unknown reagent category.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                ReagentBank::ItemAmountMap deposited;
                bool overflowed = false;
                uint32 total = ReagentBank::Deposit(player, category, deposited, overflowed);

                ReagentBank::SendTransaction(handler, "deposit", deposited);

                if (total)
                    ReagentBank::SendOk(handler, overflowed
                        ? Acore::StringFormat("Deposited {} reagent(s). Some stacks were skipped because the bank cap was reached.", total)
                        : Acore::StringFormat("Deposited {} reagent(s).", total));
                else if (overflowed)
                    ReagentBank::SendError(handler, "No reagents were deposited because the reagent bank cap was reached for the matching item(s).");
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                ReagentBank::SendCategory(handler, player, category, 0);
                return true;
            }

            if (scope == "item")
            {
                if (tokens.size() < 4)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 itemEntry = 0;
                uint32 amount = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], itemEntry) || !ReagentBank::TryParseUInt32(tokens[3], amount) || !itemEntry || !amount)
                {
                    ReagentBank::SendError(handler, "Usage: .rbank deposit item <itemEntry> <amount>");
                    return true;
                }

                std::vector<std::pair<uint32, uint32>> requestedItems;
                requestedItems.emplace_back(itemEntry, amount);

                ReagentBank::ItemAmountMap deposited;
                bool overflowed = false;
                uint32 total = ReagentBank::DepositSpecificItems(player, requestedItems, deposited, overflowed);

                ReagentBank::SendTransaction(handler, "deposit", deposited);

                if (total)
                    ReagentBank::SendOk(handler, overflowed
                        ? Acore::StringFormat("Deposited {} reagent(s). Some amount was skipped because the bank cap was reached.", total)
                        : Acore::StringFormat("Deposited {} reagent(s).", total));
                else if (overflowed)
                    ReagentBank::SendError(handler, "No reagents were deposited because the reagent bank cap was reached for the matching item(s).");
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                return true;
            }

            if (scope == "items")
            {
                std::vector<std::pair<uint32, uint32>> requestedItems;
                if (!ReagentBank::TryParseItemAmountPairs(tokens, 2, requestedItems))
                {
                    ReagentBank::SendError(handler, "Usage: .rbank deposit items <itemEntry> <amount> [itemEntry amount ...]");
                    return true;
                }

                ReagentBank::ItemAmountMap deposited;
                bool overflowed = false;
                uint32 total = ReagentBank::DepositSpecificItems(player, requestedItems, deposited, overflowed);

                ReagentBank::SendTransaction(handler, "deposit", deposited);

                if (total)
                    ReagentBank::SendOk(handler, overflowed
                        ? Acore::StringFormat("Deposited {} reagent leftover(s). Some amount was skipped because the bank cap was reached.", total)
                        : Acore::StringFormat("Deposited {} reagent leftover(s).", total));
                else if (overflowed)
                    ReagentBank::SendError(handler, "No leftover reagents were deposited because the reagent bank cap was reached for the matching item(s).");
                else
                    ReagentBank::SendOk(handler, "No matching leftover reagents were found in your bags.");

                return true;
            }

            ReagentBank::SendUsage(handler);
            return true;
        }

        if (command == "withdraw")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendUsage(handler);
                return true;
            }

            std::string scope = ReagentBank::ToLower(tokens[1]);

            if (scope == "all")
            {
                bool stoppedForBagSpace = false;
                ReagentBank::ItemAmountMap withdrawn;
                uint32 total = ReagentBank::WithdrawAll(player, stoppedForBagSpace, withdrawn);

                ReagentBank::SendTransaction(handler, "withdraw", withdrawn);

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} reagent(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No reagents were withdrawn.");

                ReagentBank::SendRoot(handler, player);
                return true;
            }

            if (scope == "category")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 category = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], category) || !ReagentBank::IsCategory(category))
                {
                    ReagentBank::SendError(handler, "Unknown reagent category.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                bool stoppedForBagSpace = false;
                ReagentBank::ItemAmountMap withdrawn;
                uint32 total = ReagentBank::WithdrawCategory(player, category, stoppedForBagSpace, withdrawn);

                ReagentBank::SendTransaction(handler, "withdraw", withdrawn);

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} reagent(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No reagents were withdrawn.");

                ReagentBank::SendCategory(handler, player, category, 0);
                return true;
            }

            if (scope == "item")
            {
                if (tokens.size() < 4)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 itemEntry = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], itemEntry))
                {
                    ReagentBank::SendError(handler, "Invalid item entry.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                uint32 returnCategory = 0;
                uint32 returnPage = 0;
                bool stoppedForBagSpace = false;
                uint32 total = 0;

                std::string modeText = ReagentBank::ToLower(tokens[3]);
                if (modeText == "exact")
                {
                    if (tokens.size() < 5)
                    {
                        ReagentBank::SendUsage(handler);
                        return true;
                    }

                    uint32 amount = 0;
                    if (!ReagentBank::TryParseUInt32(tokens[4], amount) || !amount)
                    {
                        ReagentBank::SendError(handler, "Invalid exact withdraw amount.");
                        return true;
                    }

                    if (tokens.size() >= 6)
                        ReagentBank::TryParseUInt32(tokens[5], returnCategory);
                    if (tokens.size() >= 7)
                        ReagentBank::TryParseUInt32(tokens[6], returnPage);

                    ReagentBank::ItemAmountMap withdrawn;
                    total = ReagentBank::WithdrawItemAmount(player, itemEntry, amount, stoppedForBagSpace, withdrawn);
                    ReagentBank::SendTransaction(handler, "withdraw", withdrawn);
                }
                else
                {
                    ReagentBank::WithdrawMode mode;
                    if (!ReagentBank::ParseWithdrawMode(modeText, mode))
                    {
                        ReagentBank::SendError(handler, "Invalid withdraw mode.");
                        ReagentBank::SendRoot(handler, player);
                        return true;
                    }

                    if (tokens.size() >= 5)
                        ReagentBank::TryParseUInt32(tokens[4], returnCategory);
                    if (tokens.size() >= 6)
                        ReagentBank::TryParseUInt32(tokens[5], returnPage);

                    ReagentBank::ItemAmountMap withdrawn;
                    total = ReagentBank::WithdrawItem(player, itemEntry, mode, stoppedForBagSpace, withdrawn);
                    ReagentBank::SendTransaction(handler, "withdraw", withdrawn);
                }

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} item(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} item(s).", total));
                else
                    ReagentBank::SendOk(handler, "No item was withdrawn.");

                if (returnCategory && ReagentBank::IsCategory(returnCategory))
                    ReagentBank::SendCategory(handler, player, returnCategory, returnPage);
                else
                    ReagentBank::SendRoot(handler, player);

                return true;
            }

            if (scope == "needed")
            {
                std::vector<std::pair<uint32, uint32>> requestedItems;
                if (!ReagentBank::TryParseItemAmountPairs(tokens, 2, requestedItems))
                {
                    ReagentBank::SendError(handler, "Usage: .rbank withdraw needed <itemEntry> <amount> [itemEntry amount ...]");
                    return true;
                }

                bool stoppedForBagSpace = false;
                uint32 incompleteItems = 0;
                ReagentBank::ItemAmountMap withdrawn;
                uint32 total = ReagentBank::WithdrawSpecificItems(player, requestedItems, stoppedForBagSpace, incompleteItems, withdrawn);

                ReagentBank::SendTransaction(handler, "withdraw", withdrawn);

                if (total)
                {
                    if (stoppedForBagSpace)
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s). Your bags are now full.", total));
                    else if (incompleteItems)
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s). Some requested reagents were not fully available.", total));
                    else
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s).", total));
                }
                else
                    ReagentBank::SendOk(handler, "No needed reagents were withdrawn.");

                return true;
            }

            ReagentBank::SendUsage(handler);
            return true;
        }

        if (command == "share")
        {
            if (!g_reagentBankSharingEnabled)
            {
                ReagentBank::SendProtocol(handler, "RBANK:SHARE:ERR:Sharing is not enabled on this server.");
                return true;
            }

            if (tokens.size() < 2 || ReagentBank::ToLower(tokens[1]) == "open")
            {
                ReagentBank::SendShareOpen(handler, player);
                return true;
            }

            std::string shareCmd = ReagentBank::ToLower(tokens[1]);

            if (shareCmd == "invite")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendShareError(handler, "Usage: .rbank share invite <character_name>");
                    return true;
                }

                ReagentBank::HandleShareInvite(handler, player, tokens[2]);
                return true;
            }

            if (shareCmd == "accept")
            {
                ReagentBank::HandleShareAccept(handler, player);
                return true;
            }

            if (shareCmd == "decline")
            {
                ReagentBank::HandleShareDecline(handler, player);
                return true;
            }

            if (shareCmd == "leave")
            {
                ReagentBank::HandleShareLeave(handler, player);
                return true;
            }

            if (shareCmd == "kick")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendShareError(handler, "Usage: .rbank share kick <character_name>");
                    return true;
                }

                ReagentBank::HandleShareKick(handler, player, tokens[2]);
                return true;
            }

            ReagentBank::SendShareError(handler, "Usage: .rbank share [open|invite <name>|accept|decline|leave|kick <name>]");
            return true;
        }

        if (command == "help")
        {
            ReagentBank::SendUsage(handler);
            ReagentBank::SendRoot(handler, player);
            return true;
        }

        ReagentBank::SendUsage(handler);
        return true;
    }
};

class mod_reagent_bank_account_worldscript : public WorldScript
{
public:
    mod_reagent_bank_account_worldscript() : WorldScript("mod_reagent_bank_account_worldscript") {}

    void OnAfterConfigLoad(bool reload) override
    {
        ReagentBank::LoadConfig();

        if (reload)
        {
            ReagentBank::EnsureStorageModeMatchesConfig();
            ReagentBank::LoadDepositExclusions();
            if (g_reagentBankSharingEnabled)
                ReagentBank::LoadShareMembers();
            g_reagentBankStorageReady = true;

            LOG_INFO("module", "Standalone Reagent Bank config reloaded. Enabled: {}, AccountWide: {}, AutoMigrate: {}, MaxItemsPerPage: {}",
                g_reagentBankEnabled ? "yes" : "no",
                g_accountWideReagentBank ? "yes" : "no",
                g_reagentBankAutoMigrate ? "yes" : "no",
                g_reagentBankMaxItemsPerPage);
        }
    }

    void OnStartup() override
    {
        ReagentBank::LoadConfig();
        ReagentBank::EnsureStorageModeMatchesConfig();
        ReagentBank::LoadDepositExclusions();
        if (g_reagentBankSharingEnabled)
            ReagentBank::LoadShareMembers();
        g_reagentBankStorageReady = true;

        LOG_INFO("module", "Standalone Reagent Bank command module loaded. Enabled: {}, AccountWide: {}, AutoMigrate: {}, MaxItemsPerPage: {}",
            g_reagentBankEnabled ? "yes" : "no",
            g_accountWideReagentBank ? "yes" : "no",
            g_reagentBankAutoMigrate ? "yes" : "no",
            g_reagentBankMaxItemsPerPage);
    }
};

class mod_reagent_bank_account_playerscript : public PlayerScript
{
public:
    mod_reagent_bank_account_playerscript() : PlayerScript("mod_reagent_bank_account_playerscript") {}

    void OnPlayerLogin(Player* player) override
    {
        if (!g_reagentBankEnabled || !g_reagentBankStorageReady || !g_reagentBankSharingEnabled)
            return;

        uint32 const loginKey = ReagentBank::GetShareKey(player);

        QueryResult result = CharacterDatabase.Query(
            "SELECT inviter_key FROM mod_reagent_bank_share_invites WHERE invitee_key = {} LIMIT 1",
            loginKey);

        if (!result)
            return;

        uint32 const inviterKey = (*result)[0].Get<uint32>();
        std::string const inviterName = ReagentBank::GetDisplayNameByKey(inviterKey);

        if (inviterName.empty())
            return;

        ChatHandler handler(player->GetSession());
        ReagentBank::SendProtocol(&handler, Acore::StringFormat("RBANK:SHARE:INVITE:{}",
            ReagentBank::SanitizeProtocolText(inviterName)));
    }
};

void AddSC_mod_reagent_bank_account()
{
    new mod_reagent_bank_account_worldscript();
    new mod_reagent_bank_account_commandscript();
    new mod_reagent_bank_account_playerscript();
}
