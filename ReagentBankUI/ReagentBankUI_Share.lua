-- ReagentBankUI_Share.lua
-- Reagent Bank Sharing UI — extends RB with share panel, invite dialog, and SHARE protocol handling.
-- Loaded after ReagentBankUI.lua; hooks into CreateFrame, SetCommonVisibility, UpdateControls, HandleProtocol.

local RB = ReagentBankUI
if not RB then return end

local SHARE_PANEL_WIDTH  = 420
local SHARE_PANEL_HEIGHT = 300
local SHARE_BUTTON_WIDTH = 76
local SHARE_MEMBER_ROWS  = 8
local SHARE_MEMBER_ROW_H = 26
local SHARE_MEMBER_ROW_GAP = 2

-- ─── Protocol ────────────────────────────────────────────────────────────────

local originalHandleProtocol = RB.HandleProtocol

function RB:HandleProtocol(message)
    if type(message) == "string" and string.sub(message, 1, 12) == "RBANK:SHARE:" then
        return self:HandleShareProtocol(message)
    end

    return originalHandleProtocol(self, message)
end

function RB:HandleShareProtocol(message)
    local parts = {}
    for part in string.gmatch(message, "([^:]+)") do
        table.insert(parts, part)
    end

    local kind = parts[3]

    if kind == "FEATURE" then
        self.sharingEnabled = (parts[4] == "1")
        return true
    end

    if kind == "REFRESH" then
        if self.frame and self.frame:IsShown() then
            if self.currentView == "category" and self.currentCategoryId then
                self:RequestCategory(self.currentCategoryId, self.currentPage or 0)
            elseif self.currentView == "detail" and self.currentCategoryId then
                self:RequestCategory(self.currentCategoryId, self.currentPage or 0)
            else
                self:RequestRoot()
            end
        end
        return true
    end

    if kind == "ACCEPTED" then
        local ownerName = parts[4] or "the bank owner"
        if self.frame and self.frame:IsShown() then
            self:Close()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff73d216Reagent Bank:|r You have joined " .. ownerName .. "'s shared bank. Your items have been merged.", 1, 1, 1)
        return true
    end

    if kind == "INVITE" then
        local inviterName = parts[4] or "Unknown"
        self:ShowShareInviteDialog(inviterName)
        return true
    end

    if kind == "JOINED" then
        local memberName = parts[4] or "Someone"
        if self.frame and self.frame:IsShown() and self.frame.sharePanel and self.frame.sharePanel:IsShown() then
            self:RequestShareOpen()
        end
        self:Status(memberName .. " joined your shared bank.", 0.45, 1.00, 0.45)
        return true
    end

    if kind == "LEFT" then
        local memberName = parts[4] or "Someone"
        if self.frame and self.frame:IsShown() and self.frame.sharePanel and self.frame.sharePanel:IsShown() then
            self:RequestShareOpen()
        end
        self:Status(memberName .. " left your shared bank.", 1.00, 0.72, 0.32)
        return true
    end

    if kind == "LEFT_SELF" then
        local ownerName = parts[4] or "the bank owner"
        if self.frame and self.frame:IsShown() then
            self:Close()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff73d216Reagent Bank:|r You have left " .. ownerName .. "'s shared bank. Your deposited items remain there.", 1, 1, 1)
        return true
    end

    if kind == "KICKED" then
        local ownerName = parts[4] or "the bank owner"
        if self.frame and self.frame:IsShown() then
            self:Close()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6644Reagent Bank:|r You were removed from " .. ownerName .. "'s shared bank.", 1, 0.6, 0.4)
        return true
    end

    if kind == "BEGIN" then
        local status    = parts[4] or "owner"
        local extraArg  = parts[5] or ""
        self.pendingShare = { status = status, ownerName = extraArg, members = {} }
        return true
    end

    if kind == "ITEM" then
        if self.pendingShare then
            table.insert(self.pendingShare.members, parts[4] or "?")
        end
        return true
    end

    if kind == "END" then
        local data = self.pendingShare
        self.pendingShare = nil
        if data then
            self:RenderSharePanel(data)
        end
        return true
    end

    if kind == "OK" then
        local msg = parts[4] or "Done."
        self:Status(msg, 0.45, 1.00, 0.45)
        return true
    end

    if kind == "ERR" then
        local msg = parts[4] or "Error."
        self:Status(msg, 1.00, 0.40, 0.40)
        return true
    end

    return true
end

-- ─── Server request ──────────────────────────────────────────────────────────

function RB:RequestShareOpen()
    self:SendServerCommand("share open")
