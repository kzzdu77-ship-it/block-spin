--// BlockSpin | Farm Panel (Rayfield)
--// Mobile + PC
--// Single tab: Farm

if game.PlaceId ~= 127742093697776 then
    warn("[BlockSpin] Jogo errado. Entra no BlockSpin primeiro.")
    return
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BlockSpin | Farm",
    LoadingTitle = "Carregando painel...",
    LoadingSubtitle = "by Repo",
    Theme = "DarkBlue",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BlockSpinRepo",
        FileName = "config"
    },
    KeySystem = false
})

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

local state = {
    autoFarm        = false,
    includePlanting = false,
    selectedJob     = "Fishing",
    afkChecker      = true,
    travelMode      = "Underground",
    vehicleType     = "Car",
    rod             = "Smart Select",
    bait            = "Smart Select",
    baitQuantity    = 10,
    fishAmount      = 50,
    targetFish      = "All"
}

local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getHum()  return getChar():FindFirstChildOfClass("Humanoid") end
local function getRoot() return getChar():FindFirstChild("HumanoidRootPart") end

local function teleportTo(pos, yOffset)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, yOffset or 3, 0))
    end
end

local function getNearestByName(keywords)
    local root = getRoot()
    if not root then return nil end
    local nearest, shortest = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if n:find(kw) then
                    local d = (obj.Position - root.Position).Magnitude
                    if d < shortest then
                        shortest = d
                        nearest = obj
                    end
                    break
                end
            end
        end
    end
    return nearest
end

local function fireProximity(part)
    if not part then return end
    for _, c in pairs(part:GetChildren()) do
        if c:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(c) end)
        end
    end
end

local function fireRemotes(keywords, ...)
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if n:find(kw) then
                    pcall(function()
                        if obj:IsA("RemoteEvent") then
                            obj:FireServer(...)
                        else
                            obj:InvokeServer(...)
                        end
                    end)
                    break
                end
            end
        end
    end
end

local farmDebounce = false

local function runAutoFarm()
    if not state.autoFarm or farmDebounce then return end
    farmDebounce = true

    local job = state.selectedJob:lower()
    local keywords
    if job == "fishing" then
        keywords = {"fish", "water", "pond", "lake", "ocean"}
    elseif job == "mining" then
        keywords = {"mine", "ore", "rock", "coal", "gold"}
    elseif job == "farming" then
        keywords = {"crop", "plant", "farm", "seed", "harvest"}
    elseif job == "delivery" then
        keywords = {"deliver", "package", "box", "drop"}
    else
        keywords = {"job", "work"}
    end

    local target = getNearestByName(keywords)
    if target then
        local yOff = (state.travelMode == "Underground") and -10 or 3
        teleportTo(target.Position, yOff)
        task.wait(0.4)
        fireProximity(target)
        local tool = getChar():FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
        fireRemotes({"farm", "work", "job", "collect", "harvest", "fish", "mine"})
        task.wait(0.6)
    end

    if state.includePlanting then
        local plot = getNearestByName({"plot", "soil", "dirt", "plant"})
        if plot then
            teleportTo(plot.Position, 3)
            task.wait(0.3)
            fireRemotes({"plant", "seed", "place"})
        end
    end

    farmDebounce = false
end

local function selectRod()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    if state.rod == "Smart Select" then
        local best, score = nil, -1
        for _, tool in pairs(backpack:GetChildren()) do
            if tool.Name:lower():find("rod") and #tool.Name > score then
                score = #tool.Name
                best = tool
            end
        end
        if best then pcall(function() getHum():EquipTool(best) end) end
    else
        local tool = backpack:FindFirstChild(state.rod)
        if tool then pcall(function() getHum():EquipTool(tool) end) end
    end
end

local function selectBait()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    if state.bait == "Smart Select" then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool.Name:lower():find("bait") then
                pcall(function() getHum():EquipTool(tool) end)
                return
            end
        end
    else
        local tool = backpack:FindFirstChild(state.bait)
        if tool then pcall(function() getHum():EquipTool(tool) end) end
    end
end

local function sellFish()
    if state.fishAmount <= 0 then return end
    local sellPart = getNearestByName({"sell", "shop", "market", "merchant"})
    if sellPart then
        teleportTo(sellPart.Position, 3)
        task.wait(0.4)
        fireProximity(sellPart)
        fireRemotes({"sell", "fish", "shop"}, state.fishAmount, state.targetFish)
    end
