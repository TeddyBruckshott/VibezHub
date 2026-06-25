--[[
    ╦  ╦╦╔╗ ╔═╗╔═╗  ╦ ╦╦ ╦╔╗
    ╚╗╔╝║╠╩╗║╣ ╔═╝  ╠═╣║ ║╠╩╗
     ╚╝ ╩╚═╝╚═╝╚═╝  ╩ ╩╚═╝╚═╝
    Vibez Hub  —  FREE  |  robloxscripts.com
]]

local CORE_LOADER_URL = "https://api.jnkie.com/api/v1/luascripts/public/404f40f3cbdc9c86fb24c18302977c2a617525879b75e18615f86f25955a3113/download"
local GET_KEY_URL = "https://jnkie.com/get-key/vibes-hub"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local setclip = (setclipboard or set_clipboard or (syn and syn.write_clipboard))
local function copy(text) pcall(function() if setclip then setclip(text) end end) end

----------------------------------------------------------------------
-- Saved keys
----------------------------------------------------------------------
local KEY_FILE = "VibezHub_keys.txt"
local HAS_FS = (type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function")

local function loadKeys()
    if not HAS_FS then return {} end
    local ok, present = pcall(isfile, KEY_FILE)
    if not ok or not present then return {} end
    local rok, raw = pcall(readfile, KEY_FILE)
    if not rok or type(raw) ~= "string" then return {} end
    local out = {}
    for line in raw:gmatch("[^\r\n]+") do
        local k = line:gsub("%s", "")
        if #k > 0 then out[#out + 1] = k end
    end
    return out
end

local function writeKeys(list)
    if not HAS_FS then return end
    pcall(function() writefile(KEY_FILE, table.concat(list, "\n")) end)
end

local function rememberKey(key)
    if not key or key == "" then return end
    local list = loadKeys()
    local out = { key }
    for _, k in ipairs(list) do
        if k ~= key and #out < 5 then out[#out + 1] = k end
    end
    writeKeys(out)
end

local function forgetKey(key)
    local list = loadKeys()
    local out = {}
    for _, k in ipairs(list) do if k ~= key then out[#out + 1] = k end end
    writeKeys(out)
end

local function lastKey()
    local list = loadKeys()
    return list[1]
end

----------------------------------------------------------------------
-- Singleton guard
----------------------------------------------------------------------
pcall(function() if _G.__VibezHubUnload then _G.__VibezHubUnload() end end)
pcall(function()
    getgenv().__VibezAuthed = nil
    getgenv().__VibezReady = nil
end)

----------------------------------------------------------------------
-- UI library
----------------------------------------------------------------------
local VibeUI
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/RealSlimShady2000/VibeUI/main/VibeUI.luau"))()
    end)
    if ok and lib then
        VibeUI = lib
        pcall(function() getgenv().VibeUI = lib end)
    else
        warn("[Vibez Hub] UI library failed to load:", lib)
    end
end

----------------------------------------------------------------------
-- Palette
----------------------------------------------------------------------
local C = {
    gold   = Color3.fromRGB(255, 209, 0),
    green  = Color3.fromRGB(0, 122, 51),
    greenD = Color3.fromRGB(21, 74, 40),
    red    = Color3.fromRGB(170, 28, 28),
    bg     = Color3.fromRGB(9, 16, 10),
    panel  = Color3.fromRGB(13, 22, 14),
    inline = Color3.fromRGB(17, 28, 19),
    text   = Color3.fromRGB(245, 240, 215),
    sub    = Color3.fromRGB(190, 175, 120),
}

----------------------------------------------------------------------
-- GUI helpers
----------------------------------------------------------------------
local function getGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return game:GetService("CoreGui")
end

local function make(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

----------------------------------------------------------------------
-- Loading / key screen
----------------------------------------------------------------------
local screenGui = make("ScreenGui", {
    Name = "VibezHubLoader",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(screenGui) end end)
screenGui.Parent = getGuiParent()

local dim = make("Frame", {
    Name = "Dim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Parent = screenGui,
})

local card = make("Frame", {
    Name = "Card",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(420, 360),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = dim,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 14) }),
    make("UIStroke", { Color = C.green, Thickness = 1.5, Transparency = 0.2 }),
})
make("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 26, 17)),
        ColorSequenceKeypoint.new(1, C.panel),
    }),
    Parent = card,
})

