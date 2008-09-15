--import
local WIM = WIM;
local _G = _G;
local CreateFrame = CreateFrame;
local table = table;
local string = string;

--set namespace
setfenv(1, WIM);

local Menu = CreateModule("Menu", true);

local groupCount = 0;
local buttonCount = 0;

local lists = {
    whisper = {},
    chat = {}
}
local maxButtons = {
    whisper = 20,
    chat = 10
};

db_defaults.menuSortActivity = true;

local function sortWindows(a, b)
    if(db and db.menuSortActivity) then
        return a.lastActivity > b.lastActivity;
    else
        return string.lower(a.theUser) < string.lower(b.theUser);
    end
end

function isMouseOver()
	-- can optionaly exclude an object
	local x,y = _G.GetCursorPosition();
	local menu = WIM.Menu;
        if(not menu) then
            return false;
        else
            local x1, y1 = menu:GetLeft()*menu:GetEffectiveScale(), menu:GetTop()*menu:GetEffectiveScale();
            local x2, y2 = x1 + menu:GetWidth()*menu:GetEffectiveScale(), y1 - menu:GetHeight()*menu:GetEffectiveScale();
            if(x >= x1 and x <= x2 and y <= y1 and y >= y2) then
                return true;
            end
            return false;
        end
end

local function createCloseButton(parent)
    local button = CreateFrame("Button", nil, parent);
    button:SetNormalTexture("Interface\\AddOns\\"..addonTocName.."\\Modules\\Textures\\xNormal");
    button:SetPushedTexture("Interface\\AddOns\\"..addonTocName.."\\Modules\\Textures\\xPressed");
    button:SetWidth(16);
    button:SetHeight(16);
    button:SetScript("OnClick", function(self)
            self:GetParent().win.widgets.close.forceShift = true;
            self:GetParent().win.widgets.close:Click();
        end);

    return button;
end

local function createButton(parent)
    buttonCount = buttonCount + 1;
    local button = CreateFrame("Button", "WIM3MenuButton"..buttonCount, parent, "UIPanelButtonTemplate");
    button:SetNormalTexture(nil); button:SetPushedTexture(nil); button:SetDisabledTexture(nil); button:SetHighlightTexture(nil);
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD");
    button:GetHighlightTexture():SetVertexColor(.196, .388, .8);
    button:SetHeight(20);
    button:GetHighlightTexture():SetAllPoints();
    button.text = _G[button:GetName().."Text"];
    button.text:ClearAllPoints();
    button.text:SetPoint("LEFT"); button.text:SetPoint("RIGHT");
    button:GetHighlightTexture():ClearAllPoints();
    button:GetHighlightTexture():SetAllPoints();
    
    button.close = createCloseButton(button);
    button.close:SetPoint("LEFT", button, "RIGHT");
    
    button:SetScript("OnClick", function(self, b)
            self.win:Pop(true);
            WIM.Menu:Hide();
        end);
    button:SetScript("OnUpdate", function(self, elapsed)
            if(self.win and not self.win:IsShown()) then
                self.text:SetAlpha(.65);
            else
                self.text:SetAlpha(1);
            end
        end);
    button.GetMinimumWidth = function(self)
            return self.text:GetStringWidth()+22;
        end
    return button;
end

