--------------------------------------------------------------------------------------------------------------------


 -- Blox Fruits script open source (in case for learning only) (If you copid my work renamed it as your own and publish it, That's a big skill issue)


--------------------------------------------------------------------------------------------------------------------

local executor = getgenv().identifyexecutor and (getgenv().identifyexecutor()) or game["Run Service"]:IsStudio() and (game["Run Service"]:IsServer() and "Server" or "Client").."StudioApp" or game["Run Service"]:IsServer() and "Server" or "Client"

local RunService = game:GetService("RunService")
local Lightning = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local function sendSystemNotification(title, text, duration, icon, button1Text, button2Text, callbackFunction)
	local success = false
	while not success do
		success = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = title,
				Text = text,
				Duration = duration or 5,
				Icon = icon or "rbxassetid://0", 
				Button1 = button1Text,
				Button2 = button2Text,
				Callback = callbackFunction 
			})
		end)
		task.wait(0.5)
	end
end

repeat task.wait() until game:IsLoaded()

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 5)
local Humanoid = Character:WaitForChild("Humanoid", 5)

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")


local FallDamageconnection
local Tweenconnection

local CurrentWeapon = "Melee"

local Function = {
    ["Settings"] = {
        ["Fast Attack"] = true,
        ["Attack Delay"] = 0.15,

        ["Attack Mobs"] = true,
        ["Attack Players"] = false,

        ["Bring Enemy"] = true,
        ["Smooth Bring"] = false,
        ["Bring Distance"] = 350,
        ["Bring Speed"] = 200,

        ["Auto Haki"] = true,

        ["Selected Weapon"] = "Melee",

        ["Tween Speed"] = 300,
    },

    ["Farming"] = {
        ["Selected Mob"] = "None",
        ["Selected Zone"] = "None",

        ["Auto Farm Level"] = false,
    },

    ["Travel"] = {
        ["Selected"] = "None",
        ["Traveling"] = false,
    },

    ["Local"] = {
        ["No Fall Damage"] = true,
    },
}

local function IslandTableList()
    local Islands = {}
    for _, v in ipairs(workspace:WaitForChild("Map"):GetChildren()) do
        if v:IsA("Model") and (v.Name ~= "TeleportSpawn" or v.Name ~= "Fishmen" or v.Name ~= "SkyArea1" or v.Name ~= "SkyArea2") then
            table.insert(Islands, v)
        end
    end
    return Islands
end

local function GetSessionID()

    local SendHitsToServer = getrenv()._G.SendHitsToServer
    local CombatThread = getupvalues(SendHitsToServer)[1]

    local UserIDSlice = tostring(Player.UserId):sub(2, 4)
    local MemorySlice = tostring(CombatThread):sub(11, 15)

    local SessionID = UserIDSlice .. MemorySlice

    return SessionID
end

print("Session ID Test:", GetSessionID())

local function randomString(num)
    if not num then return end
	local length = math.random(num)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function Dis(conn)
    if conn then
        if type(conn) == "thread" then task.cancel(conn)
        else conn:Disconnect() end
    end
    return nil
end

local function C_falldmg()
    Dis(FallDamageconnection)
end

local function Falldmg()
    C_falldmg()
    if not HumanoidRootPart then return end

    FallDamageconnection = RunService.Heartbeat:Connect(function()
        if not Function["Local"]["No Fall Damage"] then
            if FallDamageconnection then FallDamageconnection:Disconnect() end
            return
        end
        if not HumanoidRootPart or not HumanoidRootPart.Parent then
            if FallDamageconnection then FallDamageconnection:Disconnect() end
            return
        end

        local oldVel = HumanoidRootPart.AssemblyLinearVelocity
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        RunService.RenderStepped:Wait()
        HumanoidRootPart.AssemblyLinearVelocity = oldVel
    end)
end

