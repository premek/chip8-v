type Instr = u16

fn (i Instr) lo() u8 {
	return u8(i)
}

fn (i Instr) hi() u8 {
	return i >> 8
}

// the lowest 8 bits of the instruction

fn (i Instr) kk() u8 {
	return u8(i)
}

// the lowest 12 bits of the instruction
fn (i Instr) nnn() u16 {
	return i & 0xFFF
}

// highest 4
fn (i Instr) a() u8 {
	return i >> 12
}

// the lower 4 bits of the high u8 of the instruction
fn (i Instr) x() u8 {
	return u8(i & 0x0F00 >> 8)
}

// the upper 4 bits of the low u8 of the instruction
fn (i Instr) y() u8 {
	return u8(i & 0x00F0 >> 4)
}

// the lowest 4 bits of the instruction
fn (i Instr) n() u8 {
	return u8(i & 0x000F)
}

fn (i Instr) getn(b int) u8 {
	debug('${0xF000 >> (4 * b):X}')
	debug('${i & (0xF000 >> (4 * b)):X}')
	return u8(i & (0xF000 >> (4 * b))) >> (4 * (4 - 1 - b))
}

fn (i Instr) println() {
	println(i)
	println(i.tostring())
}

fn (i Instr) hex() string {
	return '${i:04X}'
}

fn (i Instr) tostring() string {
	return '(${i:04X}, nnn:${i.nnn():03X}, x:${i.x():X}, y:${i.y():X}, n:${i.n():X})'
}