local function createGroup(title, list, maxButtons, showNone)
    groupCount = groupCount + 1;
    local group = CreateFrame("Frame", "WIM3MenuGroup"..groupCount, _G.WIM3Menu);
    -- set backdrop
    group:SetBackdrop({bgFile = "Interface\\AddOns\\"..addonTocName.."\\Modules\\Textures\\Menu_bg",
        edgeFile = "Interface\\AddOns\\"..addonTocName.."\\Modules\\Textures\\Menu", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 32, right = 32, top = 32, bottom = 32 }});
    group.list = list;
    group.title = CreateFrame("Frame", group:GetName().."Title", group);
    group.title:SetHeight(17);
    group.title:SetPoint("TOPLEFT", 20, -18); group.title:SetPoint("TOPRIGHT", -20, -18);
    group.title.bg = group.title:CreateTexture(nil, "BACKGROUND");
    group.title.bg:SetAllPoints();
    group.title.text = group.title:CreateFontString(nil, "OVERLAY", "ChatFontNormal");
    local font = group.title.text:GetFont();
    group.title.text:SetFont(font, 11, "");
    group.title.text:SetAllPoints();
    group.title.text:SetText(title.." ");
    group.title.text:SetJustifyV("TOP");
    group.title.text:SetJustifyH("RIGHT");
    group.buttons = {};
    local lastButton = group.title;
    local offSet = -16;
    for i=1, maxButtons do
        local button = createButton(group);
        button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT");
        button:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", offSet, 0);
        offSet= 0;
        button.shown = false;
        lastButton = button;
        table.insert(group.buttons, button);
    end
    group.showNone = showNone;
    group.GetButtonCount = function(self)
        local count = 0;
        for i=1, #self.buttons do
            count = self.buttons[i].shown and count+1 or count;
        end
        return count;
    end
    group.UpdateHeight = function(self)
        if(#self.list == 0 and not self.showNone) then
            group:SetHeight(0);
        else
            group:SetHeight(_G.math.max(group.title:GetHeight() + group.buttons[1]:GetHeight()*self:GetButtonCount() + 18*2, 64));
        end
    end
    group.width = 0;
    group.Refresh = function(self)
        local maxWidth = 150-18*2;
        table.sort(self.list, sortWindows);
        for i=1, #self.buttons do
            local button = self.buttons[i];
            if(i > #self.list) then
                button.win = nil;
                button:Hide();
                button.shown = false;
            else
                button.win = self.list[i];
                button.close:Show();
                button.text:SetText(button.win.theUser);
                button:Show();
                button:Enable();
                button.text:SetJustifyH("LEFT");
                button.shown = true;
                maxWidth = _G.math.max(maxWidth, button:GetMinimumWidth());
            end
        end
        self.title:Show();
        if(#self.list == 0) then
            if(self.showNone) then
                self.buttons[1].close:Hide();
                self.buttons[1]:Show();
                self.buttons[1].shown = true;
                self.buttons[1]:Disable();
                self.buttons[1].text:SetJustifyH("LEFT");
                self.buttons[1].text:SetText(L["None"]);
            else
                self.title:Hide();
            end
        end
        self.width = maxWidth+18*2;
        self:UpdateHeight();
    end
    return group;
end


local function createMenu()
    local menu = CreateFrame("Frame", "WIM3Menu", _G.UIParent);
    menu:Hide(); -- testing only.
    menu:SetClampedToScreen(true);
    menu:SetFrameStrata("DIALOG");
    menu:SetToplevel(true);
    menu:SetWidth(180);
    menu:SetHeight(200);
    menu.groups = {};
    --create whisper group
    menu.groups[1] = createGroup(L["Whispers"], lists.whisper, maxButtons.whisper, true);
    menu.groups[1]:SetPoint("TOPLEFT");
    menu.groups[1]:SetPoint("TOPRIGHT");
    --create chat group
    menu.groups[2] = createGroup(L["Chat"], lists.chat, maxButtons.chat, false);
    menu.groups[2]:SetPoint("TOPLEFT", menu.groups[1], "BOTTOMLEFT", 0, 25);
    menu.groups[2]:SetPoint("TOPRIGHT", menu.groups[1], "BOTTOMRIGHT", 0, 25);
    
    menu.Refresh = function(self)
            local groupHeight = 0;
            local groupWidth = 0;
            for i=1, #self.groups do
                self.groups[i]:Refresh();
                groupHeight = groupHeight + self.groups[i]:GetHeight();
                groupWidth = _G.math.max(groupWidth, self.groups[i].width);
            end
            self:SetHeight(groupHeight);
            self:SetWidth(groupWidth);
        end
        
    menu:SetScript("OnUpdate", function(self)
            if(isMouseOver()) then
                self.mouseStamp = _G.time();
            else
                if((_G.time() - self.mouseStamp) > 1) then
                    self:Hide();
                end
            end
        end);
    menu:SetScript("OnShow", function(self)
            self.mouseStamp = _G.time();
        end);
        
    return menu;
end


function Menu:OnWindowCreated(obj)
    -- add obj to specified list & Update
    if(obj.type == "whisper" or obj.type == "chat") then
        addToTableUnique(lists[obj.type], obj);
        WIM.Menu:Refresh();
    end
end

function Menu:OnWindowDestroyed(obj)
    -- remove obj to specified list & Update
    obj.widgets.close.forceShift = nil;
    if(obj.type == "whisper" or obj.type == "chat") then
        removeFromTable(lists[obj.type], obj);
        WIM.Menu:Refresh();
    end
end

function Menu:OnWindowPopped(obj)
    -- check status of obj to specified list & Update
    if(obj.type == "whisper" or obj.type == "chat") then
        WIM.Menu:Refresh();
    end
end


-- for convention, we will load the module as normal.
function Menu:OnEnable()
    if(not WIM.Menu) then
        WIM.Menu = createMenu();
        WIM.Menu:Refresh();
    end
end


-- This is a core module and must always be loaded...
Menu.canDisable = false;
Menu:Enable();