local function Tween(part, target, speed, onComplete)
    if not part or not part.Parent then return end
    if part:GetAttribute("Moving") then return end

    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
    part:SetAttribute("Moving", true)

    local targetCF
    if typeof(target) == "Instance" then
        targetCF = target.CFrame
    elseif typeof(target) == "Vector3" then
        targetCF = CFrame.new(target)
    else
        targetCF = target
    end

    local startCF = part.CFrame
    local alpha = 0 

    if Tweenconnection then
        Tweenconnection:Disconnect()
        Tweenconnection = nil
    end

    Tweenconnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not part.Parent or Cancel then
            if Tweenconnection then
                Tweenconnection:Disconnect()
                Tweenconnection = nil
            end

            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
            part:SetAttribute("Moving", false)
            return
        end

        local currentSpeed = tonumber(Function["Settings"]["Tween Speed"]) or speed or 290

        local totalDistance = (targetCF.Position - startCF.Position).Magnitude

        if totalDistance < 0.001 then
            alpha = 1
        else
            local alphaIncrement = (currentSpeed * deltaTime) / totalDistance
            alpha = math.clamp(alpha + alphaIncrement, 0, 1)
        end

        local nextCF = startCF:Lerp(targetCF, alpha)
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.CFrame = nextCF

        if alpha >= 1 then
            if Tweenconnection then
                Tweenconnection:Disconnect()
                Tweenconnection = nil
            end
            part:SetAttribute("Moving", false)
            if onComplete then onComplete() end
        end
    end)
end

local function Instanttp(part, target, onComplete)
    if not part or not part.Parent then return end
    if part:GetAttribute("Moving") then return end

    local targetCF

    if typeof(target) == "Instance" then
        targetCF = target.CFrame
    elseif typeof(target) == "Vector3" then
        targetCF = CFrame.new(target)
    else
        targetCF = target
    end

    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
    part.CFrame = targetCF

    if onComplete then onComplete() end
end

local function Canceltween()
    Dis(Tweenconnection)

    HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    HumanoidRootPart:SetAttribute("Moving", false)
end

function E_Haki()
	if not Character:FindFirstChild("HasBuso") then
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Buso")
	end
end

local function InMyNetWork(object)
    if not object then return end
	    if isnetworkowner then
	    	return isnetworkowner(object)
	    else
	    	if (object.Position - HumanoidRootPart.Position).Magnitude <= 350 then 
	    		return true
	    	end
	    return false
	end
end

