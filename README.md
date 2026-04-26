# mod-reagent-bank-account

Reagent bank system for AzerothCore with a required UI addon.

---

## Install

### Server
1. Place in:
   modules/mod-reagent-bank-account/

2. Recompile AzerothCore

3. Add to config:
   ReagentBankAccount.Enable = 1
   ReagentBankAccount.AccountWide = 0
   ReagentBankAccount.MaxItemsPerPage = 12
   ReagentBankAccount.AutoMigrate = 1

4. Start server (tables auto-create)

---

### Addon (REQUIRED)

Place the addon in:
Interface/AddOns/ReagentBankUI/

If you don’t install the addon, this module is not usable.

---

## How to open

Click the **Reagent Bank icon on the character paperdoll**.

---

## What it does

- Stores reagents (trade goods, gems)
- Account-wide or character-wide (config)
- Deposit / withdraw handled through the addon UI

---

## Files

Server:
- ReagentBankAccount.cpp
- ReagentBankAccount.h
- ReagentBankAccount_loader.cpp 

Addon:
- ReagentBankUI.lua

---
