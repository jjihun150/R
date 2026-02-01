local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local virtualUser = game:GetService("VirtualUser")
local localPlayer = players.LocalPlayer

-- 1. GUI 생성
local function setupGui()
    local existing = coreGui:FindFirstChild("UltraFarmFinalV4")
    if existing then existing:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "UltraFarmFinalV4"
    sg.Parent = coreGui
    sg.DisplayOrder = 9999
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Name = "MainToggle"
    btn.Parent = sg
    btn.Size = UDim2.new(0, 160, 0, 65)
    btn.Position = UDim2.new(0.05, 0, 0.2, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    btn.Text = "AUTO: OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 24
    btn.Draggable = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    return btn
end

local toggleBtn = setupGui()
local farming = false
local currentTargetIndex = 1
local lastSwitchTime = 0
local mobList = {}
local lastWeaponCheck = 0

toggleBtn.MouseButton1Click:Connect(function()
    farming = not farming
    toggleBtn.Text = farming and "AUTO: ON" or "AUTO: OFF"
    toggleBtn.BackgroundColor3 = farming and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    if farming then 
        currentTargetIndex = 1
        lastSwitchTime = tick()
    end
end)

-- 2. 단순화된 무기 장착 로직
local function checkWeapon()
    if not farming then return end
    if tick() - lastWeaponCheck < 1 then return end
    lastWeaponCheck = tick()
    local char = localPlayer.Character
    if not char then return end   
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if not equippedTool then
        virtualUser:SetKeyDown("1")
        task.wait(0.05)
        virtualUser:SetKeyUp("1")
    end
end
local function handleCaptcha()
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, v in pairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible and v.Text:match("%d") then
                local code = v.Text:gsub("%s+", ""):match("%d%d%d%d") or v.Text:gsub("%s+", ""):match("%d%d%d")
                if code and #code >= 3 then
                    for _, input in pairs(pg:GetDescendants()) do
                        if input:IsA("TextBox") and input.Visible then
                            if input.Text ~= code then
                                input.Text = code
                                task.wait(0.1)
                                input:ReleaseFocus(true)
                                virtualUser:SetKeyDown("enter")
                                task.wait(0.05)
                                virtualUser:SetKeyUp("enter")
                            end
                        end
                    end
                end
            end
        end
    end
end   
    local success, err = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and (self.Name:lower():find("captcha") or self.Name:lower():find("verify")) then
                return oldNamecall(self, "Success", true) 
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function isAliveEnemy(v)
    if not v:IsA("Model") or not v:FindFirstChild("Humanoid") or not v:FindFirstChild("HumanoidRootPart") then return false end
    if v.Humanoid.Health <= 0 or v == localPlayer.Character then return false end
    local n = v.Name:lower()
    local ignore = {"npc", "shop", "quest", "bank", "guide", "town", "citizen", "guard", "dummy", "pet"}
    for _, t in ipairs(ignore) do if n:find(t) then return false end end
    return true
end

local function updateTargets()
    mobList = {}
    local folder = workspace:FindFirstChild("Mobs")
    local source = folder and folder:GetChildren() or workspace:GetDescendants()
    for _, v in pairs(source) do
        if isAliveEnemy(v) then table.insert(mobList, v) end
    end
end

runService.Heartbeat:Connect(function()
    if not farming then return end    
    checkWeapon()
    if tick() % 0.5 < 0.1 then handleCaptcha() end
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = mobList[currentTargetIndex]
    if tick() - lastSwitchTime > 20 or not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then
        updateTargets()
        currentTargetIndex = (currentTargetIndex % #mobList) + 1
        lastSwitchTime = tick()
    end
    local finalTarget = mobList[currentTargetIndex]
    if finalTarget and finalTarget:FindFirstChild("HumanoidRootPart") then
        local th = finalTarget.HumanoidRootPart
        hrp.CFrame = CFrame.new(th.Position + (th.CFrame.LookVector * -3) + Vector3.new(0, 1.5, 0), th.Position)
             local vel = hrp:FindFirstChild("FarmVel") or Instance.new("BodyVelocity", hrp)
        vel.Name = "FarmVel"
        vel.Velocity = Vector3.new(0,0,0)
        vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

  virtualUser:CaptureController()
        virtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.02)
        virtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    else
        updateTargets()
    end

  virtualUser:ClickButton2(Vector2.new(0,0))
end)

localPlayer.CharacterAdded:Connect(function()
    if farming then task.wait(1) checkWeapon() end
end)

print("1")