local function G_Targets()
    if not HumanoidRootPart then return nil, {} end

    local mainTarget = nil
    local otherTargets = {}

    local function checkAndAdd(model)
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then

            local R15Parts = {
                "HumanoidRootPart", "UpperTorso", "LowerTorso", "Head",
                "RightUpperArm", "RightLowerArm", "RightHand",
                "LeftUpperArm", "LeftLowerArm", "LeftHand",
                "RightUpperLeg", "RightLowerLeg", "RightFoot",
                "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"
            }
    
            local availableParts = {}
            for _, partName in ipairs(R15Parts) do
                local part = model:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    table.insert(availableParts, part)
                end
            end

            if #availableParts > 0 then
                local enemyPart = availableParts[math.random(1, #availableParts)]
                
                local dist = (HumanoidRootPart.Position - enemyPart.Position).Magnitude
                if dist <= 50 then
                    if not mainTarget then
                        mainTarget = enemyPart
                    else
                        table.insert(otherTargets, {model, enemyPart})
                    end
                end
            end
        end
    end

    if Function["Settings"]["Attack Players"] then
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= Player and p.Character then
                checkAndAdd(p.Character)
            end
        end
    end

    if Function["Settings"]["Attack Mobs"] then
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                if enemy:IsA("Model") then
                    checkAndAdd(enemy)
                end
            end
        end
    end

    return mainTarget, otherTargets
end

local function Attack()
    local mainPart, extraTargets = G_Targets()
    if not mainPart or not mainPart.Parent then return end
    RegisterAttack:FireServer(0.5)
    task.wait()
    local dataTable = {
        mainPart,
        extraTargets,
        nil,
        GetSessionID()
    }
    RegisterHit:FireServer(unpack(dataTable))
end

local BringingMobs = {}
local _childAddedConnected = false

local function BringMobs(TargetCFrame, NameM)
    if not TargetCFrame or (typeof(TargetCFrame) ~= "CFrame" and typeof(TargetCFrame) ~= "Instance") then
        warn("Failed to get position: TargetCFrame is invalid.")
        return
    end

    -- Get target position and preserve full CFrame for the orbit calculations
    local TargetPosition = typeof(TargetCFrame) == "Instance" and TargetCFrame.Position or TargetCFrame.Position
    local baseCFrame = typeof(TargetCFrame) == "Instance" and TargetCFrame.CFrame or TargetCFrame

    if not TargetPosition then
        warn("Failed to get position.")
        return
    end

    local function manageMobMovement(mob, hrp, hum, bp)
        local maxDistance = tonumber(Function["Settings"]["Bring Distance"]) or 300
        local orbitRadius = 10        
        local orbitSpeed = 3         

        task.spawn(function()
            while hum.Health > 0 and hrp and bp.Parent do
                if not TargetPosition then bp:Destroy(); break end
                
                local distNow = (hrp.Position - TargetPosition).Magnitude

                if distNow > maxDistance then
                    bp:Destroy()
                    BringingMobs[mob] = nil
                    break
                end

                if distNow < 3 then
                    local currentTime = os.clock()
                    local offsetX = math.sin(currentTime * orbitSpeed) * orbitRadius
                    local offsetZ = math.cos(currentTime * orbitSpeed) * orbitRadius

                    bp.Position = TargetPosition + Vector3.new(offsetX, 0, offsetZ)
                else
                    bp.Position = TargetPosition
                end
                
                task.wait()
            end
            
            if bp and bp.Parent then
                bp:Destroy()
            end
            BringingMobs[mob] = nil
        end)
    end

    for _, mob in ipairs(workspace:WaitForChild("Enemies"):GetChildren()) do
        if mob:IsA("Model") and mob.Name == NameM then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                continue
            end

            local maxDistance = tonumber(Function["Settings"]["Bring Distance"]) or 300
            local distance = (hrp.Position - TargetPosition).Magnitude
            if distance > maxDistance then
                continue
            end

            if not InMyNetWork(hrp) then
                warn("Not mine (sad)")
                continue
            end

            if BringingMobs[mob] then
                continue
            end

            BringingMobs[mob] = true

            if hrp:FindFirstChildOfClass("BodyPosition") then
                hrp:FindFirstChildOfClass("BodyPosition"):Destroy()
            end

            for _, part in pairs(mob:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Massless = true
                end
            end

            local bp = Instance.new("BodyPosition", hrp)
            bp.Name = "BringMob_"..math.random(100000,999999) .. randomString(15, 30)
            bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bp.P = tonumber(Function["Settings"]["Bring Speed"]) or 300
            if Function["Settings"]["Smooth Bring"] then
                bp.D = math.clamp(bp.P * 0.1, 50, 350)
            else
                bp.D = 50
            end

            bp.Position = TargetPosition

            manageMobMovement(mob, hrp, hum, bp)
        end
    end

    if not _childAddedConnected then
        _childAddedConnected = true
        workspace:WaitForChild("Enemies").ChildAdded:Connect(function(newMob)
            task.wait()

            if not TargetPosition then return end 
            
            if newMob:IsA("Model") and newMob.Name == NameM then
                local hrp = newMob:FindFirstChild("HumanoidRootPart")
                local hum = newMob:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then return end

                local maxDistance = tonumber(Function["Settings"]["Bring Distance"]) or 300
                local distance = (hrp.Position - TargetPosition).Magnitude
                if distance > maxDistance then
                    return
                end

                if not InMyNetWork(hrp) then
                    warn("Not mine (sad)")
                    return
                end

                if BringingMobs[newMob] then return end
                BringingMobs[newMob] = true

                for _, part in pairs(newMob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Massless = true
                    end
                end

                local bp = Instance.new("BodyPosition", hrp)
                bp.Name = "BringMob_"..math.random(100000,999999) .. randomString(15, 30)
                bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bp.P = tonumber(Function["Settings"]["Bring Speed"]) or 300
                if Function["Settings"]["Smooth Bring"] then
                    bp.D = math.clamp(bp.P * 0.1, 50, 350)
                else
                    bp.D = 50
                end

                bp.Position = TargetPosition

                manageMobMovement(newMob, hrp, hum, bp)
            end
        end)
    end
end

local function Parsenum(str)
    if not str then return 0 end

    local cleaned = tostring(str):gsub("[^%d]", "")
    return tonumber(cleaned) or 0
end

local function Click(target, hold, duration)
    if not target then return end

    hold = hold or false
    duration = duration or 0.1

    pcall(function()
        GuiService.SelectedObject = target
        task.wait()

        if hold then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(duration)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end

        GuiService.SelectedObject = nil
    end)
end

local function C_Lv()
    local Level = Player:WaitForChild("Data"):WaitForChild("Level").Value
    if Level <= 10 
       or Function["Farming"]["Selected Mob"] == "Bandit" 
       or (Function["Farming"]["Selected Zone"] == "Pirate Starter" and Player.Team.Name == "Pirates") then
        Mob = "Bandit"
        Quest = "BanditQuest1"
        QuestStage = 1
        QuestAt = CFrame.new(1043.25684, 26.5099926, 1557.40234, -0.176764727, 7.62294121e-08, 0.984253109, 5.02705575e-08, 1, -6.84207606e-08, -0.984253109, 3.73845772e-08, -0.176764727)
        MobAt = CFrame.new(1036.46643, 80.5894089, 1594.23425, 0.998629153, 2.65692055e-08, 0.0523437858, -3.05579562e-08, 1, 7.54026246e-08, -0.0523437858, -7.68987789e-08, 0.998629153)

    elseif Level <= 10 
        or Function["Farming"]["Selected Mob"] == "Trainee" 
        or (Function["Farming"]["Selected Zone"] == "Marine Starter" and Player.Team.Name == "Marines") then
        Mob = "Trainee"
        Quest = "MarineQuest"
        QuestStage = 1
        QuestAt = CFrame.new(-2708.21094, 34.2863045, 2133.08667, -0.785682142, 1.79072703e-08, 0.61863035, 1.74382842e-09, 1, -2.67319162e-08, -0.61863035, -1.99240056e-08, -0.785682142)
        MobAt = CFrame.new(-2847.14258, 41.0435829, 2186.98267, 0.800139606, 5.58095223e-08, -0.599813819, -1.94275387e-08, 1, 6.7128795e-08, 0.599813819, -4.20595043e-08, 0.800139606)

    elseif Level <= 15 
        or Function["Farming"]["Selected Mob"] == "Monkey" 
        or Function["Farming"]["Selected Zone"] == "Jungle" then
        Mob = "Monkey"
        Quest = "JungleQuest"
        QuestStage = 1
        QuestAt = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102)
        MobAt = CFrame.new(-1448.1446533203, 50.851993560791, 63.60718536377)

    elseif Level <= 30 
        or Function["Farming"]["Selected Mob"] == "Monkey" 
        or Function["Farming"]["Selected Zone"] == "Jungle" then
        Mob = "Gorilla"
        Quest = "JungleQuest"
        QuestStage = 2
        QuestAt = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102)
        MobAt = CFrame.new(-1142.6488037109, 40.462348937988, -515.39227294922)

    elseif Level <= 40
        or Function["Farming"]["Selected Mob"] == "Pirate" 
        or Function["Farming"]["Selected Zone"] == "Buggy" then
        Mob = "Pirate"
        Quest = "BuggyQuest1"
        QuestStage = 1
        QuestAt = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188)
        MobAt = CFrame.new(-1201.0881347656, 40.628940582275, 3857.5966796875)

    elseif Level <= 60
        or Function["Farming"]["Selected Mob"] == "Brute" 
        or Function["Farming"]["Selected Zone"] == "Buggy" then
        Mob = "Brute"
        Quest = "BuggyQuest1"
        QuestStage = 2
        QuestAt = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188)
        MobAt = CFrame.new(-1387.5324707031, 24.592035293579, 4100.9575195313)

    elseif Level <= 75
        or Function["Farming"]["Selected Mob"] == "Desert Bandit" 
        or Function["Farming"]["Selected Zone"] == "Desert" then
        Mob = "Desert Bandit"
        Quest = "DesertQuest"
        QuestStage = 1
        QuestAt = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625)
        MobAt = CFrame.new(984.99896240234, 16.109552383423, 4417.91015625)

    elseif Level <= 90
        or Function["Farming"]["Selected Mob"] == "Desert Officer" 
        or Function["Farming"]["Selected Zone"] == "Desert" then
        Mob = "Desert Officer"
        Quest = "DesertQuest"
        QuestStage = 2
        QuestAt = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625)
        MobAt = CFrame.new(1547.1510009766, 14.452038764954, 4381.8002929688)

    elseif Level <= 100
        or Function["Farming"]["Selected Mob"] == "Snow Bandit" 
        or Function["Farming"]["Selected Zone"] == "Snow" then
        Mob = "Snow Bandit"
        Quest = "SnowQuest"
        QuestStage = 1
        QuestAt = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156)
        MobAt = CFrame.new(1356.3028564453, 105.76865386963, -1328.2418212891)

    elseif Level <= 120
        or Function["Farming"]["Selected Mob"] == "Snowman" 
        or Function["Farming"]["Selected Zone"] == "Snow" then
        Mob = "Snowman"
        Quest = "SnowQuest"
        QuestStage = 2
        QuestAt = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156)
        MobAt = CFrame.new(1218.7956542969, 138.01184082031, -1488.0262451172)

    elseif Level <= 150
        or Function["Farming"]["Selected Mob"] == "Chief Petty Officer" 
        or Function["Farming"]["Selected Zone"] == "Marine" then
        Mob = "Chief Petty Officer"
        Quest = "MarineQuest2"
        QuestStage = 1
        QuestAt = CFrame.new(-5028, 29, 4329)
        MobAt = CFrame.new(-4915, 179, 4325)

    elseif Level <= 175
        or Function["Farming"]["Selected Mob"] == "Sky Bandit" 
        or Function["Farming"]["Selected Zone"] == "Sky" then
        Mob = "Sky Bandit"
        Quest = "SkyQuest"
        QuestStage = 1
        QuestAt = CFrame.new(-4913, 738, -2578)
        MobAt = CFrame.new(-5016, 343, -2919)

    elseif Level <= 190
        or Function["Farming"]["Selected Mob"] == "Dark Master" 
        or Function["Farming"]["Selected Zone"] == "Sky" then
        Mob = "Dark Master"
        Quest = "SkyQuest"
        QuestStage = 2
        QuestAt = CFrame.new(-4913, 738, -2578)
        MobAt = CFrame.new(-5246, 393, -2207)

    elseif Level <= 210
        or Function["Farming"]["Selected Mob"] == "Prisoner" 
        or Function["Farming"]["Selected Zone"] == "Prison" then
        Mob = "Prisoner"
        Quest = "PrisonerQuest"
        QuestStage = 1
        QuestAt = CFrame.new(5304, 2, 463)
        MobAt = CFrame.new(5050, 73, 431)

    elseif Level <= 250
        or Function["Farming"]["Selected Mob"] == "Dangerous Prisoner" 
        or Function["Farming"]["Selected Zone"] == "Prison" then
        Mob = "Dangerous Prisoner"
        Quest = "PrisonerQuest"
        QuestStage = 2
        QuestAt = CFrame.new(5304, 2, 463)
        MobAt = CFrame.new(5382, 89, 1009)

    elseif Level <= 275
        or Function["Farming"]["Selected Mob"] == "Toga Warrior" 
        or Function["Farming"]["Selected Zone"] == "Colosseum" then
        Mob = "Toga Warrior"
        Quest = "ColosseumQuest"
        QuestStage = 1
        QuestAt = CFrame.new(-1566, 7, -2981)
        MobAt = CFrame.new(-1896, 7, -2744)

    elseif Level <= 300
        or Function["Farming"]["Selected Mob"] == "Gladiator" 
        or Function["Farming"]["Selected Zone"] == "Colosseum" then
        Mob = "Gladiator"
        Quest = "ColosseumQuest"
        QuestStage = 2
        QuestAt = CFrame.new(-1566, 7, -2981)
        MobAt = CFrame.new(-1314, 7, -3278)
    end