end

-- ─── Frame hooks ─────────────────────────────────────────────────────────────

local originalCreateFrame = RB.CreateFrame

function RB:CreateFrame()
    originalCreateFrame(self)

    local f = self.frame
    if not f or f.share then
        return
    end

    f.share = self:CreateButton(f, SHARE_BUTTON_WIDTH, 24, "Sharing")
    f.share:SetPoint("TOPLEFT", 18, -90)
    f.share:SetScript("OnClick", function()
        if f.sharePanel and f.sharePanel:IsShown() then
            self:HideSharePanel()
        else
            self:RequestShareOpen()
        end
    end)
    f.share:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank Sharing", 1, 0.82, 0)
        GameTooltip:AddLine("Share your bank with other players.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.share:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip:IsShown() then
            GameTooltip:Hide()
        end
    end)

    self:BuildSharePanel(f)
    self:BuildShareInvitePrompt(f)
    self:BuildShareInviteDialog(f)
end

local originalSetCommonVisibility = RB.SetCommonVisibility

function RB:SetCommonVisibility(view)
    originalSetCommonVisibility(self, view)

    local f = self.frame
    if not f or not f.share then
        return
    end

    if view == "root" and self.sharingEnabled then
        f.share:Show()
    else
        f.share:Hide()
    end
    self:HideSharePanel()
end

local originalUpdateControls = RB.UpdateControls

function RB:UpdateControls()
    originalUpdateControls(self)

    local f = self.frame
    if not f or not f.share then
        return
    end

    local busy = self.busyKind ~= nil
    self:SetButtonEnabled(f.share, not busy)
end

-- ─── Share panel ─────────────────────────────────────────────────────────────

function RB:BuildSharePanel(f)
    local p = CreateFrame("Frame", nil, f)
    p:SetWidth(SHARE_PANEL_WIDTH)
    p:SetHeight(SHARE_PANEL_HEIGHT)
    p:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -120)
    p:SetFrameLevel((f:GetFrameLevel() or 1) + 70)
    p:EnableMouse(true)
    self:MakeBackdrop(p, 0.98, true)
    p:Hide()
    f.sharePanel = p

    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.title:SetPoint("TOPLEFT", 14, -12)
    p.title:SetText("Reagent Bank Sharing")
    p.title:SetTextColor(1.00, 0.82, 0.28)

    p.closeBtn = self:CreateCloseButton(p)
    p.closeBtn:SetPoint("TOPRIGHT", -6, -6)
    p.closeBtn:SetScript("OnClick", function()
        self:HideSharePanel()
    end)

    p.statusText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p.statusText:SetPoint("TOPLEFT", 14, -42)
    p.statusText:SetPoint("RIGHT", -14, 0)
    p.statusText:SetJustifyH("LEFT")
    p.statusText:SetWordWrap(true)
    p.statusText:SetText("")

    p.warningText = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.warningText:SetPoint("TOPLEFT", 14, -64)
    p.warningText:SetPoint("RIGHT", -14, 0)
    p.warningText:SetJustifyH("LEFT")
    p.warningText:SetWordWrap(true)
    p.warningText:SetText("")
    p.warningText:SetTextColor(1.00, 0.72, 0.32)

    p.memberRows = {}
    for i = 1, SHARE_MEMBER_ROWS do
        local row = CreateFrame("Frame", nil, p)
        row:SetHeight(SHARE_MEMBER_ROW_H)
        row:SetPoint("TOPLEFT", 14, -88 - (i - 1) * (SHARE_MEMBER_ROW_H + SHARE_MEMBER_ROW_GAP))
        row:SetPoint("RIGHT", -14, 0)
        self:MakeBackdrop(row, i % 2 == 0 and 0.25 or 0.18, true)
        row:Hide()

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameText:SetPoint("LEFT", 8, 0)
        row.nameText:SetPoint("RIGHT", -80, 0)
        row.nameText:SetJustifyH("LEFT")

        row.kickBtn = self:CreateButton(row, 64, 20, "Kick")
        row.kickBtn:SetPoint("RIGHT", -6, 0)
        row.kickBtn:Hide()

        p.memberRows[i] = row
    end

    p.actionBtn = self:CreateButton(p, 140, 26, "Invite Member")
    p.actionBtn:SetPoint("BOTTOMLEFT", 14, 14)
    p.actionBtn:SetScript("OnClick", function()
        self:ShowShareInvitePrompt()
    end)

    p.leaveBtn = self:CreateButton(p, 140, 26, "Leave Shared Bank")
    p.leaveBtn:SetPoint("BOTTOMLEFT", 14, 14)
    p.leaveBtn:Hide()
    p.leaveBtn:SetScript("OnClick", function()
        self:SendServerCommand("share leave")
        self:HideSharePanel()
    end)

    p.cancelBtn = self:CreateButton(p, 80, 26, "Close")
    p.cancelBtn:SetPoint("BOTTOMRIGHT", -14, 14)
    p.cancelBtn:SetScript("OnClick", function()
        self:HideSharePanel()
    end)
