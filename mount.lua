-- Mengamankan GUI
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("AutoFishHub") then
    CoreGui.AutoFishHub:Destroy()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser") 

local autoCatchActive = false
local autoSellActive = false

-- ==========================================
-- PENGATURAN FILTER IKAN YANG DIJUAL
-- ==========================================
local raritiesToSell = {
    ["Common"] = true,
    ["Uncommon"] = true,
    ["Rare"] = true,
    ["Epic"] = true
}

-- ==========================================
-- MEMBUAT TAMPILAN GUI KHUSUS HP
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishHub"
ScreenGui.Parent = CoreGui

-- Tombol Kecil untuk Membuka Menu (Awalnya Sembunyi)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -20)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.BorderSizePixel = 2
OpenBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
OpenBtn.TextSize = 22
OpenBtn.Text = "🎣"
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui

-- Bingkai Menu Utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 190)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Tombol Tutup (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Text = "X"
CloseBtn.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Text = "🎣 God Hub + Smart Sell"
Title.Parent = MainFrame

local AutoCatchBtn = Instance.new("TextButton")
AutoCatchBtn.Size = UDim2.new(0.8, 0, 0, 50)
AutoCatchBtn.Position = UDim2.new(0.1, 0, 0, 60)
AutoCatchBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AutoCatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoCatchBtn.Font = Enum.Font.GothamSemibold
AutoCatchBtn.TextSize = 14
AutoCatchBtn.Text = "God Auto Catch: OFF"
AutoCatchBtn.Parent = MainFrame

local AutoSellBtn = Instance.new("TextButton")
AutoSellBtn.Size = UDim2.new(0.8, 0, 0, 50)
AutoSellBtn.Position = UDim2.new(0.1, 0, 0, 120)
AutoSellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AutoSellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSellBtn.Font = Enum.Font.GothamSemibold
AutoSellBtn.TextSize = 14
AutoSellBtn.Text = "Smart Sell: OFF"
AutoSellBtn.Parent = MainFrame

-- ==========================================
-- LOGIKA SEMBUNYIKAN GUI
-- ==========================================
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- ==========================================
-- LOGIKA ANTI-AFK 
-- ==========================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

-- ==========================================
-- LOGIKA PEMBAJAKAN SINYAL AUTO CATCH
-- ==========================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 5)
local FishGiver = FishingSystem and FishingSystem:WaitForChild("FishGiver", 5)
local CleanupCast = FishingSystem and FishingSystem:WaitForChild("CleanupCast", 5)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if not checkcaller() and method == "FireServer" then
        if self.Name == "MinigameStarted" and autoCatchActive then
            local args = {...}
            local tableData = args[1]
            
            task.spawn(function()
                task.wait(0.1)
                
                if CleanupCast then pcall(function() CleanupCast:FireServer() end) end
                if FishGiver then pcall(function() FishGiver:FireServer(tableData) end) end
                
                local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if PlayerGui then
                    for _, ui in pairs(PlayerGui:GetDescendants()) do
                        if ui:IsA("Frame") and string.find(string.lower(ui.Name), "eventframe") then
                            ui.Visible = false
                            ui:Destroy()
                        end
                    end
                end
                
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    for _, anim in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if string.find(string.lower(anim.Animation.AnimationId), "fish") or string.find(string.lower(anim.Animation.AnimationId), "cast") then
                            anim:Stop()
                        end
                    end
                end
            end)
            
            return oldNamecall(self, ...)
        end
    end
    
    return oldNamecall(self, ...)
end))

-- ==========================================
-- LOGIKA SMART AUTO SELL (FILTER)
-- ==========================================
local FishCaughtResult = FishingSystem and FishingSystem:WaitForChild("FishCaughtResult", 5)
local SellFish = FishingSystem and FishingSystem:WaitForChild("SellFish", 5)

if FishCaughtResult and SellFish then
    FishCaughtResult.OnClientEvent:Connect(function(data)
        if autoSellActive and type(data) == "table" then
            
            local rarity = data.rarity
            local weight = data.weight
            local fishId = data.uniqueId
            
            if rarity and raritiesToSell[rarity] then
                task.spawn(function()
                    task.wait(1.5)
                    pcall(function()
                        SellFish:FireServer("SellSingle", {
                            ["weight"] = weight,
                            ["rarity"] = rarity,
                            ["fishId"] = fishId
                        })
                    end)
                end)
            end
        end
    end)
end

-- ==========================================
-- LOGIKA TOMBOL 
-- ==========================================
AutoCatchBtn.MouseButton1Click:Connect(function()
    autoCatchActive = not autoCatchActive
    if autoCatchActive then
        AutoCatchBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        AutoCatchBtn.Text = "God Auto Catch: ON"
    else
        AutoCatchBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AutoCatchBtn.Text = "God Auto Catch: OFF"
    end
end)

AutoSellBtn.MouseButton1Click:Connect(function()
    autoSellActive = not autoSellActive
    if autoSellActive then
        AutoSellBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        AutoSellBtn.Text = "Smart Sell: ON"
    else
        AutoSellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AutoSellBtn.Text = "Smart Sell: OFF"
    end
end)
