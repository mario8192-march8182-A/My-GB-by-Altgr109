local gpu = {}

-- Registradores e buffers
gpu.LCDC = 0x91
gpu.STAT = 0x85
gpu.SCY = 0
gpu.SCX = 0
gpu.LY = 0
gpu.LYC = 0
gpu.BGP = 0xFC
gpu.OBP0 = 0xFF
gpu.OBP1 = 0xFF
gpu.WY = 0
gpu.WX = 0

gpu.vram = {}
gpu.oam = {}
gpu.framebuffer = {}

-- Inicializa framebuffer
for y = 0, 143 do
    gpu.framebuffer[y] = {}
    for x = 0, 159 do
        gpu.framebuffer[y][x] = 0
    end
end

-- Avança GPU conforme ciclos
function gpu.step(cycles)
    -- Atualiza LY, modos e dispara interrupções
    gpu.LY = (gpu.LY + 1) % 154
    if gpu.LY < 144 then
        gpu:renderScanline()
    else
        -- VBlank
    end
end

-- Renderiza uma linha
function gpu:renderScanline()
    self:drawBackground()
    self:drawWindow()
    self:drawSprites()
end

function gpu:drawBackground()
    -- lógica para tiles do background
end

function gpu:drawWindow()
    -- lógica para janela
end

function gpu:drawSprites()
    -- lógica para sprites
end

return gpu