end

function RB:HideSharePanel()
    local f = self.frame
    if f and f.sharePanel then
        f.sharePanel:Hide()
    end
    self:HideShareInvitePrompt()
end

function RB:RenderSharePanel(data)
    self:CreateFrame()
    local f = self.frame
    local p = f.sharePanel
    if not p then
        return
    end

    self:HideShareInvitePrompt()

    local status    = data.status    or "owner"
    local ownerName = data.ownerName or ""
    local members   = data.members   or {}

    for i = 1, SHARE_MEMBER_ROWS do
        local row = p.memberRows[i]
        row:Hide()
        row.kickBtn:Hide()
        row.nameText:SetText("")
        row.kickBtn:SetScript("OnClick", nil)
    end

    if status == "member" then
        p.statusText:SetText("You are sharing |cffffd200" .. ownerName .. "|r's reagent bank.")
        p.warningText:SetText("If you leave, your deposited items remain in the shared bank.")
        p.actionBtn:Hide()
        p.leaveBtn:Show()

        for _, row in ipairs(p.memberRows) do
            row:Hide()
        end
    else
        local memberCount = #members
        if memberCount == 0 then
            p.statusText:SetText("You own this bank.\nNo one is currently sharing it.")
        else
            p.statusText:SetText("You own this bank.\n" .. memberCount .. " member" .. (memberCount == 1 and "" or "s") .. " sharing with you:")
        end
        p.warningText:SetText("Members' items merge into your bank on join. Items stay here if they leave.")
        p.actionBtn:Show()
        p.leaveBtn:Hide()

        for i, memberName in ipairs(members) do
            local row = p.memberRows[i]
            if row then
                row.nameText:SetText(memberName)
                row.kickBtn:Show()
                local capturedName = memberName
                row.kickBtn:SetScript("OnClick", function()
                    self:SendServerCommand("share kick " .. capturedName)
                end)
                row:Show()
            end
        end
    end

    f.sharePanel:Show()
    f.sharePanel:SetFrameLevel((f:GetFrameLevel() or 1) + 70)
end

-- ─── Invite prompt (owner enters a character name) ───────────────────────────

function RB:BuildShareInvitePrompt(f)
    local p = CreateFrame("Frame", nil, f)
    p:SetWidth(340)
    p:SetHeight(150)
    p:SetPoint("CENTER", f, "CENTER", 0, 30)
    p:SetFrameLevel((f:GetFrameLevel() or 1) + 90)
    p:EnableMouse(true)
    self:MakeBackdrop(p, 0.98, true)
    p:Hide()
    f.shareInvitePrompt = p

    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.title:SetPoint("TOPLEFT", 14, -12)
    p.title:SetText("Invite to Shared Bank")
    p.title:SetTextColor(1.00, 0.82, 0.28)

    p.closeBtn = self:CreateCloseButton(p)
    p.closeBtn:SetPoint("TOPRIGHT", -6, -6)
    p.closeBtn:SetScript("OnClick", function()
        self:HideShareInvitePrompt()
    end)

    p.label = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.label:SetPoint("TOPLEFT", 14, -44)
    p.label:SetText("Character name:")

    p.nameBox = self:CreateEditBox(p, 160, 24)
    p.nameBox:SetNumeric(false)
    p.nameBox:SetPoint("LEFT", p.label, "RIGHT", 10, 0)
    p.nameBox:SetScript("OnEnterPressed", function(box)
        box:ClearFocus()
        self:ConfirmShareInvite()
    end)
    p.nameBox:SetScript("OnEscapePressed", function(box)
        box:ClearFocus()
        self:HideShareInvitePrompt()
    end)

    p.hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.hint:SetPoint("TOPLEFT", 14, -78)
    p.hint:SetPoint("RIGHT", -14, 0)
    p.hint:SetJustifyH("LEFT")
    p.hint:SetWordWrap(true)
    p.hint:SetText("Their items merge into your bank on join.\nThey can leave at any time, but items stay.")
    p.hint:SetTextColor(1.00, 0.72, 0.32)

    p.sendBtn = self:CreateButton(p, 110, 26, "Send Invite")
    p.sendBtn:SetPoint("BOTTOMLEFT", 14, 12)
    p.sendBtn:SetScript("OnClick", function()
        self:ConfirmShareInvite()
    end)

    p.cancelBtn = self:CreateButton(p, 80, 26, "Cancel")
    p.cancelBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    p.cancelBtn:SetScript("OnClick", function()
        self:HideShareInvitePrompt()
    end)
