local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "DEKHERE STORE",
    Icon = "rbxassetid://71033501459948",
    Author = "# Make By Boss💸",
    Folder = "boss",

    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = {
        Enabled = true,
        Anonymous = false,
        Name = LocalPlayer.Name,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        Callback = function()
            print("User Profile Clicked")
        end,
    }
})

Window:EditOpenButton({
    Enabled = false
})

--===============================
-- Services
--===============================
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

--===============================
-- Custom Toggle Button
--===============================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WindUI_Toggle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.fromOffset(50, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = "rbxassetid://71033501459948"
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.AutoButtonColor = false

--===============================
-- Toggle Logic (FIXED)
--===============================
ToggleBtn.MouseButton1Click:Connect(function()
    ToggleBtn:TweenSize(
        UDim2.fromOffset(56, 56),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.12,
        true,
        function()
            ToggleBtn:TweenSize(
                UDim2.fromOffset(50, 50),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.12,
                true
            )
        end
    )

    -- ✅ ตัวนี้แหละที่ถูก
    Window:Toggle()
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        Window:Toggle()
    end
end)

local Tab = Window:Tab({Title = "Combat", Icon = "sword"})

Tab:Section(
    {
        Title = "Aimbot"
    }
)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==================== VARIABLES ====================
local AimbotEnabled = false
local WallCheckEnabled = false
local TeamCheckEnabled = false
local FOV_RADIUS = 150
local DrawingIsAvailable = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
local FOV_Circle, LockLine

-- ==================== DRAWING ====================
if DrawingIsAvailable then
    FOV_Circle = Drawing.new("Circle")
    FOV_Circle.Radius = FOV_RADIUS
    FOV_Circle.Color = Color3.fromRGB(255,255,255)
    FOV_Circle.Thickness = 2
    FOV_Circle.Transparency = 1
    FOV_Circle.Filled = false
    FOV_Circle.Visible = false

    LockLine = Drawing.new("Line")
    LockLine.Color = Color3.fromRGB(255,0,0)
    LockLine.Thickness = 2
    LockLine.Visible = false
end

-- ==================== GUI SETTINGS ====================
-- Aimlock Toggle
Tab:Toggle({
    Title = "Enable Aimlock",
    Desc = "",
    Value = false,
    Callback = function(v)
        AimbotEnabled = v
        if DrawingIsAvailable and FOV_Circle then FOV_Circle.Visible = v end
        if not v and DrawingIsAvailable and LockLine then LockLine.Visible = false end
    end
})

-- Wall Check Toggle
Tab:Toggle({
    Title = "Wall Check",
    Desc = "",
    Value = false,
    Callback = function(v)
        WallCheckEnabled = v
        print("Wall Check:", v)
    end
})

-- Team Check Toggle
Tab:Toggle({
    Title = "Team Check",
    Desc = "",
    Value = false,
    Callback = function(v)
        TeamCheckEnabled = v
        print("Team Check:", v)
    end
})

-- ==================== HELPER FUNCTIONS ====================
local function isVisible(targetPart)
    if not targetPart then return false end
    if not WallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local ok,res = pcall(function() return Workspace:Raycast(origin,direction,rayParams) end)
    if not ok or not res then return false end
    return res.Instance:IsDescendantOf(targetPart.Parent)
end

local function isSameTeam(player)
    if not TeamCheckEnabled then return false end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

local function getClosestTarget()
    local closestPlayer = nil
    local shortestDistance = FOV_RADIUS
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not isSameTeam(player) then
                local head = player.Character.Head
                local ok,pos,onScreen = pcall(function() return Camera:WorldToViewportPoint(head.Position) end)
                if ok and onScreen then
                    local distance = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                    if distance < shortestDistance and isVisible(head) then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    -- Update FOV circle
    if DrawingIsAvailable and FOV_Circle then
        FOV_Circle.Position = center
        FOV_Circle.Radius = FOV_RADIUS
    end

    -- Aimlock
    if AimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local ok, headPos, onScreen = pcall(function()
                return Camera:WorldToViewportPoint(head.Position)
            end)
            if ok and onScreen then
                pcall(function()
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
                end)
                if DrawingIsAvailable and LockLine then
                    LockLine.From = center
                    LockLine.To = Vector2.new(headPos.X,headPos.Y)
                    LockLine.Visible = true
                end
            else
                if DrawingIsAvailable and LockLine then LockLine.Visible = false end
            end
        else
            if DrawingIsAvailable and LockLine then LockLine.Visible = false end
        end
    else
        if DrawingIsAvailable and LockLine then LockLine.Visible = false end
    end
end)