end

C_Lv()

function G_Q()
	C_Lv()
	CommF:InvokeServer("StartQuest", Quest, QuestStage)
end

function GetWeaponInventory(Weaponname)
    for i,v in pairs(CommF:InvokeServer("getInventory")) do
        if type(v) == "table" then
            if v.Type == "Sword" then
                if v.Name == Weaponname then
                return true
                end
            end
        end
    end
return false
end

function Equip(tool)
    if Humanoid and tool.Parent ~= Character then
        Humanoid:EquipTool(tool)
    end
end

local function u_c(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
    Humanoid = newChar:WaitForChild("Humanoid", 5)
end

if Player.Character then
    u_c(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    u_c(char)
end)

local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Library:CreateWindow{
    Title = "Anchor Hub -",
    SubTitle = "Blox Fruits - [ " .. executor .. " ]",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Resize = false,
    MinSize = Vector2.new(520, 380),
    Acrylic = false,
    Theme = "GitHub Dark Default",
    MinimizeKey = Enum.KeyCode.K
}

local Options = Library.Options

local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "house"
    },

    Travel = Window:CreateTab{
        Title = "Travel",
        Icon = "map-pin"
    }
}

Tabs.Main:Section("Farm Settings")

local WeaponDrop = Tabs.Main:CreateDropdown("WeaponDrop", {
    Title = "Select Weapon",
    Values = {"Melee", "Sword", "Fruit"},
    Multi = false,
    Default = "Melee",
})

