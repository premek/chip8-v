import os
import time
import rand

struct Vm {
mut:
	ram          [4096]u8
	pc           u16    // program counter - the currently executing address
	v            [16]u8 // general purpose 8-bit registers Vx (V0 -VF)
	i            u16    // generally used to store memory addresses
	dt           u8     // delay timer
	st           u8     // sound timer
	stack        []u16
	display      Display
	pressed_keys [16]bool
}

fn new_vm(app_filename string) &Vm {
	mut vm := Vm{
		ram: [4096]u8{}
		pc: 0x200
		display: [][]bool{len: w, init: []bool{len: h}}
	}
	vm.load('/home/premek/downloads/FONTS.chip8', 0) // FIXME
	vm.load(app_filename, vm.pc)
	return &vm
}

fn (m Vm) print(pc int) {
	debug('${m.ram[pc]:X}')
}

fn (m Vm) tostring() string {
	return '${m.v}'
}

fn (mut m Vm) load(filename string, start int) {
	data := os.read_file(filename) or { panic('error reading ${filename}') }
	for i, b in data {
		m.ram[start + i] = b
	}
}

fn (mut m Vm) read_instruction() Instr {
	hi := m.ram[m.pc]
	m.pc++
	lo := m.ram[m.pc]
	m.pc++
	return (u16(hi) << 8) + lo
}

fn (mut m Vm) run() {
	for m.pc < m.ram.len {
		if m.step() {
			break
		}
		// debug('\t')
		time.sleep(16 * time.millisecond)
	}
	debug('program end')
}

fn (mut m Vm) step() bool {
	i := m.read_instruction()
	debug(i.tostring())
	if i == 0 {
		return true
	}
	m.run_instruction(i)
	if m.st > 0 {
		m.st-- // TODO play/stop sound
	}
	if m.dt > 0 {
		m.dt--
	}
	return false
}