Tab:Section(
    {
        Title = "Hitbox"
    }
)

_G.HeadSize = 10
_G.Disabled = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 🔁 ระบบขยาย Hitbox
RunService.RenderStepped:Connect(function()
    if not _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    local hrp = v.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                    hrp.Transparency = 0.9
                    hrp.BrickColor = BrickColor.new("Institutional white")
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                end)
            end
        end
    end
end)

-- ✅ ปุ่มเปิด/ปิด Hitbox
Tab:Toggle({
    Title = "Hitbox",
    Desc = "ขยายดาเมจ (เปิด/ปิดระบบ)",
    Value = false,
    Callback = function(v)
        _G.Disabled = not v
        print("Hitbox Enabled:", v)
    end
})

-- 🎚️ Slider ปรับขนาด Hitbox
local Slider = Tab:Slider({
    Title = "Hitbox Size",
    Desc = "",
    Step = 1,
    Value = {
        Min = 5,
        Max = 100,
        Default = 10,
    },
    Callback = function(value)
        _G.HeadSize = value
        print("HeadSize:", value)
    end
})

local Tab = Window:Tab({Title = "Main", Icon = "house"})

Tab:Section(
    {
        Title = "Main"
    }
)

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local RunService = game:GetService("RunService")
local invisOn = false

-- ฟังก์ชันล่องหนจาก Invis Ghost
local function setTransparency(char, val)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.Transparency = val
        end
    end
end

local function toggleInvis()
    invisOn = not invisOn
    local char = plr.Character
    if not char then return end

    if invisOn then
        setTransparency(char, 0.5)
        local savedpos = char.HumanoidRootPart.CFrame
        task.wait()
        char:MoveTo(Vector3.new(-25.95, 84, 3537.55))
        task.wait(0.15)
        local Seat = Instance.new("Seat", workspace)
        Seat.Anchored = false
        Seat.CanCollide = false
        Seat.Name = "invischair"
        Seat.Transparency = 1
        Seat.Position = Vector3.new(-25.95, 84, 3537.55)
        local Weld = Instance.new("Weld", Seat)
        Weld.Part0 = Seat
        Weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        Seat.CFrame = savedpos
        print("Invisibility Enabled")
    else
        setTransparency(char, 0)
        if workspace:FindFirstChild("invischair") then
            workspace.invischair:Destroy()
        end
        print("Invisibility Disabled")
    end
end

-- ใส่ใน Toggle ของ UI Library
Tab:Toggle({
    Title = "Invisibility (บางแมพอาจไม่ติด)",
    Desc = "",
    Value = false,
    Callback = function(v)
        -- ตรวจสอบว่าตัวละครโหลดแล้ว
        if not plr.Character then
            plr.CharacterAdded:Wait()
        end
        toggleInvis()
    end
})

getgenv().PullEnabled = false

-- ลูปดึงคน
local function PullPlayersLoop()
    while getgenv().PullEnabled do
        task.wait(0.1)

        local lp = game.Players.LocalPlayer
        local char = lp.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- เบื้องหน้าเรา
        local frontPos = hrp.CFrame * CFrame.new(0, 0, -5)

        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr ~= lp then
                local c = plr.Character
                if c then
                    local ohrp = c:FindFirstChild("HumanoidRootPart")
                    if ohrp then
                        -- วางไว้หน้าเรา 5 หน่วย
                        ohrp.CFrame = frontPos
                    end
                end
            end
        end
    end
end

-- Toggle
Tab:Toggle({
    Title = "Bring Players (บางแมพอาจไม่ติด)",
    Desc = "",
    Value = false,
    Callback = function(v)
        getgenv().PullEnabled = v
        print("Pull:", v)

        if v then
            task.spawn(PullPlayersLoop)
        end
    end
})

Tab:Section(
    {
        Title = "Misc Main"
    }
)

Tab:Toggle({
    Title = "FPS Boost",
    Desc = "",
    Value = false,
    Callback = function(v)
        if v then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end

            local Lighting = game:GetService("Lighting")
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
        else
            print("ปิด FPS Boost (รีเซ็ตเองหรือรีจอย)")
        end
    end
})

