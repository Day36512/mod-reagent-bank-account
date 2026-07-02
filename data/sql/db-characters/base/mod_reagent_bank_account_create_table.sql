CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account` (
    `account_id` int NOT NULL DEFAULT 0,
    `guid` int NOT NULL DEFAULT 0,
    `item_entry` int NOT NULL,
    `item_subclass` int NOT NULL,
    `amount` int NOT NULL,
    PRIMARY KEY (`account_id`, `guid`, `item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS `mod_reagent_bank_share_members` (
  `member_key` INT UNSIGNED NOT NULL,
  `owner_key` INT UNSIGNED NOT NULL,
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`member_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_reagent_bank_share_invites` (
  `inviter_key` INT UNSIGNED NOT NULL,
  `invitee_key` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`invitee_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
