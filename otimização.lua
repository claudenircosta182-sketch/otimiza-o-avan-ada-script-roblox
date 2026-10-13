-- ==========================================
-- SCRIPT DE OTIMIZACAO AVANCADA (ANTI-LAG V1)
-- ==========================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Determinar armazenamento seguro e compatível com Delta Mobile
local TargetGui = nil
pcall(function()
    if CoreGui then TargetGui = CoreGui end
end)
if not TargetGui then
    TargetGui = LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- Limpar execuções duplicadas anteriores
if TargetGui:FindFirstChild("OtimizacaoAvancadaGui") then
    TargetGui.OtimizacaoAvancadaGui:Destroy()
end

-- Notificação estilizada no chat nativo
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "[SISTEMA]: Otimização Avançada Carregada! Clique em UPD.";
    Color = Color3.fromRGB(0, 180, 255);
    Font = Enum.Font.SourceSansBold;
    Size = 15;
})

-- Variáveis de controle de estado contínuo (ON/OFF)
local menuAberto = false
local texturasDesativadas = false
local graficoMassinhaAtivo = false
local otimizadorAtivo = false

-- Tabelas na memória para armazenar o estado original e reverter perfeitamente
local texturasOriginais = {}
local materiaisOriginais = {}
local conexaoOtimizador = nil

-- [[ 1. CONFIGURAÇÃO DA INTERFACE VISUAL (GRADIENTE AZUL E PRETO) ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OtimizacaoAvancadaGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

-- Janela Flutuante "UPD"
local BotaoUPD = Instance.new("TextButton")
BotaoUPD.Name = "BotaoUPD"
BotaoUPD.Size = UDim2.new(0, 55, 0, 55)
BotaoUPD.Position = UDim2.new(0.05, 0, 0.25, 0)
BotaoUPD.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BotaoUPD.Text = "UPD"
BotaoUPD.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoUPD.Font = Enum.Font.SourceSansBold
BotaoUPD.TextSize = 18
BotaoUPD.Active = true
BotaoUPD.Draggable = true
BotaoUPD.Parent = ScreenGui

local UICornerUPD = Instance.new("UICorner")
UICornerUPD.CornerRadius = UDim.new(0, 12)
UICornerUPD.Parent = BotaoUPD

local GradienteUPD = Instance.new("UIGradient")
GradienteUPD.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)), -- Azul Neon
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))       -- Preto Absoluto
})
GradienteUPD.Rotation = 45
GradienteUPD.Parent = BotaoUPD

-- Menu Principal
local FrameMenu = Instance.new("Frame")
FrameMenu.Name = "JanelaPrincipal"
FrameMenu.Size = UDim2.new(0, 210, 0, 360)
FrameMenu.Position = UDim2.new(0.3, 0, 0.25, 0)
FrameMenu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FrameMenu.Visible = false
FrameMenu.Active = true
FrameMenu.Draggable = true
FrameMenu.Parent = ScreenGui

local UICornerMenu = Instance.new("UICorner")
UICornerMenu.CornerRadius = UDim.new(0, 14)
UICornerMenu.Parent = FrameMenu

local StrokeMenu = Instance.new("UIStroke")
StrokeMenu.Color = Color3.fromRGB(0, 120, 255)
StrokeMenu.Thickness = 1.5
StrokeMenu.Parent = FrameMenu

local GradienteMenu = Instance.new("UIGradient")
GradienteMenu.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 50, 150)), -- Azul Escuro
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 5))      -- Preto
})
GradienteMenu.Rotation = 90
GradienteMenu.Parent = FrameMenu

-- Título Interno
local LabelTitulo = Instance.new("TextLabel")
LabelTitulo.Size = UDim2.new(1, 0, 0, 40)
LabelTitulo.BackgroundTransparency = 1
LabelTitulo.Text = "OTIMIZAÇÃO AVANÇADA"
LabelTitulo.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelTitulo.Font = Enum.Font.SourceSansBold
LabelTitulo.TextSize = 14
LabelTitulo.Parent = FrameMenu

-- [[ 2. CONTAGEM FIXA DE FPS (MONITORAMENTO EM TEMPO REAL) ]] --
local LabelFPS = Instance.new("TextLabel")
LabelFPS.Size = UDim2.new(1, -24, 0, 32)
LabelFPS.Position = UDim2.new(0, 12, 0, 40)
LabelFPS.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LabelFPS.BackgroundTransparency = 0.5
LabelFPS.Font = Enum.Font.SourceSansSemibold
LabelFPS.TextSize = 14
LabelFPS.TextColor3 = Color3.fromRGB(0, 255, 150)
LabelFPS.Text = "FPS: Calculando..."
LabelFPS.Parent = FrameMenu

local UICornerFPS = Instance.new("UICorner")
UICornerFPS.CornerRadius = UDim.new(0, 6)
UICornerFPS.Parent = LabelFPS

