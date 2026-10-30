-- Mengamankan GUI
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("AutoFishHub") then
    CoreGui.AutoFishHub:Destroy()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local autoCatchActive = false

-- ==========================================
-- MEMBUAT TAMPILAN GUI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishHub"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 130)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Text = "🎣 God Auto Fish"
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

-- ==========================================
-- LOGIKA PEMBAJAKAN SINYAL (HOOKING)
-- ==========================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishGiver = FishingSystem:WaitForChild("FishGiver")
local CleanupCast = FishingSystem:WaitForChild("CleanupCast")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if not checkcaller() and method == "FireServer" then
        if self.Name == "MinigameStarted" and autoCatchActive then
            local args = {...}
            local tableData = args[1] -- Mengambil data koordinat asli dari game
            
            task.spawn(function()
                -- 1. Beri jeda 0.1 detik agar MinigameStarted terkirim lebih dulu
                task.wait(0.1)
                
                -- 2. Kirim sinyal CleanupCast (Mereset kail di server sesuai log)
                pcall(function() CleanupCast:FireServer() end)
                
                -- 3. Langsung kirim sinyal FishGiver menggunakan data asli dari game!
                pcall(function() FishGiver:FireServer(tableData) end)
                
                print("🐟 Ikan berhasil di-Bypass!")
                
                -- 4. Hancurkan layar minigame secara instan
                local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if PlayerGui then
                    for _, ui in pairs(PlayerGui:GetDescendants()) do
                        if ui:IsA("Frame") and string.find(string.lower(ui.Name), "eventframe") then
                            ui.Visible = false
                            ui:Destroy()
                        end
                    end
                end
                
                -- 5. Bebaskan karakter dari animasi memancing (Force Stop Animation)
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
            
            -- Biarkan sinyal MinigameStarted lolos ke server
            return oldNamecall(self, ...)
        end
    end
    
    return oldNamecall(self, ...)
end))

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

print("✅ God Auto Fish (Full Protocol) Siap!")
