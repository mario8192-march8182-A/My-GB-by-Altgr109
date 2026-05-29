-- CPU Z80 do Game Boy
-- Implementação do processador central

local CPU = {}
CPU.__index = CPU

function CPU.new()
    local self = setmetatable({}, CPU)
    
    -- Registradores (8 bits)
    self.a = 0    -- Acumulador
    self.b = 0
    self.c = 0
    self.d = 0
    self.e = 0
    self.h = 0
    self.l = 0
    
    -- Registrador de flags (F)
    self.f = 0
    self.z = 0   -- Zero flag
    self.n = 0   -- Subtract flag
    self.h_flag = 0 -- Half-carry flag
    self.c_flag = 0 -- Carry flag
    
    -- Registrador de programa e stack
    self.pc = 0x0100  -- Program counter (inicia em 0x100)
    self.sp = 0xFFFE  -- Stack pointer (inicia no topo da RAM)
    
    -- Clock interno
    self.m_cycles = 0
    self.t_cycles = 0
    
    -- Estado de interrupção
    self.halt = false
    self.stop = false
    self.ime = false  -- Interrupt Master Enable
    
    return self
end

function CPU:execute(memory)
    if self.halt then
        return 4  -- Continuar retornando ciclos enquanto em halt
    end
    
    local opcode = memory:read_byte(self.pc)
    local cycles = 4  -- Ciclos padrão
    
    -- Incrementar PC
    self.pc = (self.pc + 1) & 0xFFFF
    
    -- Decodificar e executar opcode
    cycles = self:execute_opcode(opcode, memory)
    
    self.m_cycles = self.m_cycles + (cycles / 4)
    self.t_cycles = self.t_cycles + cycles
    
    return cycles
end

