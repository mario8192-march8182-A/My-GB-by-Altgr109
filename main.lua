-- Emulador de Game Boy em Lua
-- Arquivo principal

require("src.cpu")
require("src.memory")
require("src.gpu")
require("src.input")
require("src.cartridge")
require("src.timer")
require("src.apu")

local GameBoy = {}
GameBoy.__index = GameBoy

function GameBoy.new()
    local self = setmetatable({}, GameBoy)
    
    self.cpu = CPU.new()
    self.memory = Memory.new()
    self.gpu = GPU.new()
    self.input = Input.new()
    self.cartridge = nil
    self.timer = Timer.new()
    self.apu = APU.new()
    
    self.running = false
    self.fps = 60
    self.frame_time = 1 / self.fps
    self.cycle_count = 0
    
    return self
end

function GameBoy:load_cartridge(rom_path)
    self.cartridge = Cartridge.new(rom_path)
    self.memory:set_cartridge(self.cartridge)
    print("Cartucho carregado: " .. rom_path)
end

function GameBoy:update(dt)
    if not self.running then return end
    
    self.cycle_count = self.cycle_count + dt * 4194304  -- Frequência de clock do GB
    
    -- Executar ciclos de CPU
    while self.cycle_count > 0 do
        local cycles = self.cpu:execute(self.memory)
        self.cycle_count = self.cycle_count - cycles
        
        -- Atualizar timer
        self.timer:update(cycles, self.memory)
        
        -- Atualizar GPU
        self.gpu:update(cycles, self.memory)
        
        -- Atualizar APU (áudio)
        self.apu:update(cycles, self.memory)
        
        -- Atualizar input
        self.input:update(self.memory)
        
        -- Verificar interrupções
        self:handle_interrupts()
    end
end

function GameBoy:draw()
    if self.running then
        self.gpu:draw()
    end
end

function GameBoy:handle_interrupts()
    local interrupt_flags = self.memory:read_byte(0xFF0F)
    local interrupt_enable = self.memory:read_byte(0xFFFF)
    
    if self.cpu.ime and (interrupt_flags & interrupt_enable) ~= 0 then
        self.cpu.halt = false
        
        if (interrupt_flags & 0x01) ~= 0 and (interrupt_enable & 0x01) ~= 0 then
            -- Interrupção V-Blank
            self:interrupt_vblank()
        elseif (interrupt_flags & 0x02) ~= 0 and (interrupt_enable & 0x02) ~= 0 then
            -- Interrupção LCD STAT
            self:interrupt_stat()
        elseif (interrupt_flags & 0x04) ~= 0 and (interrupt_enable & 0x04) ~= 0 then
            -- Interrupção Timer
            self:interrupt_timer()
        elseif (interrupt_flags & 0x08) ~= 0 and (interrupt_enable & 0x08) ~= 0 then
            -- Interrupção Serial
            self:interrupt_serial()
        elseif (interrupt_flags & 0x10) ~= 0 and (interrupt_enable & 0x10) ~= 0 then
            -- Interrupção Joypad
            self:interrupt_joypad()
        end
    end
end

function GameBoy:interrupt_vblank()
    self.memory:write_byte(0xFF0F, self.memory:read_byte(0xFF0F) & 0xFE)
    self.cpu:push_stack(self.memory, self.cpu.pc)
    self.cpu.pc = 0x40
    self.cpu.ime = false
end

function GameBoy:interrupt_stat()
    self.memory:write_byte(0xFF0F, self.memory:read_byte(0xFF0F) & 0xFD)
    self.cpu:push_stack(self.memory, self.cpu.pc)
    self.cpu.pc = 0x48
    self.cpu.ime = false
end

function GameBoy:interrupt_timer()
    self.memory:write_byte(0xFF0F, self.memory:read_byte(0xFF0F) & 0xFB)
    self.cpu:push_stack(self.memory, self.cpu.pc)
    self.cpu.pc = 0x50
    self.cpu.ime = false
end

function GameBoy:interrupt_serial()
    self.memory:write_byte(0xFF0F, self.memory:read_byte(0xFF0F) & 0xF7)
    self.cpu:push_stack(self.memory, self.cpu.pc)
    self.cpu.pc = 0x58
    self.cpu.ime = false
end

function GameBoy:interrupt_joypad()
    self.memory:write_byte(0xFF0F, self.memory:read_byte(0xFF0F) & 0xEF)
    self.cpu:push_stack(self.memory, self.cpu.pc)
    self.cpu.pc = 0x60
    self.cpu.ime = false
end

function GameBoy:start()
    self.running = true
    print("Emulador iniciado!")
end

function GameBoy:pause()
    self.running = not self.running
end

function GameBoy:reset()
    self.cpu = CPU.new()
    self.memory = Memory.new()
    self.gpu = GPU.new()
    self.timer = Timer.new()
    self.apu = APU.new()
    if self.cartridge then
        self.memory:set_cartridge(self.cartridge)
    end
    print("Emulador resetado!")
end

-- Exports
return GameBoy
