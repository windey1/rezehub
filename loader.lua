if not game:IsLoaded() then
    game.Loaded:Wait()
end

local env = (getgenv and getgenv()) or _G

if env.__REZEHUB_LOADING then
    return
end
env.__REZEHUB_LOADING = true

-- =====================================================================
-- REBRAND TABLE
-- =====================================================================
local REBRAND = {
    { "ZANJIHUB", "REZEHUB" },
    { "ZanjiHub", "RezeHub" },
    { "ZanjiHUB", "RezeHUB" },
    { "zanjihub", "rezehub" },
    { "ZANJI",    "REZE"    },
    { "Zanji",    "Reze"    },
    { "zanji",    "reze"    },
    { "ZANJ",     "REZ"     },
    { "Zanj",     "Rez"     },
    { "zanj",     "rez"     },
}

local function rebrand(s)
    if type(s) ~= "string" then return s end
    for _, p in ipairs(REBRAND) do
        s = s:gsub(p[1], p[2])
    end
    return s
end

-- =====================================================================
-- HTTPGET PATCH
-- =====================================================================
local _origHttpGet = game.HttpGet
local _origHttpGetAsync = game.HttpGetAsync

local function isSourceUrl(url)
    return type(url) == "string"
        and (url:find("%.lua") ~= nil or url:find("%.luau") ~= nil)
end

local function safeHttpGet(self, url, ...)
    local body = _origHttpGet(self, url, ...)
    if isSourceUrl(url) then return rebrand(body) end
    return body
end

local function safeHttpGetAsync(self, url, ...)
    local body = _origHttpGetAsync(self, url, ...)
    if isSourceUrl(url) then return rebrand(body) end
    return body
end

local function installHttpGetPatch()
    local ok1 = pcall(function() game.HttpGet = safeHttpGet end)
    local ok2 = false
    if _origHttpGetAsync then
        ok2 = pcall(function() game.HttpGetAsync = safeHttpGetAsync end)
    end
    return ok1, ok2
end

local function uninstallHttpGetPatch()
    pcall(function() game.HttpGet = _origHttpGet end)
    if _origHttpGetAsync then
        pcall(function() game.HttpGetAsync = _origHttpGetAsync end)
    end
end

-- =====================================================================
-- ROUTES
-- =====================================================================
local GAG = "https://raw.githubusercontent.com/jr0nzz/zanjihub/refs/heads/main/zanjihub.lua"
local RAP = "https://raw.githubusercontent.com/jr0nzz/zanjihub/refs/heads/main/rideapet.lua"
local SAE = "https://raw.githubusercontent.com/jr0nzz/zanjihub/refs/heads/main/stealanegg.lua"

local ROUTES = {
    [126884695634066] = GAG,
    [124977557560410] = GAG,
    [129954712878723] = GAG,
    [108890465381067] = GAG,

    [124216119978534] = RAP,
    [107778070777162] = SAE,
}

-- =====================================================================
-- MAIN
-- =====================================================================
local ok, err = pcall(function()
    local url = ROUTES[game.PlaceId]
    if not url then
        error("Unsupported PlaceId: " .. tostring(game.PlaceId))
    end

    local source
    for i = 1, 3 do
        local success, result = pcall(_origHttpGet, game, url, true)
        if success and type(result) == "string" and #result > 0 then
            source = result
            break
        end
        task.wait(i * 0.5)
    end

    if not source then
        error("Failed to download base script from " .. url)
    end

    source = rebrand(source)

    local chunk, compileError = loadstring(source)
    if not chunk then
        error("Compile error: " .. tostring(compileError))
    end

    do
        installHttpGetPatch()
    end

    local runOk, runErr = pcall(chunk)

    uninstallHttpGetPatch()

    if not runOk then
        error("Runtime error: " .. tostring(runErr))
    end
end)