function CPU:execute_opcode(opcode, memory)
    local cycles = 4
    
    -- NOP (0x00)
    if opcode == 0x00 then
        return 4
    end
    
    -- LD B, n (0x06)
    if opcode == 0x06 then
        self.b = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD C, n (0x0E)
    if opcode == 0x0E then
        self.c = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD D, n (0x16)
    if opcode == 0x16 then
        self.d = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD E, n (0x1E)
    if opcode == 0x1E then
        self.e = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD H, n (0x26)
    if opcode == 0x26 then
        self.h = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD L, n (0x2E)
    if opcode == 0x2E then
        self.l = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- LD A, n (0x3E)
    if opcode == 0x3E then
        self.a = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return 8
    end
    
    -- ADD A, B (0x80)
    if opcode == 0x80 then
        self:add_a(self.b)
        return 4
    end
    
    -- ADD A, C (0x81)
    if opcode == 0x81 then
        self:add_a(self.c)
        return 4
    end
    
    -- ADD A, D (0x82)
    if opcode == 0x82 then
        self:add_a(self.d)
        return 4
    end
    
    -- ADD A, E (0x83)
    if opcode == 0x83 then
        self:add_a(self.e)
        return 4
    end
    
    -- ADD A, H (0x84)
    if opcode == 0x84 then
        self:add_a(self.h)
        return 4
    end
    
    -- ADD A, L (0x85)
    if opcode == 0x85 then
        self:add_a(self.l)
        return 4
    end
    
    -- ADD A, A (0x87)
    if opcode == 0x87 then
        self:add_a(self.a)
        return 4
    end
    
    -- ADD A, n (0xC6)
    if opcode == 0xC6 then
        local n = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        self:add_a(n)
        return 8
    end
    
    -- SUB A, B (0x90)
    if opcode == 0x90 then
        self:sub_a(self.b)
        return 4
    end
    
    -- SUB A, n (0xD6)
    if opcode == 0xD6 then
        local n = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        self:sub_a(n)
        return 8
    end
    
    -- XOR A, B (0xA8)
    if opcode == 0xA8 then
        self:xor_a(self.b)
        return 4
    end
    
    -- JP nn (0xC3)
    if opcode == 0xC3 then
        local low = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        local high = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        self.pc = (high * 256 + low) & 0xFFFF
        return 16
    end
    
    -- JP Z, nn (0xCA)
    if opcode == 0xCA then
        local low = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        local high = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        if self.z == 1 then
            self.pc = (high * 256 + low) & 0xFFFF
            return 16
        end
        return 12
    end
    
    -- CALL nn (0xCD)
    if opcode == 0xCD then
        local low = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        local high = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        self:push_stack(memory, self.pc)
        self.pc = (high * 256 + low) & 0xFFFF
        return 24
    end
    
    -- RET (0xC9)
    if opcode == 0xC9 then
        self.pc = self:pop_stack(memory)
        return 16
    end
    
    -- HALT (0x76)
    if opcode == 0x76 then
        self.halt = true
        return 4
    end
    
    -- DI (0xF3) - Desabilitar interrupções
    if opcode == 0xF3 then
        self.ime = false
        return 4
    end
    
    -- EI (0xFB) - Habilitar interrupções
    if opcode == 0xFB then
        self.ime = true
        return 4
    end
    
    -- Opcode estendido (0xCB)
    if opcode == 0xCB then
        local next_opcode = memory:read_byte(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return self:execute_cb_opcode(next_opcode, memory)
    end
    
    -- Padrão: retornar 4 ciclos
    return 4
end

function CPU:execute_cb_opcode(opcode, memory)
    -- BIT 0, B (0x40)
    if opcode == 0x40 then
        self:bit(0, self.b)
        return 8
    end
    
    -- RLC B (0x00)
    if opcode == 0x00 then
        self.b = self:rlc(self.b)
        return 8
    end
    
    return 8
end

function CPU:add_a(value)
    local result = self.a + value
    self.h_flag = ((self.a & 0x0F) + (value & 0x0F)) > 0x0F and 1 or 0
    self.c_flag = result > 0xFF and 1 or 0
    self.a = result & 0xFF
    self.z = self.a == 0 and 1 or 0
    self.n = 0
end

function CPU:sub_a(value)
    local result = self.a - value
    self.h_flag = ((self.a & 0x0F) - (value & 0x0F)) < 0 and 1 or 0
    self.c_flag = result < 0 and 1 or 0
    self.a = result & 0xFF
    self.z = self.a == 0 and 1 or 0
    self.n = 1
end

function CPU:xor_a(value)
    self.a = (self.a ~ value) & 0xFF
    self.z = self.a == 0 and 1 or 0
    self.n = 0
    self.h_flag = 0
    self.c_flag = 0
end

function CPU:bit(bit_pos, value)
    local result = (value >> bit_pos) & 1
    self.z = result == 0 and 1 or 0
    self.n = 0
    self.h_flag = 1
end

function CPU:rlc(value)
    local carry = (value >> 7) & 1
    local result = ((value << 1) | carry) & 0xFF
    self.c_flag = carry
    self.z = result == 0 and 1 or 0
    self.n = 0
    self.h_flag = 0
    return result
end

function CPU:push_stack(memory, value)
    self.sp = (self.sp - 1) & 0xFFFF
    memory:write_byte(self.sp, (value >> 8) & 0xFF)
    self.sp = (self.sp - 1) & 0xFFFF
    memory:write_byte(self.sp, value & 0xFF)
end

function CPU:pop_stack(memory)
    local low = memory:read_byte(self.sp)
    self.sp = (self.sp + 1) & 0xFFFF
    local high = memory:read_byte(self.sp)
    self.sp = (self.sp + 1) & 0xFFFF
    return (high << 8) | low
end

function CPU:get_flags()
    return (self.z << 7) | (self.n << 6) | (self.h_flag << 5) | (self.c_flag << 4)
end

function CPU:set_flags(value)
    self.z = (value >> 7) & 1
    self.n = (value >> 6) & 1
    self.h_flag = (value >> 5) & 1
    self.c_flag = (value >> 4) & 1
end

return CPU