make("Frame", {
    Name = "Stripe",
    Size = UDim2.new(1, 0, 0, 4),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = C.gold,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = card,
}, {
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, C.red),
            ColorSequenceKeypoint.new(0.5, C.gold),
            ColorSequenceKeypoint.new(1.0, C.green),
        }),
    }),
})

-- Draggable card
do
    local dragging, dragStart, startPos
    local conns = {}
    local function disconnectAll() for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end end

    conns[#conns + 1] = card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
            local changed
            changed = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changed then changed:Disconnect() end
                end
            end)
        end
    end)

    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    conns[#conns + 1] = screenGui.Destroying:Connect(disconnectAll)
end

make("TextLabel", {
    Name = "Title",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 30),
    Size = UDim2.new(1, 0, 0, 34),
    Font = Enum.Font.GothamBlack,
    Text = "VIBEZ HUB",
    TextColor3 = C.gold,
    TextSize = 30,
    Parent = card,
})
make("TextLabel", {
    Name = "Subtitle",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 64),
    Size = UDim2.new(1, 0, 0, 18),
    Font = Enum.Font.GothamMedium,
    Text = "robloxscripts.com  •  FREE",
    TextColor3 = C.sub,
    TextSize = 13,
    Parent = card,
})

local status = make("TextLabel", {
    Name = "Status",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 92),
    Size = UDim2.new(1, -40, 0, 34),
    AnchorPoint = Vector2.new(0, 0),
    Font = Enum.Font.Gotham,
    Text = "Booting…",
    TextColor3 = C.text,
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = card,
})

local barBack = make("Frame", {
    Name = "BarBack",
    Position = UDim2.fromOffset(20, 132),
    Size = UDim2.new(1, -40, 0, 8),
    BackgroundColor3 = C.inline,
    BorderSizePixel = 0,
    Parent = card,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local barFill = make("Frame", {
    Name = "BarFill",
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = C.gold,
    BorderSizePixel = 0,
    Parent = barBack,
}, {
    make("UICorner", { CornerRadius = UDim.new(1, 0) }),
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.green),
            ColorSequenceKeypoint.new(1, C.gold),
        }),
    }),
})

local function setProgress(pct, dur)
    pct = math.clamp(pct, 0, 1)
    TweenService:Create(barFill, TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quad), {
        Size = UDim2.fromScale(pct, 1),
    }):Play()
end
local function setStatus(text) status.Text = text end
pcall(function()
    getgenv().__VibezStatus = function(text, pct)
        pcall(function()
            if text then setStatus(tostring(text)) end
            if pct then setProgress(pct) end
        end)
    end
end)

----------------------------------------------------------------------
-- Key entry
----------------------------------------------------------------------
local keyBox = make("TextBox", {
    Name = "KeyBox",
    Position = UDim2.fromOffset(20, 156),
    Size = UDim2.new(1, -40, 0, 40),
    BackgroundColor3 = C.inline,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Paste your key here…",
    PlaceholderColor3 = C.sub,
    Text = "",
    TextColor3 = C.text,
    TextSize = 14,
    ClearTextOnFocus = false,
    Parent = card,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 8) }),
    make("UIStroke", { Color = C.greenD, Thickness = 1 }),
    make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
})

local function makeButton(name, text, y, fill, textColor)
    local btn = make("TextButton", {
        Name = name,
        Position = UDim2.fromOffset(20, y),
        Size = UDim2.new(1, -40, 0, 40),
        BackgroundColor3 = fill,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = textColor or C.text,
        TextSize = 15,
        Parent = card,
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 8) }),
        make("UIStroke", { Color = C.greenD, Thickness = 1, Transparency = 0.3 }),
    })
    return btn
end

local submitBtn = makeButton("Submit", "UNLOCK HUB", 206, C.green, C.text)
local getKeyBtn = makeButton("GetKey", "Get a Key", 254, C.greenD, C.gold)

make("TextLabel", {
    Name = "Footer",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 318),
    Size = UDim2.new(1, 0, 0, 16),
    Font = Enum.Font.Gotham,
    Text = "FREE  •  Right Ctrl to toggle once loaded",
    TextColor3 = C.sub,
    TextSize = 11,
    Parent = card,
})

----------------------------------------------------------------------
-- Auth
----------------------------------------------------------------------
local busy = false