fn (mut m Vm) run_instruction(i Instr) {
	// TODO do some kind of matcher for the patterns like 7xkk etc?
	match true {
		i == 0x00E0 {
			m.display.clear()
		}
		i == 0x00EE {
			debug('ret')
			m.pc = m.stack.pop()
		}
		i.a() == 1 {
			debug('goto nnn')
			m.pc = i.nnn()
		}
		i.a() == 2 {
			debug('call nnn')
			m.stack << m.pc
			m.pc = i.nnn()
		}
		i.a() == 3 {
			debug('Skip next if Vx = kk')
			if m.v[i.x()] == i.kk() {
				m.pc += 2
			}
		}
		i.a() == 4 {
			debug('Skip next if Vx != kk')
			if m.v[i.x()] != i.kk() {
				m.pc += 2
			}
		}
		i.a() == 5 {
			debug('Skip next if Vx = Vy')
			if m.v[i.x()] == m.v[i.y()] {
				m.pc += 2
			}
		}
		i.a() == 6 {
			m.v[i.x()] = i.kk()
			debug('V${i.x()}=${i.kk()}; ${m.v}')
		}
		i.a() == 7 {
			m.v[i.x()] += i.kk()
			debug('Vx += kk')
		}
		i.a() == 8 && i.n() == 0 {
			debug('Vx=Vy')
			m.v[i.x()] = m.v[i.y()]
		}
		i.a() == 8 && i.n() == 1 {
			debug('Vx|=Vy')
			m.v[i.x()] |= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 2 {
			debug('Vx&=Vy')
			m.v[i.x()] &= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 3 {
			debug('Vx^=Vy')
			m.v[i.x()] ^= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 4 {
			debug('vx = vx + vy, set vf = carry')
			ret := u16(m.v[i.x()]) + m.v[i.y()]
			m.v[i.x()] = u8(ret)
			m.v[0xf] = if ret > 0xFF { u8(1) } else { 0 }
		}
		i.a() == 8 && i.n() == 5 {
			debug('Vx = Vx - Vy, set VF = NOT borrow')
			m.v[0xf] = if m.v[i.x()] > m.v[i.y()] { u8(1) } else { 0 }
			m.v[i.x()] -= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 6 {
			debug('Vx = Vx SHR 1, VF overfl')
			m.v[0xf] = m.v[i.x()] & 1
			m.v[i.x()] >>= 1
		}
		i.a() == 8 && i.n() == 7 {
			debug('Vx = Vy - Vx, set VF = NOT borrow')
			m.v[0xf] = if m.v[i.y()] > m.v[i.x()] { u8(1) } else { 0 }
			m.v[i.x()] = m.v[i.y()] - m.v[i.x()]
		}
		i.a() == 8 && i.n() == 0xE {
			debug('Vx = Vx SHL 1, VF overfl')
			m.v[0xf] = m.v[i.x()] >> 7
			m.v[i.x()] <<= 1
		}
		i.a() == 9 {
			debug('Skip next if Vx != Vy')
			if m.v[i.x()] != m.v[i.y()] {
				m.pc += 2
			}
		}
		i.a() == 0xA {
			debug('I=nnn')
			m.i = i.nnn()
		}
		i.a() == 0xC {
			debug('Vx = rand & kk')
			m.v[i.x()] = rand.u8() & i.kk()
		}
		i.a() == 0xD {
			sprite := m.ram[m.i..m.i + i.n()]
			sx := m.v[i.x()]
			sy := m.v[i.y()]
			debug('Sprite on (${sx}, ${sy}): [')
			for r, row in sprite {
				y := sy + r
				print("'")
				for bit in 0 .. 8 {
					x := sx + bit
					val := (row >> (7 - bit)) & 1 == 1
					m.display.pixel(x % w, y % h, val)
					print(if val { '#' } else { ' ' })
				}
				debug("'")
			}
			debug(']')

			// TODO set VF collision
		}
		i.a() == 0xE && i.kk() == 0x9E {
			debug('skip next if key Vx pressed')
			if m.pressed_keys[m.v[i.x()]] {
				m.pc += 2
			}
		}
		i.a() == 0xE && i.kk() == 0xA1 {
			debug('skip next if key Vx not pressed')
			if !m.pressed_keys[m.v[i.x()]] {
				m.pc += 2
			}
		}
		i.a() == 0xF && i.kk() == 0x0A {
			debug('Wait for key, store key in Vx')
			if key := get_pressed_key(m) {
				m.v[i.x()] = key
			} else {
				m.pc -= 2 // stay on the same instruction - wait for key
			}
		}
		i.a() == 0xF && i.kk() == 0x07 {
			m.v[i.x()] = m.dt
		}
		i.a() == 0xF && i.kk() == 0x15 {
			m.dt = m.v[i.x()]
		}
		i.a() == 0xF && i.kk() == 0x1E {
			m.i += m.v[i.x()]
		}
		i.a() == 0xF && i.kk() == 0x18 {
			m.st = m.v[i.x()]
		}
		i.a() == 0xF && i.kk() == 0x29 {
			m.i = m.v[i.x()] * 5
			debug('I = location of sprite for digit Vx; Vx=${m.v[i.x()]}; I=${m.i}')
		}
		i.a() == 0xF && i.kk() == 0x33 {
			debug('BCD Vx -> I, I+1, I+2')
			m.ram[m.i] = m.v[i.x()] / 100
			m.ram[m.i + 1] = m.v[i.x()] / 10 % 10
			m.ram[m.i + 2] = m.v[i.x()] % 10
		}
		i.a() == 0xF && i.kk() == 0x55 {
			for x in 0 .. i.x() + 1 {
				debug('ram[${m.i}+${x}] = V${x}')
				m.ram[m.i + x] = m.v[x]
			}
		}
		i.a() == 0xF && i.kk() == 0x65 {
			for x in 0 .. i.x() + 1 {
				debug('V${x} = ram[${m.i}+${x}]')
				m.v[x] = m.ram[m.i + x]
			}
		}
		else {
			panic('unknown instruction ${i.hex()}')
		}
	}
}

fn get_pressed_key(m Vm) ?u8 {
	for key, pressed in m.pressed_keys {
		if pressed {
			return u8(key)
		}
	}
	return none
}