end

LocalPlayer.Idled:Connect(function()
    if not state.afkChecker then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    while task.wait(0.5) do
        if state.autoFarm then
            runAutoFarm()
            if state.selectedJob == "Fishing" then
                selectRod()
                selectBait()
                if state.fishAmount > 0 then sellFish() end
            end
        end
    end
end)

local mt = getrawmetatable(game)
local oldNC = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    if getnamecallmethod() == "Kick" and state.afkChecker then return end
    return oldNC(self, ...)
end)
setreadonly(mt, true)

--// ============================================================
--// UI — SÓ A ABA FARM
--// ============================================================
local FarmTab = Window:CreateTab("Farm", nil)

FarmTab:CreateSection("Farm")

FarmTab:CreateToggle({
    Name = "Auto Farm",
    Info = "Start Farming",
    CurrentValue = false,
    Flag = "autoFarm",
    Callback = function(v) state.autoFarm = v end
})

FarmTab:CreateDropdown({
    Name = "Jobs",
    Info = "Select Jobs",
    Options = {"Fishing", "Mining", "Farming", "Delivery"},
    CurrentOption = {"Fishing"},
    Flag = "jobSelect",
    Callback = function(opt) state.selectedJob = opt[1] end
})

FarmTab:CreateToggle({
    Name = "Include Planting",
    Info = "It plants automatically while you are farming other jobs.",
    CurrentValue = false,
    Flag = "includePlanting",
    Callback = function(v) state.includePlanting = v end
})

FarmTab:CreateSection("Fishing")

FarmTab:CreateToggle({
    Name = "Afk Checker",
    Info = "If your character stays idle for more than 5 minutes, it will automatically rejoin.",
    CurrentValue = true,
    Flag = "afkChecker",
    Callback = function(v) state.afkChecker = v end
})

FarmTab:CreateDropdown({
    Name = "Travel Mode",
    Info = "Fishing only — Normal or Underground.",
    Options = {"Underground", "Normal"},
    CurrentOption = {"Underground"},
    Flag = "travelMode",
    Callback = function(opt) state.travelMode = opt[1] end
})

FarmTab:CreateDropdown({
    Name = "Vehicle Type",
    Info = "Select Vehicle Type.",
    Options = {"Car", "Boat", "Helicopter", "Bike"},
    CurrentOption = {"Car"},
    Flag = "vehicleType",
    Callback = function(opt) state.vehicleType = opt[1] end
})

FarmTab:CreateDropdown({
    Name = "Rod",
    Info = "Select Hacktools, recommend Smart Select.",
    Options = {"Smart Select", "Basic Rod", "Pro Rod", "Legendary Rod"},
    CurrentOption = {"Smart Select"},
    Flag = "rodSelect",
    Callback = function(opt) state.rod = opt[1] end
})

FarmTab:CreateDropdown({
    Name = "Bait",
    Info = "Select Hacktools, recommend Smart Select.",
    Options = {"Smart Select", "Worm", "Shrimp", "Magnetic"},
    CurrentOption = {"Smart Select"},
    Flag = "baitSelect",
    Callback = function(opt) state.bait = opt[1] end
})

FarmTab:CreateInput({
    Name = "Bait Quantity",
    Info = "Number of Bait you need to buy.",
    CurrentValue = "10",
    PlaceholderText = "10",
    Flag = "baitQty",
    Callback = function(v)
        local n = tonumber(v)
        if n then state.baitQuantity = n end
    end
})

FarmTab:CreateInput({
    Name = "Fish Amount",
    Info = "Put number you need to sell fish.",
    CurrentValue = "50",
    PlaceholderText = "50",
    Flag = "fishAmt",
    Callback = function(v)
        local n = tonumber(v)
        if n then state.fishAmount = n end
    end
})

FarmTab:CreateDropdown({
    Name = "Target Fish",
    Info = "Select fish to keep. Ordered Common > Legendary. Default all.",
    Options = {"All", "Perch", "Salmon", "Tuna", "Shark", "Legendary"},
    CurrentOption = {"All"},
    Flag = "targetFish",
    Callback = function(opt) state.targetFish = opt[1] end
})

Rayfield:Notify({
    Title = "BlockSpin | Farm",
    Content = "Painel carregado. Ativa o Auto Farm pra começar.",
    Duration = 4
})
