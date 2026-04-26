<img width="1273" height="1097" alt="Reagent1" src="https://github.com/user-attachments/assets/803a5f8d-50e2-495e-9169-692e12ff9c69" />
## mod-reagent-bank-account

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

### Profession Integration

- Open any profession window
- Use the **"Withdraw Needed"** button
- Automatically pulls missing reagents for the selected recipe
- Supports multi-craft amounts
- Optional auto-deposit of leftovers when closing the profession window
<img width="1305" height="906" alt="Reagent2" src="https://github.com/user-attachments/assets/ee0a2073-7406-4137-885d-034b2ca0104f" />
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