WeaponDrop:OnChanged(function(Value)
    CurrentWeapon = Value
end)

local AtkDown = Tabs.Main:CreateDropdown("AttackDown", {
    Title = "Attack Delay",
    Values = {"0.15", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"},
    Multi = false,
    Default = "0.15",
})

AtkDown:OnChanged(function(Value)
    Function["Settings"]["Attack Delay"] = Value
end)

local TargetMob = Tabs.Main:CreateToggle("Target Mob", {Title = "Attack Mobs", Default = true })

TargetMob:OnChanged(function(Bool)
    Function["Settings"]["Attack Mobs"] = Bool
end)

local TargetPlayer = Tabs.Main:CreateToggle("Target Player", {Title = "Attack Players", Default = false })

TargetPlayer:OnChanged(function(Bool)
    Function["Settings"]["Attack Players"] = Bool
end)

local FastAttack = Tabs.Main:CreateToggle("Fast Attack", {Title = "Enable Fast Attack", Default = true })

FastAttack:OnChanged(function(Bool)
    Function["Settings"]["Fast Attack"] = Bool
end)

local BringDistanceDown = Tabs.Main:CreateDropdown("BringDistanceDown", {
    Title = "Bring Distance",
    Values = {"100", "150", "200", "250", "300", "350", "400", "450"},
    Multi = false,
    Default = "350",
})

BringDistanceDown:OnChanged(function(Value)
    Function["Settings"]["Bring Distance"] = Value
end)

local BringSpeedeDown = Tabs.Main:CreateDropdown("BringSpeedeDown", {
    Title = "Bring Speed",
    Values = {"100", "150", "200", "250", "300", "350", "400", "450", "500"},
    Multi = false,
    Default = "200",
})

BringSpeedeDown:OnChanged(function(Value)
    Function["Settings"]["Bring Speed"] = Value
end)

local SmoothBring = Tabs.Main:CreateToggle("Smooth Bring", {Title = "Enable Smooth Bring (Mob)", Default = false })

SmoothBring:OnChanged(function(Bool)
    Function["Settings"]["Smooth Bring"] = Bool
end)

local BringEnemy = Tabs.Main:CreateToggle("Bring Enemy", {Title = "Enable Bring Enemy (Mob)", Default = true })

BringEnemy:OnChanged(function(Bool)
    Function["Settings"]["Bring Enemy"] = Bool
end)

local AutoBuso = Tabs.Main:CreateToggle("Auto Buso", {Title = "Enable Auto Buso Haki", Default = true })

AutoBuso:OnChanged(function(Bool)
    Function["Settings"]["Auto Haki"] = Bool
end)

Tabs.Main:Section("Movement Settings")

Tabs.Main:CreateSlider("TweenSpeedSlider", {
    Title = "Tween Speed",
    Default = 300,
    Min = 100,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        Function["Settings"]["Tween Speed"] = Value
    end
})

Tabs.Main:Section("Farming")

local AutoFarm = Tabs.Main:CreateToggle("AutoFarm", {Title = "Enable Auto Farm Level", Default = false })

AutoFarm:OnChanged(function(Bool)
    Function["Farming"]["Auto Farm Level"] = Bool
    if not Bool then Canceltween() end
end)

Tabs.Travel:Section("Island Travel")

local IslandDrop = Tabs.Travel:CreateDropdown("IslandDrop", {
    Title = "Select Island",
    Values = "None", IslandTableList(),
    Multi = false,
    Default = "None",
})

IslandDrop:OnChanged(function(Value)
    Function["Travel"]["Selected"] = Value
end)

local AutoTravel = Tabs.Travel:CreateToggle("Auto Travel", {Title = "Enable Auto Travel", Default = false })

AutoTravel:OnChanged(function(Bool)
    Function["Travel"]["Traveling"] = Bool
    if not Bool then Canceltween() end
end)

task.spawn(function()
    while task.wait(1) do
        if not Character:FindFirstChild("HasBuso") and Function["Settings"]["Auto Haki"] then
            E_Haki()
        end
    end
end)

task.spawn(function()
    while true do
        if Function["Settings"]["Fast Attack"] then
            Attack()
        end

        task.wait(Function["Settings"]["Attack Delay"])
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if CurrentWeapon == "Melee" then
            for _, t in pairs(Player.Backpack:GetChildren()) do
                if t:IsA("Tool") and t.ToolTip == "Melee" then
                    if Player.Backpack:FindFirstChild(tostring(t.Name)) then
                        Function["Settings"]["Selected Weapon"] = t.Name
                    end
                end
            end

            elseif CurrentWeapon == "Sword" then
                for _, t in pairs(Player.Backpack:GetChildren()) do
                    if t:IsA("Tool") and t.ToolTip == "Sword" then
                        if Player.Backpack:FindFirstChild(tostring(t.Name)) then
                            Function["Settings"]["Selected Weapon"] = t.Name
                        end
                    end
                end

            elseif CurrentWeapon == "Fruit" then
                for _, t in pairs(Player.Backpack:GetChildren()) do
                    if t:IsA("Tool") and t.ToolTip == "Blox Fruit" then
                        if Player.Backpack:FindFirstChild(tostring(t.Name)) then
                            Function["Settings"]["Selected Weapon"] = t.Name
                        end
                    end
                end
        end
    end
end)

local targetMob = nil      
local storedMobPos = nil

task.spawn(function()
    while true do
        task.wait()
        if Function["Farming"]["Auto Farm Level"] then
            C_Lv()

            pcall(function()
                sethiddenproperty(Player, "SimulationRadius", math.huge)
            end)

            if Mob then
                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible and string.find(questGui.Container.QuestTitle.Title.Text, Mob)

                if not hasQuest then
                    CommF:InvokeServer("AbandonQuest")
                    Tween(HumanoidRootPart, QuestAt, Function["Settings"]["Tween Speed"], function()
                        G_Q()
                    end)
                else
                    local enemies = workspace:FindFirstChild("Enemies")
                    local nearestEnemy = nil
                    local shortestDistance = math.huge

                    if enemies and HumanoidRootPart then
                        for _, v in ipairs(enemies:GetChildren()) do
                            if v.Name == Mob and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                                if targetMob == nil or v == targetMob then
                                    local distance = (HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                                    if distance < shortestDistance then
                                        shortestDistance = distance
                                        nearestEnemy = v
                                    end
                                end
                            end
                        end
                    end

                    if nearestEnemy then
                        if not targetMob then
                            targetMob = nearestEnemy
                            storedMobPos = nearestEnemy.HumanoidRootPart.Position
                        end

                        local toolName = Function["Settings"]["Selected Weapon"]
                        local tool = Player.Backpack:FindFirstChild(toolName) or Character:FindFirstChild(toolName)
                        
                        if tool then
                            Equip(tool)
                        else
                            warn("Weapon not found")
                        end

                        local travelPos = storedMobPos or nearestEnemy.HumanoidRootPart.Position

                        Tween(HumanoidRootPart, nearestEnemy.HumanoidRootPart.Position + Vector3.new(0, 15, 0), Function["Settings"]["Tween Speed"])

                        if Function["Settings"]["Bring Enemy"] then
                            BringMobs(CFrame.new(travelPos), nearestEnemy.Name)
                        end
                    else
                        targetMob = nil
                        storedMobPos = nil

                        if HumanoidRootPart and MobAt then
                            Tween(HumanoidRootPart, MobAt.Position, Function["Settings"]["Tween Speed"])
                        end
                    end
                end
            end
        else
            targetMob = nil
            storedMobPos = nil
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Function["Travel"]["Traveling"] then
            if not Function["Travel"]["Selected"] then return end

            local PlaceToTravel = workspace:WaitForChild("Map"):FindFirstChild(tostring(Function["Travel"]["Selected"]))
            if not PlaceToTravel then return end

            Tween(HumanoidRootPart, PlaceToTravel.WorldPosition, Function["Settings"]["Tween Speed"])
        end
    end
end)

sendSystemNotification(
	"System", 
	"In Dev [v1.0.6]", 
	7, 
	"rbxassetid://6034287515" -- Replace with your own image ID if you want an icon
)
