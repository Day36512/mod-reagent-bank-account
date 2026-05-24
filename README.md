# Reagent Bank Account

A reagent bank system for AzerothCore with a required WotLK 3.3.5a UI addon.

This module adds a server-backed reagent bank for trade goods, gems, and crafting materials. The addon provides the full player-facing interface: browsing stored reagents, depositing, withdrawing, profession prep, and Auction House shopping-list support.

<img width="1273" height="1097" alt="Reagent1" src="https://github.com/user-attachments/assets/803a5f8d-50e2-495e-9169-692e12ff9c69" />

---

## Features

- Stores reagents and crafting materials server-side
- Account-wide or character-wide storage through config
- Required addon UI, no banker NPC needed
- Category browsing for common reagent types
- Deposit all reagents
- Deposit by category
- Withdraw all, category, stack, single item, or exact amount
- Optional deposit preview confirmation
- Reverse last deposit/withdraw transaction
- Sort categories and items by several modes
- Movable, scalable, skinnable addon window
- Periodic auto-deposit timer
- Character paperdoll launcher button

---

## Profession Integration

Open a profession window and ReagentBankUI adds reagent tools directly to the profession frame.

- **Withdraw Needed** pulls missing reagents for the selected recipe
- Supports multi-craft amounts
- Shows reagent availability from bags and reagent bank
- Optional leftover auto-deposit when closing the profession window
- **Add to AH List** adds missing recipe reagents to the shopping list
- `/rbank craft 5` withdraws reagents for 5 crafts
- `/rbank plan 5` prints a reagent plan for 5 crafts

<img width="1305" height="906" alt="Reagent2" src="https://github.com/user-attachments/assets/ee0a2073-7406-4137-885d-034b2ca0104f" />

---

## Auction House Shopping List

ReagentBankUI includes an AH shopping list for missing crafting materials.

You can add items to the AH list from:

- The main reagent item detail screen
- The profession window with **Add to AH List**
- The AH list **From Recipe** button
- Slash commands

Shopping list features:

- Edit item amounts directly in the AH list
- Right-click an item to change its amount
- Shift-right-click an item to remove it
- Left-click an item to search for it on the Auction House
- Print the list to chat
- Clear the list
- Shows needed amount and current bag count
- Compact AH helper panel opens beside the Auction House frame

Note: AH purchases do not automatically decrement the list. Adjust amounts manually from the list. I also have not tested this with any other AH addons.

---

## Install

### Server

Place the module in:

```txt
modules/mod-reagent-bank-account/