local function setBusy(on)
    busy = on
    submitBtn.Active = not on
    submitBtn.AutoButtonColor = not on
    submitBtn.Text = on and "AUTHENTICATING…" or "UNLOCK HUB"
    keyBox.TextEditable = not on
end

local function fadeOutAndClose()
    setStatus("Welcome to Vibez Hub! 🌴")
    setProgress(1, 0.4)
    task.wait(0.45)
    for _, obj in ipairs(screenGui:GetDescendants()) do
        if obj:IsA("GuiObject") then
            pcall(function()
                TweenService:Create(obj, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
            end)
        end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            pcall(function()
                TweenService:Create(obj, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            end)
        end
        if obj:IsA("UIStroke") then
            pcall(function() TweenService:Create(obj, TweenInfo.new(0.4), { Transparency = 1 }):Play() end)
        end
    end
    TweenService:Create(dim, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    task.wait(0.5)
    screenGui:Destroy()
end

local function doAuth(key, fromMemory)
    if busy then return end
    if not key or key:gsub("%s", "") == "" then
        setStatus("Please paste your key first."); return
    end
    key = key:gsub("^%s*(.-)%s*$", "%1")
    setBusy(true)
    setStatus("Authenticating…")
    setProgress(0.5, 0.45)

    pcall(function() getgenv().SCRIPT_KEY = key end)
    pcall(function() getgenv().__VibezExtendUrl = GET_KEY_URL end)
    pcall(function()
        getgenv().__VibezRelaunch = ("getgenv().SCRIPT_KEY=[==[%s]==] loadstring(game:HttpGet([==[%s]==]))()"):format(key, CORE_LOADER_URL)
    end)
    pcall(function() getgenv().__VibezAuthed = nil; getgenv().__VibezReady = nil end)

    local ok, err = pcall(function()
        local src = game:HttpGet(CORE_LOADER_URL)
        local fn = loadstring(src)
        if not fn then error("loadstring failed") end
        fn()
    end)

    local authed = (getgenv().__VibezAuthed == true)

    if ok and authed then
        rememberKey(key)
        setStatus("Loading hub…"); setProgress(0.85, 0.5)
        local t0 = os.clock()
        while getgenv().__VibezReady ~= true and os.clock() - t0 < 12 do
            task.wait(0.1)
        end
        fadeOutAndClose()
    else
        setBusy(false)
        setProgress(0.3, 0.4)
        local msg = "Invalid or expired key. Grab a new one and try again."
        if not ok and typeof(err) == "string" and #err > 0 then
            msg = "Load error: " .. err:sub(1, 80)
        elseif fromMemory then
            forgetKey(key)
            msg = "Your saved key expired. Tap 'Get a Key' for more time."
        end
        setStatus(msg)
        pcall(function() getgenv().SCRIPT_KEY = nil end)
    end
end

submitBtn.MouseButton1Click:Connect(function() doAuth(keyBox.Text) end)
keyBox.FocusLost:Connect(function(enter) if enter then doAuth(keyBox.Text) end end)
getKeyBtn.MouseButton1Click:Connect(function()
    copy(GET_KEY_URL)
    setStatus("Key link copied! Open it in your browser, grab your key, then paste it here.")
end)

----------------------------------------------------------------------
-- Startup
----------------------------------------------------------------------
local function detectPresetKey()
    local k
    pcall(function() k = SCRIPT_KEY end)
    if type(k) ~= "string" or k == "" then
        pcall(function() k = getgenv().SCRIPT_KEY end)
    end
    if type(k) == "string" and k:gsub("%s", "") ~= "" then return k end
    return nil
end

task.spawn(function()
    setStatus("Initializing…"); setProgress(0.15, 0.4); task.wait(0.4)
    if not VibeUI then
        setStatus("Failed to load — re-execute the script.")
        setProgress(0.3, 0.4)
        return
    end
    local preset = detectPresetKey()
    if preset then
        keyBox.Text = preset
        setStatus("Key detected — authenticating…")
        task.wait(0.25)
        doAuth(preset)
        return
    end
    local saved = lastKey()
    if saved then
        keyBox.Text = saved
        setStatus("Welcome back — using your saved key…")
        task.wait(0.25)
        doAuth(saved, true)
    else
        setStatus("Paste your key, or tap 'Get a Key' to grab one.")
        setProgress(0.3, 0.4)
    end
end)
