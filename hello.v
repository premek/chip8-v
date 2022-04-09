import rand
import time
import os

const (
	w = 64
	h = 32
)

interface Display {
mut:
	pixel(x int, y int, val bool)
	clear()
	refresh()
}

struct Stack {
mut:
	data    [16]u16
	pointer byte
}

fn (mut s Stack) push(e u16) {
	s.pointer++
	s.data[s.pointer] = e
}

fn (mut s Stack) pop() u16 {
	ret := s.data[s.pointer]
	s.pointer--
	return ret
}

struct Vm {
mut:
	ram     [4096]byte
	pc      u16
	v       [16]byte
	i       u16
	stack   Stack
	display Display
}

fn (m Vm) print(pc int) {
	println('${m.ram[pc]:X}')
}

fn (m Vm) tostring() string {
	return '$m.v'
}

fn (mut m Vm) load(filename string, start int) {
	data := os.read_file(filename) or { panic('error reading $filename') }
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
		i := m.read_instruction()
		println(i.tostring())
		if i == 0 {
			break
		}
		m.run_instruction(i)
		m.display.refresh()
		println('\t')
		time.sleep(20 * time.millisecond)
	}
	println('program end')
}

fn (mut m Vm) run_instruction(i Instr) {
	// TODO do some kind of matcher for the patterns like 7xkk etc?
	match true {
		i == 0x00E0 {
			m.display.clear()
		}
		i == 0x00EE {
			println('ret')
			m.pc = m.stack.pop()
		}
		i.a() == 1 {
			println('goto nnn')
			m.pc = i.nnn()
		}
		i.a() == 2 {
			println('call nnn')
			m.stack.push(m.pc)
			m.pc = i.nnn()
		}
		i.a() == 3 {
			println('Skip next if Vx = kk')
			if m.v[i.x()] == i.kk() {
				m.pc += 2
			}
		}
		i.a() == 4 {
			println('Skip next if Vx != kk')
			if m.v[i.x()] != i.kk() {
				m.pc += 2
			}
		}
		i.a() == 5 {
			println('Skip next if Vx = Vy')
			if m.v[i.x()] == m.v[i.y()] {
				m.pc += 2
			}
		}
		i.a() == 6 {
			m.v[i.x()] = i.kk()
			println('V$i.x()=$i.kk(); $m.v')
		}
		i.a() == 7 {
			m.v[i.x()] += i.kk()
			println('Vx += kk')
		}
		i.a() == 8 && i.n() == 0 {
			println('Vx=Vy')
			m.v[i.x()] = m.v[i.y()]
		}
		i.a() == 8 && i.n() == 1 {
			println('Vx|=Vy')
			m.v[i.x()] |= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 2 {
			println('Vx&=Vy')
			m.v[i.x()] &= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 3 {
			println('Vx^=Vy')
			m.v[i.x()] ^= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 4 {
			println('vx = vx + vy, set vf = carry')
			ret := u16(m.v[i.x()]) + m.v[i.y()]
			m.v[i.x()] = byte(ret)
			m.v[0xf] = if ret > 0xFF { byte(1) } else { 0 }
		}
		i.a() == 8 && i.n() == 5 {
			println('Vx = Vx - Vy, set VF = NOT borrow')
			m.v[0xf] = if m.v[i.x()] > m.v[i.y()] { byte(1) } else { 0 }
			m.v[i.x()] -= m.v[i.y()]
		}
		i.a() == 8 && i.n() == 6 {
			println('Vx = Vx SHR 1, VF overfl')
			m.v[0xf] = m.v[i.x()] & 1
			m.v[i.x()] >>= 1
		}
		i.a() == 8 && i.n() == 7 {
			println('Vx = Vy - Vx, set VF = NOT borrow')
			m.v[0xf] = if m.v[i.y()] > m.v[i.x()] { byte(1) } else { 0 }
			m.v[i.x()] = m.v[i.y()] - m.v[i.x()]
		}
		i.a() == 8 && i.n() == 0xE {
			println('Vx = Vx SHL 1, VF overfl')
			m.v[0xf] = m.v[i.x()] >> 7
			m.v[i.x()] <<= 1
		}
		i.a() == 9 {
			println('Skip next if Vx != Vy')
			if m.v[i.x()] != m.v[i.y()] {
				m.pc += 2
			}
		}
		i.a() == 0xA {
			println('I=nnn')
			m.i = i.nnn()
		}
		i.a() == 0xC {
			println('Vx = rand & kk')
			m.v[i.x()] = rand.byte() & i.kk()
		}
		i.a() == 0xD {
			sprite := m.ram[m.i..m.i + i.n()]
			sx := m.v[i.x()]
			sy := m.v[i.y()]
			println('Sprite on ($sx, $sy): [')
			for r, row in sprite {
				y := sy + r
				print("'")
				for bit in 0 .. 8 {
					x := sx + bit
					val := (row >> (7 - bit)) & 1 == 1
					m.display.pixel(x % w, y % h, val)
					print(if val { '#' } else { ' ' })
				}
				println("'")
			}
			println(']')

			// TODO set VF collision
		}
		i.a() == 0xF && i.kk() == 0x29 {
			m.i = m.v[i.x()] * 5
			println('I = location of sprite for digit Vx; Vx=${m.v[i.x()]}; I=$m.i')
		}
		i.a() == 0xF && i.kk() == 0x33 {
			println('BCD Vx -> I, I+1, I+2')
			m.ram[m.i] = m.v[i.x()] / 100
			m.ram[m.i + 1] = m.v[i.x()] / 10 % 10
			m.ram[m.i + 2] = m.v[i.x()] % 10
		}
		i.a() == 0xF && i.kk() == 0x55 {
			for x in 0 .. i.x() + 1 {
				println('ram[$m.i+$x] = V$x')
				m.ram[m.i + x] = m.v[x]
			}
		}
		i.a() == 0xF && i.kk() == 0x65 {
			for x in 0 .. i.x() + 1 {
				println('V$x = ram[$m.i+$x]')
				m.v[x] = m.ram[m.i + x]
			}
		}
		else {
			panic('unknown instruction $i.hex()')
		}
	}
}

fn main() {
	display, uithread := new_ui_display()
	// display := new_text_display()

	mut vm := Vm{
		ram: [4096]byte{}
		pc: 0x200
		display: display
	}

	//	vm.load('/home/premek/downloads/displayNumbers.rom', vm.pc)
	vm.load('/home/premek/downloads/test_opcode.ch8', vm.pc)
	vm.load('/home/premek/downloads/FONTS.chip8', 0)
	vm.run()

	uithread.wait()
}
