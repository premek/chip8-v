type Instr = u16

fn (i Instr) lo() byte {
	return byte(i)
}

fn (i Instr) hi() byte {
	return i >> 8
}

// the lowest 8 bits of the instruction

fn (i Instr) kk() byte {
	return byte(i)
}

// the lowest 12 bits of the instruction
fn (i Instr) nnn() u16 {
	return i & 0xFFF
}

// highest 4
fn (i Instr) a() byte {
	return i >> 12
}

// the lower 4 bits of the high byte of the instruction
fn (i Instr) x() byte {
	return byte(i & 0x0F00 >> 8)
}

// the upper 4 bits of the low byte of the instruction
fn (i Instr) y() byte {
	return byte(i & 0x00F0 >> 4)
}

// the lowest 4 bits of the instruction
fn (i Instr) n() byte {
	return byte(i & 0x000F)
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
