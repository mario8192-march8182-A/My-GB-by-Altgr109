-- Sistema de Memória do Game Boy
-- Mapa de memória: 0x0000-0xFFFF (64KB)

local Memory = {}
Memory.__index = Memory

function Memory.new()
    local self = setmetatable({}, Memory)
    
    -- Memória RAM (0x0000-0xFFFF)
    self.ram = {}
    for i = 0, 0xFFFF do
        self.ram[i] = 0
    end
    
    -- Cartucho
    self.cartridge = nil
    
    -- Mapa de memória do Game Boy:
    -- 0x0000-0x00FF: Vetor de boot ROM (se habilitado)
    -- 0x0100-0x014F: Cabeçalho do cartucho
    -- 0x0150-0x7FFF: ROM do cartucho (banco 0 fixo)
    -- 0x8000-0x9FFF: VRAM (Memória de vídeo)
    -- 0xA000-0xBFFF: RAM externa do cartucho
    -- 0xC000-0xDFFF: RAM interna (8KB)
    -- 0xE000-0xFDFF: Echo da RAM interna
    -- 0xFE00-0xFEFF: OAM (Sprite Attribute Table)
    -- 0xFF00-0xFF4B: Registradores I/O
    -- 0xFF4C-0xFFFE: HRAM (High RAM)
    -- 0xFFFF: Registrador de interrupção
    
    return self
end

function Memory:set_cartridge(cartridge)
    self.cartridge = cartridge
end

function Memory:read_byte(address)
    address = address & 0xFFFF
    
    -- ROM do cartucho (0x0000-0x7FFF)
    if address < 0x8000 then
        if self.cartridge then
            return self.cartridge:read_byte(address)
        else
            return self.ram[address] or 0
        end
    end
    
    -- VRAM (0x8000-0x9FFF)
    if address < 0xA000 then
        return self.ram[address] or 0
    end
    
    -- RAM externa do cartucho (0xA000-0xBFFF)
    if address < 0xC000 then
        if self.cartridge then
            return self.cartridge:read_external_ram(address - 0xA000)
        else
            return self.ram[address] or 0
        end
    end
    
    -- RAM interna (0xC000-0xDFFF)
    if address < 0xE000 then
        return self.ram[address] or 0
    end
    
    -- Echo da RAM interna (0xE000-0xFDFF)
    if address < 0xFE00 then
        return self.ram[address - 0x2000] or 0
    end
    
    -- OAM (0xFE00-0xFEFF)
    if address < 0xFF00 then
        return self.ram[address] or 0
    end
    
    -- Registradores I/O (0xFF00-0xFF4B)
    if address == 0xFF00 then
        -- Joypad
        return self.ram[address] or 0
    elseif address == 0xFF01 then
        -- Serial transfer data
        return self.ram[address] or 0
    elseif address == 0xFF02 then
        -- Serial transfer control
        return self.ram[address] or 0
    elseif address >= 0xFF04 and address <= 0xFF07 then
        -- Timer
        return self.ram[address] or 0
    elseif address == 0xFF0F then
        -- Interrupt flags
        return self.ram[address] or 0
    elseif address >= 0xFF10 and address <= 0xFF3F then
        -- Áudio
        return self.ram[address] or 0
    elseif address >= 0xFF40 and address <= 0xFF4B then
        -- GPU
        return self.ram[address] or 0
    end
    
    -- HRAM (0xFF80-0xFFFE)
    if address >= 0xFF80 and address <= 0xFFFE then
        return self.ram[address] or 0
    end
    
    -- Registrador de interrupção (0xFFFF)
    if address == 0xFFFF then
        return self.ram[address] or 0
    end
    
    return self.ram[address] or 0
end

function Memory:write_byte(address, value)
    address = address & 0xFFFF
    value = value & 0xFF
    
    -- ROM do cartucho (0x0000-0x7FFF) - Somente leitura, mas pode acionar banco switching
    if address < 0x8000 then
        if self.cartridge then
            self.cartridge:handle_banking(address, value)
        end
        return
    end
    
    -- VRAM (0x8000-0x9FFF)
    if address < 0xA000 then
        self.ram[address] = value
        return
    end
    
    -- RAM externa do cartucho (0xA000-0xBFFF)
    if address < 0xC000 then
        if self.cartridge then
            self.cartridge:write_external_ram(address - 0xA000, value)
        end
        return
    end
    
    -- RAM interna (0xC000-0xDFFF)
    if address < 0xE000 then
        self.ram[address] = value
        -- Atualizar echo também
        self.ram[address + 0x2000] = value
        return
    end
    
    -- Echo da RAM interna (0xE000-0xFDFF)
    if address < 0xFE00 then
        self.ram[address] = value
        -- Atualizar RAM interna também
        self.ram[address - 0x2000] = value
        return
    end
    
    -- OAM (0xFE00-0xFEFF)
    if address < 0xFF00 then
        self.ram[address] = value
        return
    end
    
    -- Registradores I/O (0xFF00-0xFF4B)
    if address == 0xFF00 then
        -- Joypad
        self.ram[address] = value
        return
    elseif address == 0xFF01 then
        -- Serial transfer data
        self.ram[address] = value
        return
    elseif address == 0xFF02 then
        -- Serial transfer control
        self.ram[address] = value
        return
    elseif address >= 0xFF04 and address <= 0xFF07 then
        -- Timer
        self.ram[address] = value
        return
    elseif address == 0xFF0F then
        -- Interrupt flags
        self.ram[address] = value
        return
    elseif address >= 0xFF10 and address <= 0xFF3F then
        -- Áudio
        self.ram[address] = value
        return
    elseif address >= 0xFF40 and address <= 0xFF4B then
        -- GPU
        self.ram[address] = value
        return
    end
    
    -- HRAM (0xFF80-0xFFFE)
    if address >= 0xFF80 and address <= 0xFFFE then
        self.ram[address] = value
        return
    end
    
    -- Registrador de interrupção (0xFFFF)
    if address == 0xFFFF then
        self.ram[address] = value
        return
    end
    
    self.ram[address] = value
end

function Memory:read_word(address)
    local low = self:read_byte(address)
    local high = self:read_byte((address + 1) & 0xFFFF)
    return (high << 8) | low
end

function Memory:write_word(address, value)
    self:write_byte(address, value & 0xFF)
    self:write_byte((address + 1) & 0xFFFF, (value >> 8) & 0xFF)
end

return Memory