Tab:Toggle({
    Title = "Ultra Graphics",
    Desc = "",
    Value = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")

        if v then
            -- ลบของเก่า
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect")
                or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect")
                or v:IsA("DepthOfFieldEffect") then
                    v:Destroy()
                end
            end

            -- 🌌 SKY HD
            local sky = Instance.new("Sky")
            sky.Parent = Lighting
            sky.SkyboxBk = "rbxassetid://16573631102"
            sky.SkyboxDn = "rbxassetid://16573631950"
            sky.SkyboxFt = "rbxassetid://16573632795"
            sky.SkyboxLf = "rbxassetid://16573633258"
            sky.SkyboxRt = "rbxassetid://16573633908"
            sky.SkyboxUp = "rbxassetid://16573634370"

            -- ☀️ แสง
            Lighting.Brightness = 3
            Lighting.GlobalShadows = true
            Lighting.ClockTime = 14
            Lighting.OutdoorAmbient = Color3.fromRGB(170,170,170)
            Lighting.Ambient = Color3.fromRGB(120,120,120)

            -- 🌫️ Atmosphere
            local atmo = Instance.new("Atmosphere")
            atmo.Parent = Lighting
            atmo.Density = 0.3
            atmo.Offset = 0.25
            atmo.Color = Color3.fromRGB(199, 215, 255)
            atmo.Decay = Color3.fromRGB(106, 112, 125)
            atmo.Glare = 0.2
            atmo.Haze = 1

            -- ✨ Bloom
            local bloom = Instance.new("BloomEffect")
            bloom.Parent = Lighting
            bloom.Intensity = 0.6
            bloom.Size = 56
            bloom.Threshold = 1

            -- 🎨 Color Correction
            local color = Instance.new("ColorCorrectionEffect")
            color.Parent = Lighting
            color.Brightness = 0.05
            color.Contrast = 0.2
            color.Saturation = 0.25
            color.TintColor = Color3.fromRGB(255, 244, 214)

            -- ☀️ Sun Rays
            local sun = Instance.new("SunRaysEffect")
            sun.Parent = Lighting
            sun.Intensity = 0.2
            sun.Spread = 0.8

            -- 🎥 Depth of Field (เบลอฉากหลัง)
            local dof = Instance.new("DepthOfFieldEffect")
            dof.Parent = Lighting
            dof.FocusDistance = 100
            dof.InFocusRadius = 50
            dof.NearIntensity = 0.2
            dof.FarIntensity = 0.2

        else
            -- 🔄 รีเซ็ต
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect")
                or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect")
                or v:IsA("DepthOfFieldEffect") then
                    v:Destroy()
                end
            end

            Lighting.Brightness = 2
            Lighting.GlobalShadows = true
            Lighting.ClockTime = 12
            Lighting.Ambient = Color3.fromRGB(128,128,128)
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        end
    end
})

Tab:Toggle({
    Title = "No Fog",
    Desc = "",
    Value = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")

        if v then
            Lighting.FogStart = 0
            Lighting.FogEnd = 1e10

            for _, a in pairs(Lighting:GetChildren()) do
                if a:IsA("Atmosphere") then
                    a:Destroy()
                end
            end
        else
            Lighting.FogEnd = 1000
        end
    end
})

local connection