task.spawn(function()
    local tempoAntigo = os.clock()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local tempoAtual = os.clock()
        if tempoAtual - tempoAntigo >= 1 then
            LabelFPS.Text = "FPS Atual: " .. frames
            if frames >= 50 then
                LabelFPS.TextColor3 = Color3.fromRGB(0, 255, 150) -- Verde (Excelente)
            elseif frames >= 30 then
                LabelFPS.TextColor3 = Color3.fromRGB(255, 165, 0) -- Laranja (Médio)
            else
                LabelFPS.TextColor3 = Color3.fromRGB(255, 60, 60)   -- Vermelho (Gargalo)
            end
            frames = 0
            tempoAntigo = tempoAtual
        end
    end)
end)

-- Painel de Rolagem dos Botões
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -16, 1, -90)
ScrollContainer.Position = UDim2.new(0, 8, 0, 82)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 240)
ScrollContainer.ScrollBarThickness = 3
ScrollContainer.Parent = FrameMenu

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ScrollContainer

-- Criador Genérico de Botões Dinâmicos
local function criarBotao(texto, ordem, callback)
    local Botao = Instance.new("TextButton")
    Botao.Size = UDim2.new(1, -4, 0, 42)
    Botao.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Botao.Text = texto
    Botao.TextColor3 = Color3.fromRGB(220, 220, 220)
    Botao.Font = Enum.Font.SourceSansBold
    Botao.TextSize = 13
    Botao.LayoutOrder = ordem
    Botao.Parent = ScrollContainer
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 7)
    Corner.Parent = Botao
    
    local StrokeBtn = Instance.new("UIStroke")
    StrokeBtn.Color = Color3.fromRGB(45, 45, 45)
    StrokeBtn.Thickness = 1
    StrokeBtn.Parent = Botao
    
    Botao.MouseButton1Click:Connect(callback)
    return Botao
end

-- Lógica contínua de Abrir/Fechar com o UPD
BotaoUPD.MouseButton1Click:Connect(function()
    menuAberto = not menuAberto
    FrameMenu.Visible = menuAberto
end)


-- [[ 3. LOGICA DA FUNÇÃO: DESATIVAR TEXTURAS (COM REVERSÃO PERFEITA) ]] --
local BotaoTexturas = criarBotao("Desativar Texturas: OFF", 1, function() end)
BotaoTexturas.BackgroundColor3 = Color3.fromRGB(60, 20, 20)

local function alternarTexturas()
    texturasDesativadas = not texturasDesativadas
    if texturasDesativadas then
        BotaoTexturas.Text = "Desativar Texturas: LIGADO"
        BotaoTexturas.BackgroundColor3 = Color3.fromRGB(20, 70, 20)
        
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("Sky") then
                texturasOriginais[obj] = obj.Parent
                obj.Parent = nil
            end
        end
    else
        BotaoTexturas.Text = "Desativar Texturas: OFF"
        BotaoTexturas.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        
        for obj, pai in pairs(texturasOriginais) do
            if obj and pai then
                pcall(function() obj.Parent = pai end)
            end
        end
        texturasOriginais = {}
    end
end
BotaoTexturas.MouseButton1Click:Connect(alternarTexturas)


-- [[ 4. LOGICA DA FUNÇÃO: GRÁFICO MASSINHA (ESTILO FREE FIRE COM REVERSÃO) ]] --
local BotaoMassinha = criarBotao("Gráfico Massinha: OFF", 2, function() end)
BotaoMassinha.BackgroundColor3 = Color3.fromRGB(60, 20, 20)

local function alternarMassinha()
    graficoMassinhaAtivo = not graficoMassinhaAtivo
    if graficoMassinhaAtivo then
        BotaoMassinha.Text = "Gráfico Massinha: LIGADO"
        BotaoMassinha.BackgroundColor3 = Color3.fromRGB(20, 70, 20)
        
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("MeshPart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                materiaisOriginais[obj] = obj.Material
                obj.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        BotaoMassinha.Text = "Gráfico Massinha: OFF"
        BotaoMassinha.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        
        for obj, material in pairs(materiaisOriginais) do
            if obj and material then
                pcall(function() obj.Material = material end)
            end
        end
        materiaisOriginais = {}
    end
end
BotaoMassinha.MouseButton1Click:Connect(alternarMassinha)


-- [[ 5. LOGICA DA FUNÇÃO: OTIMIZADOR DE FPS (MEMÓRIA, INTERNET E LAG COLETIVO) ]] --
local BotaoOtimizar = criarBotao("Otimizador de FPS: OFF", 3, function() end)
BotaoOtimizar.BackgroundColor3 = Color3.fromRGB(60, 20, 20)

local function limparElementosPesados(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        obj.Enabled = false
    elseif obj:IsA("Explosion") then
        obj.Visible = false
    end
end

local function alternarOtimizador()
    otimizadorAtivo = not otimizadorAtivo
    if otimizadorAtivo then
        BotaoOtimizar.Text = "Otimizador de FPS: LIGADO"
        BotaoOtimizar.BackgroundColor3 = Color3.fromRGB(20, 70, 20)
        
        -- Alívio do processamento de rede e ping (Limita simulação física desnecessária fora do foco)
        settings().Network.IncomingReplicationLag = 0
        
        -- Desativação global de sombras pesadas dinâmicas e névoa renderizada
    