end

function RB:ShowShareInvitePrompt()
    local f = self.frame
    if not f or not f.shareInvitePrompt then
        return
    end

    f.shareInvitePrompt.nameBox:SetText("")
    f.shareInvitePrompt:Show()
    f.shareInvitePrompt:SetFrameLevel((f:GetFrameLevel() or 1) + 90)
    f.shareInvitePrompt.nameBox:SetFocus()
end

function RB:HideShareInvitePrompt()
    local f = self.frame
    if f and f.shareInvitePrompt then
        f.shareInvitePrompt:Hide()
    end
end

function RB:ConfirmShareInvite()
    local f = self.frame
    if not f or not f.shareInvitePrompt then
        return
    end

    local name = f.shareInvitePrompt.nameBox:GetText() or ""
    name = string.match(name, "^%s*(.-)%s*$")

    if name == "" then
        self:Status("Enter a character name first.", 1.00, 0.72, 0.32)
        return
    end

    self:HideShareInvitePrompt()
    self:SendServerCommand("share invite " .. name)
end

-- ─── Incoming invite dialog (shown on login or when invite arrives) ───────────

function RB:BuildShareInviteDialog(f)
    local d = CreateFrame("Frame", nil, f)
    d:SetWidth(360)
    d:SetHeight(200)
    d:SetPoint("CENTER", f, "CENTER", 0, 30)
    d:SetFrameLevel((f:GetFrameLevel() or 1) + 95)
    d:EnableMouse(true)
    self:MakeBackdrop(d, 0.98, true)
    d:Hide()
    f.shareInviteDialog = d

    d.title = d:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    d.title:SetPoint("TOPLEFT", 14, -12)
    d.title:SetText("Reagent Bank Invite")
    d.title:SetTextColor(1.00, 0.82, 0.28)

    d.closeBtn = self:CreateCloseButton(d)
    d.closeBtn:SetPoint("TOPRIGHT", -6, -6)
    d.closeBtn:SetScript("OnClick", function()
        self:HideShareInviteDialog()
    end)

    d.msgText = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    d.msgText:SetPoint("TOPLEFT", 14, -44)
    d.msgText:SetPoint("RIGHT", -14, 0)
    d.msgText:SetJustifyH("LEFT")
    d.msgText:SetWordWrap(true)
    d.msgText:SetText("")

    d.warnText = d:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    d.warnText:SetPoint("TOPLEFT", 14, -100)
    d.warnText:SetPoint("RIGHT", -14, 0)
    d.warnText:SetJustifyH("LEFT")
    d.warnText:SetWordWrap(true)
    d.warnText:SetText("Your current items will merge into their bank.\nIf you leave later, those items remain in the shared bank.")
    d.warnText:SetTextColor(1.00, 0.72, 0.32)

    d.acceptBtn = self:CreateButton(d, 90, 26, "Accept")
    d.acceptBtn:SetPoint("BOTTOMLEFT", 14, 14)
    d.acceptBtn:SetScript("OnClick", function()
        self:HideShareInviteDialog()
        self:SendServerCommand("share accept")
    end)

    d.declineBtn = self:CreateButton(d, 90, 26, "Decline")
    d.declineBtn:SetPoint("BOTTOMRIGHT", -14, 14)
    d.declineBtn:SetScript("OnClick", function()
        self:SendServerCommand("share decline")
        self:HideShareInviteDialog()
    end)
end

function RB:ShowShareInviteDialog(inviterName)
    self:CreateFrame()
    local f = self.frame
    if not f or not f.shareInviteDialog then
        return
    end

    f.shareInviteDialog.msgText:SetText("|cffffd200" .. inviterName .. "|r has invited you to share their reagent bank.")
    f.shareInviteDialog:Show()
    f.shareInviteDialog:SetFrameLevel((f:GetFrameLevel() or 1) + 95)
    f:Show()
end

function RB:HideShareInviteDialog()
    local f = self.frame
    if f and f.shareInviteDialog then
        f.shareInviteDialog:Hide()
    end
end