Tab:Toggle({
    Title = "Stretch Screen",
    Desc = "",
    Value = false,
    Callback = function(v)
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")

        if v then
            connection = RunService.RenderStepped:Connect(function()
                Camera.CFrame = Camera.CFrame * CFrame.new(
                    0,0,0,
                    1,0,0,
                    0,0.65,0,
                    0,0,1
                )
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

Tab:Section(
    {
        Title = "Teleport"
    }
)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local tpEnabled = false
local teamCheck = false
local connection

-- 🔍 หาเป้าหมายใกล้สุด
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
        and player.Character
        and player.Character:FindFirstChild("HumanoidRootPart") then
            
            -- ✅ เช็คทีม
            if teamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

-- 🚀 วาป + หันตัว + หันกล้อง
local function teleportBehind()
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            
            local targetHRP = target.Character.HumanoidRootPart

            -- วาปไปด้านหลัง
            local behindPosition = targetHRP.CFrame * CFrame.new(0, 0, 3)
            myChar.HumanoidRootPart.CFrame = behindPosition

            -- 🎯 หันตัวเราไปหาเป้าหมาย
            myChar.HumanoidRootPart.CFrame = CFrame.new(
                myChar.HumanoidRootPart.Position,
                targetHRP.Position
            )

            -- 🎥 หันกล้องไปหาเป้าหมาย
            Camera.CFrame = CFrame.new(
                Camera.CFrame.Position,
                targetHRP.Position
            )
        end
    end
end

-- 🎮 Toggle TP
Tab:Toggle({
    Title = "TP Player ( E )",
    Desc = "กด E เพื่อวาป",
    Value = false,
    Callback = function(v)
        tpEnabled = v
        print("TP:", v)

        if tpEnabled then
            connection = UIS.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.E then
                    teleportBehind()
                end
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- 🟢 Toggle Team Check
Tab:Toggle({
    Title = "Team Check",
    Desc = "ไม่วาปทีมเดียวกัน",
    Value = false,
    Callback = function(v)
        teamCheck = v
        print("Team Check:", v)
    end
})

local Tab = Window:Tab({Title = "Player", Icon = "user"})

Tab:Section(
    {
        Title = "Character"
    }
)

local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local normalSpeed = 16
local fastSpeed = 50 -- ปรับความเร็วได้

Tab:Toggle({
    Title = "Walk Speed",
    Desc = "",
    Value = false,
    Callback = function(v)
        local char = plr.Character or plr.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")

        if v then
            humanoid.WalkSpeed = fastSpeed
        else
            humanoid.WalkSpeed = normalSpeed
        end
    end
})

Tab:Toggle({
    Title = "TP Walk",
    Desc = "",
    Value = false,
    Callback = function(v)
        getgenv().TPWalkEnabled = v
        print("TP Walk:", v)

        if v then
            local Players = game:GetService("Players")
            local TweenService = game:GetService("TweenService")
            local LocalPlayer = Players.LocalPlayer
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HRP = Character:WaitForChild("HumanoidRootPart")
            local Humanoid = Character:WaitForChild("Humanoid")

            -- ลูปเฉพาะตอนเปิด
            task.spawn(function()
                while getgenv().TPWalkEnabled and task.wait() do
                    local dir = Humanoid.MoveDirection
                    if dir.Magnitude > 0 then
                        local newPos = HRP.Position + dir * 2.5
                        local tween = TweenService:Create(
                            HRP,
                            TweenInfo.new(0.05, Enum.EasingStyle.Linear),
                            {CFrame = CFrame.new(newPos, newPos + HRP.CFrame.LookVector)}
                        )
                        tween:Play()
                    end
                end
            end)
        end
    end
})

Tab:Toggle({
    Title = "Jump Boost",
    Desc = "",
    Value = false,
    Callback = function(state)
        getgenv().JumpBoostEnabled = state
        print("Jump Boost:", state)

        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local LocalPlayer = Players.LocalPlayer

        -- ลบของเก่า
        if getgenv().JumpBoostConnection then
            getgenv().JumpBoostConnection:Disconnect()
            getgenv().JumpBoostConnection = nil
        end
        if getgenv().JumpBoost_CharAdded then
            getgenv().JumpBoost_CharAdded:Disconnect()
            getgenv().JumpBoost_CharAdded = nil
        end

        -- ฟังก์ชันตั้งค่า Jump + Infinite Jump
        local function SetupJump(Character)
            if not getgenv().JumpBoostEnabled then return end
            local Humanoid = Character:WaitForChild("Humanoid")

            Humanoid.JumpPower = 24
            Humanoid.JumpHeight = 24

            -- Infinite Jump
            if getgenv().JumpBoostConnection then
                getgenv().JumpBoostConnection:Disconnect()
            end

            getgenv().JumpBoostConnection = UserInputService.InputBegan:Connect(function(input, g)
                if g then return end
                if input.KeyCode ~= Enum.KeyCode.Space then return end

                if getgenv().JumpBoostEnabled then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end

        -- ถ้าเปิดฟีเจอร์ → ทำงานทันที
        if state then
            local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            SetupJump(Char)

            -- ให้กลับมาทำงานเองเวลาเกิดใหม่
            getgenv().JumpBoost_CharAdded = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                if getgenv().JumpBoostEnabled then
                    SetupJump(newChar)
                end
            end)
        end
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local spinning = false
local spinSpeed = 10 -- ยิ่งมากยิ่งหมุนไว

Tab:Toggle({
    Title = "Spin Bot",
    Desc = "",
    Value = false,
    Callback = function(v)
        spinning = v

        if spinning then
            task.spawn(function()
                while spinning do
                    local char = plr.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                    end
                    RunService.RenderStepped:Wait()
                end
            end)
        end
    end
})

local UIS = game:GetService("UserInputService")
local infiniteJump = false

Tab:Toggle({
    Title = "Infinite Jump",
    Desc = "",
    Value = false,
    Callback = function(v)
        infiniteJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if infiniteJump then
        local char = game.Players.LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Button
    Tab:Button({
        Title = "Fly",
        Desc = "",
        Callback = function()
            loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\109\101\58\72\116\116\112\71\101\116\40\40\39\104\116\116\112\115\58\47\47\103\105\115\116\46\103\105\116\104\117\98\117\115\101\114\99\111\110\116\101\110\116\46\99\111\109\47\109\101\111\122\111\110\101\89\84\47\98\102\48\51\55\100\102\102\57\102\48\97\55\48\48\49\55\51\48\52\100\100\100\54\55\102\100\99\100\51\55\48\47\114\97\119\47\101\49\52\101\55\52\102\52\50\53\98\48\54\48\100\102\53\50\51\51\52\51\99\102\51\48\98\55\56\55\48\55\52\101\98\51\99\53\100\50\47\97\114\99\101\117\115\37\50\53\50\48\120\37\50\53\50\48\102\108\121\37\50\53\50\48\50\37\50\53\50\48\111\98\102\108\117\99\97\116\111\114\39\41\44\116\114\117\101\41\41\40\41\10\10")()
            Window:Notify({
                Title = "Button",
                Desc = "Action performed successfully.",
                Time = 3
            })
        end
    })

local Tab = Window:Tab({Title = "Esp", Icon = "eye"})

Tab:Section(
    {
        Title = "Esp Main"
    }
)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// SETTINGS
local ESP_ENABLED = false
local ESP_SETTINGS = {
    Box = false,
    Line = false,
    Fill = false,
    HealthBar = false,
    Names = false,
    Skeleton = false,
    JointDots = false,
    TeamCheck = false,
    Color = Color3.fromRGB(255, 255, 255),
    LinePosition = "Up"
}

--// SKELETON CONFIG (R15)
local SkeletonRig = {
    {"UpperTorso", "Head"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

--// STORAGE
local ESP_CONTAINER = {}

--// FUNCTIONS
-- ฟังก์ชันสำหรับซ่อน ESP ทั้งหมดของผู้เล่นคนนั้นๆ
local function ClearESP(esp)
    esp.Box.Visible = false
    esp.Fill.Visible = false
    esp.Line.Visible = false
    esp.HPBar.Visible = false
    esp.NameTag.Visible = false
    esp.HeadCircle.Visible = false
    for _, bone in pairs(esp.Bones) do bone.Visible = false end
    for _, dot in pairs(esp.Joints) do dot.Visible = false end
end

local function CreateESP(player)
    local esp = {
        Box = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        HPBar = Drawing.new("Square"),
        NameTag = Drawing.new("Text"),
        HeadCircle = Drawing.new("Circle"),
        Bones = {},
        Joints = {}
    }

    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Fill.Filled = true
    esp.Fill.Transparency = 0.3
    esp.Line.Thickness = 1
    esp.HPBar.Filled = true
    esp.NameTag.Size = 14
    esp.NameTag.Center = true
    esp.NameTag.Outline = true
    esp.NameTag.Color = Color3.new(1, 1, 1)
    esp.HeadCircle.Thickness = 1
    esp.HeadCircle.Filled = false

    for i = 1, #SkeletonRig do
        local line = Drawing.new("Line")
        line.Thickness = 1
        table.insert(esp.Bones, line)
        
        local dot = Drawing.new("Circle")
        dot.Radius = 2.5
        dot.Filled = true
        dot.Color = Color3.fromRGB(255, 0, 0)
        table.insert(esp.Joints, dot)
    end

    ESP_CONTAINER[player] = esp
end

local function RemoveESP(player)
    if ESP_CONTAINER[player] then
        for _, v in pairs(ESP_CONTAINER[player]) do
            if typeof(v) == "table" then
                for _, subV in pairs(v) do subV:Remove() end
            else
                v:Remove()
            end
        end
        ESP_CONTAINER[player] = nil
    end
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    for player, esp in pairs(ESP_CONTAINER) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        -- ตรวจสอบเงื่อนไขหลัก: เปิดใช้งาน, มีตัวละคร, ไม่ตาย
        if ESP_ENABLED and root and hum and hum.Health > 0 then
            -- Team Check
            if ESP_SETTINGS.TeamCheck and player.Team == LocalPlayer.Team then
                ClearESP(esp)
                continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            -- ตรวจสอบว่าอยู่ในหน้าจอหรือไม่
            if onScreen then
                local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 1.5

                -- Box & Fill
                esp.Box.Visible = ESP_SETTINGS.Box
                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                esp.Box.Color = ESP_SETTINGS.Color

                esp.Fill.Visible = ESP_SETTINGS.Fill
                esp.Fill.Size = esp.Box.Size
                esp.Fill.Position = esp.Box.Position
                esp.Fill.Color = ESP_SETTINGS.Color

                -- Line
                local fromY = (ESP_SETTINGS.LinePosition == "Up") and 0 or Camera.ViewportSize.Y
                esp.Line.Visible = ESP_SETTINGS.Line
                esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, fromY)
                esp.Line.To = Vector2.new(pos.X, pos.Y)
                esp.Line.Color = ESP_SETTINGS.Color

                -- Health Bar
                local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                esp.HPBar.Visible = ESP_SETTINGS.HealthBar
                esp.HPBar.Size = Vector2.new(2, height * hpPct)
                esp.HPBar.Position = Vector2.new(esp.Box.Position.X - 5, esp.Box.Position.Y + (height - height * hpPct))
                esp.HPBar.Color = Color3.fromRGB(255 * (1 - hpPct), 255 * hpPct, 0)

                -- Names
                esp.NameTag.Visible = ESP_SETTINGS.Names
                esp.NameTag.Text = player.Name .. " [" .. math.floor(hum.Health) .. "]"
                esp.NameTag.Position = Vector2.new(pos.X, esp.Box.Position.Y - 15)

                -- Skeleton
                if ESP_SETTINGS.Skeleton then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local hPos, hScreen = Camera:WorldToViewportPoint(head.Position)
                        esp.HeadCircle.Visible = hScreen
                        esp.HeadCircle.Radius = height / 10
                        esp.HeadCircle.Position = Vector2.new(hPos.X, hPos.Y)
                        esp.HeadCircle.Color = ESP_SETTINGS.Color
                    end

                    for i, rig in pairs(SkeletonRig) do
                        local p1, p2 = char:FindFirstChild(rig[1]), char:FindFirstChild(rig[2])
                        local line, dot = esp.Bones[i], esp.Joints[i]
                        if p1 and p2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            line.Visible = vis1 and vis2
                            line.From = Vector2.new(pos1.X, pos1.Y)
                            line.To = Vector2.new(pos2.X, pos2.Y)
                            line.Color = ESP_SETTINGS.Color
                            
                            dot.Visible = vis1 and ESP_SETTINGS.JointDots
                            dot.Position = Vector2.new(pos1.X, pos1.Y)
                        else
                            line.Visible = false
                            dot.Visible = false
                        end
                    end
                else
                    esp.HeadCircle.Visible = false
                    for _, b in pairs(esp.Bones) do b.Visible = false end
                    for _, j in pairs(esp.Joints) do j.Visible = false end
                end
            else
                -- กรณีไม่อยู่ในจอ ให้ล้าง ESP ออก
                ClearESP(esp)
            end
        else
            -- กรณีปิด ESP, ตัวละครหาย หรือตาย ให้ล้าง ESP ออก
            ClearESP(esp)
        end
    end
end)

--// INIT
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
Players.PlayerRemoving:Connect(RemoveESP)

---// UI SECTIONS //---

Tab:Toggle({
    Title = "Enabled Esp",
    Value = false,
    Callback = function(v) ESP_ENABLED = v end
})

Tab:Toggle({
    Title = "ESP Box",
    Value = false,
    Callback = function(v) ESP_SETTINGS.Box = v end
})

Tab:Toggle({
    Title = "ESP Skeleton",
    Value = false,
    Callback = function(v) ESP_SETTINGS.Skeleton = v end
})

Tab:Toggle({
    Title = "ESP Line",
    Value = false,
    Callback = function(v) ESP_SETTINGS.Line = v end
})

Tab:Toggle({
    Title = "ESP Health",
    Value = false,
    Callback = function(v) ESP_SETTINGS.HealthBar = v end
})

Tab:Toggle({
    Title = "ESP Names",
    Value = false,
    Callback = function(v) ESP_SETTINGS.Names = v end
})

Tab:Toggle({
    Title = "Team Check",
    Value = false,
    Callback = function(v) ESP_SETTINGS.TeamCheck = v end
})