-- =====================================================================
-- POST-LOAD
-- =====================================================================
if ok then
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP         = Players.LocalPlayer
    local PG         = LP:WaitForChild("PlayerGui")

    local REZE_ICON = "rbxassetid://6031075931"
    local Z_ASSET_ID = "88022909172536"

    local GOLD_LIGHT  = Color3.fromRGB(255, 215, 120)
    local GOLD_BRIGHT = Color3.fromRGB(255, 240, 180)

    -- ── GLASS ───────────────────────────────────────────────────────
    local GLASS_TRANSPARENCY  = 0.55
    local GLASS_BORDER_ALPHA  = 0.25
    local GLASS_CORNER_RADIUS = 12

    local function allRoots()
        local roots = { PG }
        local hok, hui = pcall(function() return gethui() end)
        if hok and hui then table.insert(roots, hui) end
        table.insert(roots, game:GetService("CoreGui"))
        return roots
    end

    local function hasZanji(txt)
        if type(txt) ~= "string" then return false end
        return string.find(txt, "zanj", 1, true) ~= nil
            or string.find(txt, "Zanj", 1, true) ~= nil
            or string.find(txt, "ZANJ", 1, true) ~= nil
    end

    local function isZAsset(img)
        if type(img) ~= "string" or img == "" then return false end
        local l = string.lower(img)
        if string.find(l, "zanj", 1, true) then return true end
        if string.find(l, Z_ASSET_ID, 1, true) then return true end
        return false
    end

    local function isDark(bg)
        return (bg.R + bg.G + bg.B) < 0.35
    end

    -- =================================================================
    -- HOOKS
    -- =================================================================
    local function hookTextLabel(d)
        if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) then return end
        if d:GetAttribute("__reze_text_hooked") then return end
        d:SetAttribute("__reze_text_hooked", true)

        local okR, txt = pcall(function() return d.Text end)
        if okR and hasZanji(txt) then
            pcall(function() d.Text = rebrand(txt) end)
        end

        pcall(function()
            d:GetPropertyChangedSignal("Text"):Connect(function()
                local okR2, txt2 = pcall(function() return d.Text end)
                if okR2 and hasZanji(txt2) then
                    d.Text = rebrand(txt2)
                end
            end)
        end)
    end

    local function hookImage(d)
        if not (d:IsA("ImageLabel") or d:IsA("ImageButton")) then return end
        if d:GetAttribute("__reze_img_hooked") then return end
        d:SetAttribute("__reze_img_hooked", true)

        local okI, img = pcall(function() return d.Image end)
        if okI and isZAsset(img) then
            pcall(function() d.Image = REZE_ICON end)
        end

        pcall(function()
            d:GetPropertyChangedSignal("Image"):Connect(function()
                local okI2, img2 = pcall(function() return d.Image end)
                if okI2 and isZAsset(img2) then
                    d.Image = REZE_ICON
                end
            end)
        end)
    end

    local function hookFloatingToggle(d)
        if not (d:IsA("ImageLabel") or d:IsA("ImageButton")) then return end
        if d:GetAttribute("__reze_float_hooked") then return end
        local p  = d.AbsolutePosition
        local sz = d.AbsoluteSize
        if math.abs(sz.X - sz.Y) < 25
           and sz.X >= 15 and sz.X <= 110
           and p.X >= 0 and p.X < 200
           and p.Y >= 0 and p.Y < 300 then
            d:SetAttribute("__reze_float_hooked", true)
            pcall(function() d.Image = REZE_ICON end)
            pcall(function()
                d:GetPropertyChangedSignal("Image"):Connect(function()
                    if d.Image ~= REZE_ICON then
                        d.Image = REZE_ICON
                    end
                end)
            end)
        end
    end

    -- =================================================================
    -- FIND THE MAIN WINDOW
    -- =================================================================
    local mainWindow = nil

    local function findMainWindow()
        local best, bestArea = nil, 0
        for _, root in ipairs(allRoots()) do
            local okL, list = pcall(function() return root:GetDescendants() end)
            if okL then
                for _, d in ipairs(list) do
                    if (d:IsA("Frame") or d:IsA("ScrollingFrame")) and d.Visible then
                        if d.BackgroundTransparency < 0.5 then
                            local sz = d.AbsoluteSize
                            local area = sz.X * sz.Y
                            if sz.X >= 400 and sz.Y >= 300
                               and sz.X <= 900 and sz.Y <= 700
                               and area > bestArea then
                                best, bestArea = d, area
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    -- =================================================================
    -- GLASS (main window + its direct dark children)
    -- =================================================================
    local glassApplied = {}

    local function applyGlassToFrame(d)
        if glassApplied[d] then return end
        if not (d:IsA("Frame") or d:IsA("ScrollingFrame")) then return end
        if not d.Visible then return end
        if d.BackgroundTransparency >= 0.9 then return end

        local okG, bg = pcall(function() return d.BackgroundColor3 end)
        if not okG or not bg then return end
        if not isDark(bg) then return end

        glassApplied[d] = true
        pcall(function() d.BackgroundTransparency = GLASS_TRANSPARENCY end)
        pcall(function()
            local corner = d:FindFirstChildOfClass("UICorner")
            if not corner then
                corner = Instance.new("UICorner")
                corner.Parent = d
            end
            corner.CornerRadius = UDim.new(0, GLASS_CORNER_RADIUS)
        end)
        pcall(function()
            local stroke = d:FindFirstChildOfClass("UIStroke")
            if not stroke then
                stroke = Instance.new("UIStroke")
                stroke.Parent = d
            end
            stroke.Color = Color3.fromRGB(255, 235, 200)
            stroke.Thickness = 1
            stroke.Transparency = GLASS_BORDER_ALPHA
        end)
    end

    local function applyGlass()
        if not mainWindow or not mainWindow.Parent then
            mainWindow = findMainWindow()
        end
        if not mainWindow then return end

        applyGlassToFrame(mainWindow)

        for _, d in ipairs(mainWindow:GetChildren()) do
            if (d:IsA("Frame") or d:IsA("ScrollingFrame"))
               and d.Visible
               and d.BackgroundTransparency < 0.9 then
                local okG, bg = pcall(function() return d.BackgroundColor3 end)
                if okG and bg and isDark(bg) then
                    local sz = d.AbsoluteSize
                    if sz.X >= 100 and sz.Y >= 40 then
                        applyGlassToFrame(d)
                    end
                end
            end
        end
    end

    -- =================================================================
    -- INDEX
    -- =================================================================
    local textLabels = {}
    local images     = {}

    local function indexInstance(d)
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            table.insert(textLabels, d)
            hookTextLabel(d)
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            table.insert(images, d)
            hookImage(d)
            hookFloatingToggle(d)
        end
    end

    for _, root in ipairs(allRoots()) do
        local okL, list = pcall(function() return root:GetDescendants() end)
        if okL then
            for _, d in ipairs(list) do
                indexInstance(d)
            end
        end
        pcall(function()
            root.DescendantAdded:Connect(function(d)
                indexInstance(d)
                if d:IsA("GuiObject") then
                    for _, c in ipairs(d:GetDescendants()) do
                        indexInstance(c)
                    end
                end
            end)
        end)
    end

    print("[REZEHUB] indexed " .. #textLabels .. " text, " .. #images .. " images")

    -- =================================================================
    -- HIDE CARDS / DISCORD / SELL POPUP
    -- =================================================================
    local HIDE_CARDS = { "SESSION", "QUICKACTIONS" }

    local function sweepHideCards()
        for i = 1, #textLabels do
            local d = textLabels[i]
            if d and d.Parent and d.Visible then
                local t = (d.Text or ""):gsub("%s+", ""):upper()
                for _, name in ipairs(HIDE_CARDS) do
                    if t == name then
                        local node = d
                        for _ = 1, 5 do
                            if not node or not node.Parent then break end
                            node = node.Parent
                            if node:IsA("Frame") and node.AbsoluteSize.Y > 80 then
                                pcall(function() node.Visible = false end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    local function sweepDiscordFooter()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local footerTop = cam.ViewportSize.Y - 120
        for i = 1, #textLabels do
            local d = textLabels[i]
            if d and d.Parent and d.Visible then
                local okR, txt = pcall(function() return d.Text end)
                if okR and type(txt) == "string" and txt ~= "" then
                    local l = string.lower(txt)
                    if (string.find(l, "discord.gg", 1, true)
                        or string.find(l, "discord.com", 1, true))
                       and d.AbsolutePosition.Y >= footerTop then
                        pcall(function() d.Text = "" end)
                        pcall(function() d.Visible = false end)
                    end
                end
            end
        end
    end

    local suppressHooked = {}
    local function suppressContainer(node)
        if not node or suppressHooked[node] then return end
        suppressHooked[node] = true
        pcall(function() node.Visible = false end)
        pcall(function()
            node:GetPropertyChangedSignal("Visible"):Connect(function()
                if node.Visible then node.Visible = false end
            end)
        end)
    end

    local SELL_POPUP_TITLES = {
        "ARESURECONFIRM", "SELLCONFIRMATION", "CONFIRM",
        "SELLPETS", "SELLPET", "SELLINGPETS", "CONFIRMSELL",
        "ARESURE", "ARESUREYOUWANTTOSELL",
    }

    local function sweepSuppressSellPopup()
        for i = 1, #textLabels do
            local d = textLabels[i]
            if d and d.Parent and d.Visible then
                local t = (d.Text or ""):gsub("%s+", ""):upper()
                for _, name in ipairs(SELL_POPUP_TITLES) do
                    if t == name then
                        local node = d
                        for _ = 1, 6 do
                            if not node or not node.Parent then break end
                            node = node.Parent
                            if node:IsA("Frame")
                               and node.AbsoluteSize.X > 200
                               and node.AbsoluteSize.Y > 100 then
                                suppressContainer(node)
                                break
                            end
                        end
                    end
                end
            end
        end
        for _, root in ipairs(allRoots()) do
            if root:IsA("ScreenGui") then
                local n = (root.Name or ""):lower()
                if string.find(n, "sell", 1, true)
                   or string.find(n, "confirm", 1, true) then
                    suppressContainer(root)
                end
            end
        end
    end

    -- =================================================================
    -- GOLD THEME
    -- =================================================================
    local function isPurpleOrCyan(c)
        if c.B < 0.35 then return false end
        if c.B < c.R - 0.10 then return false end
        if c.G > c.R + 0.10 then return false end
        if (c.R + c.G + c.B) < 0.30 then return false end
        return true
    end
    local recoloredText = {}

    local function forceColorSweep()
        for i = 1, #textLabels do
            local d = textLabels[i]
            if d and d.Parent then
                local okR, rtxt = pcall(function() return d.RichText end)
                local okT2, ttxt = pcall(function() return d.Text end)
                if okR and rtxt and okT2 and type(ttxt) == "string"
                   and string.find(ttxt, "rezehub", 1, true)
                   and string.find(ttxt, "<", 1, true) then
                    local newTxt = ttxt:gsub("#9781FF", "#FFD778"):gsub("#9781ff", "#FFD778")
                    if newTxt ~= ttxt then
                        pcall(function() d.Text = newTxt end)
                    end
                end
                local okT, tc = pcall(function() return d.TextColor3 end)
                if okT and tc and isPurpleOrCyan(tc) then
                    recoloredText[d] = true
                    pcall(function() d.TextColor3 = GOLD_LIGHT end)
                end
                if recoloredText[d] then
                    for _, child in ipairs(d:GetChildren()) do
                        if child:IsA("UIGradient") then
                            pcall(function()
                                child.Color = ColorSequence.new(GOLD_LIGHT, GOLD_BRIGHT)
                            end)
                        end
                    end
                end
            end
        end
    end

    -- =================================================================
    -- RENDERSTEP: fast during load, ~30Hz after
    -- =================================================================
    local stepName = "REZEHUB_FINAL_" .. tostring(math.random(1e8))
    local loadPhaseStart = os.clock()
    local LOAD_PHASE_DURATION = 4
    local lastSlowFrame = 0

    RunService:BindToRenderStep(stepName, Enum.RenderPriority.Last.Value, function()
        local now = os.clock()
        local inLoadPhase = (now - loadPhaseStart) < LOAD_PHASE_DURATION

        if inLoadPhase or (now - lastSlowFrame) >= 0.033 then
            lastSlowFrame = now

            for i = 1, #textLabels do
                local d = textLabels[i]
                if d and d.Parent then
                    local okR, txt = pcall(function() return d.Text end)
                    if okR and hasZanji(txt) then
                        pcall(function() d.Text = rebrand(txt) end)
                    end
                end
            end

            for i = 1, #images do
                local d = images[i]
                if d and d.Parent then
                    local okI, img = pcall(function() return d.Image end)
                    if okI and isZAsset(img) then
                        pcall(function() d.Image = REZE_ICON end)
                    end
                end
            end

            applyGlass()
        end
    end)

    -- =================================================================
    -- HEARTBEAT
    -- =================================================================
    local lastCards  = 0
    local lastFooter = 0
    local lastSell   = 0
    local lastColor  = 0

    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastCards >= 0.3 then
            lastCards = now
            sweepHideCards()
        end
        if now - lastFooter >= 0.3 then
            lastFooter = now
            sweepDiscordFooter()
        end
        if now - lastSell >= 0.2 then
            lastSell = now
            sweepSuppressSellPopup()
        end
        if now - lastColor >= 0.25 then
            lastColor = now
            forceColorSweep()
        end
    end)

    sweepHideCards()
    sweepDiscordFooter()
    sweepSuppressSellPopup()
    forceColorSweep()
    applyGlass()

    print("[REZEHUB] loaded")
end

env.__REZEHUB_LOADING = nil

if not ok then
    warn("[REZEHUB] " .. tostring(err))
end
