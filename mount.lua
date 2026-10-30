-- Mengamankan GUI
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("AutoFishHub") then
    CoreGui.AutoFishHub:Destroy()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local autoCatchActive = false
local autoSellActive = false

-- ==========================================
-- PENGATURAN FILTER IKAN YANG DIJUAL
-- ==========================================
-- Ikan dengan rarity di bawah ini AKAN DIJUAL OTOMATIS.
-- Jika Anda dapat Legendary, Mythical, dll, ikan TIDAK AKAN dijual.
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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 190)
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
-- LOGIKA 1: PEMBAJAKAN SINYAL AUTO CATCH
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
                
                -- Kirim sinyal sesuai urutan log server agar legal
                if CleanupCast then pcall(function() CleanupCast:FireServer() end) end
                if FishGiver then pcall(function() FishGiver:FireServer(tableData) end) end
                
                -- Hancurkan UI minigame secara instan
                local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if PlayerGui then
                    for _, ui in pairs(PlayerGui:GetDescendants()) do
                        if ui:IsA("Frame") and string.find(string.lower(ui.Name), "eventframe") then
                            ui.Visible = false
                            ui:Destroy()
                        end
                    end
                end
                
                -- Paksa berhenti animasi memancing
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
-- LOGIKA 2: SMART AUTO SELL (FILTER)
-- ==========================================
local FishCaughtResult = FishingSystem and FishingSystem:WaitForChild("FishCaughtResult", 5)
local SellFish = FishingSystem and FishingSystem:WaitForChild("SellFish", 5)

if FishCaughtResult and SellFish then
    -- Memasang radar: Mencegat setiap ikan yang baru saja masuk ke tas
    FishCaughtResult.OnClientEvent:Connect(function(data)
        if autoSellActive and type(data) == "table" then
            
            local rarity = data.rarity
            local weight = data.weight
            local fishId = data.uniqueId
            local name = data.name
            
            -- Mengecek apakah kelangkaan ikan tersebut ada di daftar jual (Common/Uncommon/Rare/Epic)
            if rarity and raritiesToSell[rarity] then
                task.spawn(function()
                    task.wait(1.5) -- Jeda aman 1.5 detik membiarkan ikan masuk tas dulu
                    
                    pcall(function()
                        -- Mengeksekusi transaksi rahasia SellSingle!
                        SellFish:FireServer("SellSingle", {
                            ["weight"] = weight,
                            ["rarity"] = rarity,
                            ["fishId"] = fishId
                        })
                    end)
                end)
            else
                -- Jika ikannya langka (Legendary dll), abaikan dan simpan!
                print("🌟 IKAN SPESIAL DISIMPAN: " .. tostring(name) .. " (" .. tostring(rarity) .. ")")
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

print("✅ Fitur God Auto Catch & Smart Sell Siap Digunakan!")
