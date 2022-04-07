import time
import os
import ui
import gx

const (
	black = gx.rgb(0, 0, 0)
	white = gx.rgb(255, 255, 255)
	w     = 64
	h     = 32
)

struct App {
mut:
	window &ui.Window
}

enum InstrType {
	cls
	jp
	ld
}

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

interface Display {
mut:
	pixel(x int, y int, val bool)
	clear()
}

struct UiDisplay {
mut:
	window &ui.Window
	pixels [][]ui.Rectangle
}

fn (mut d UiDisplay) clear() {
	println('display clear')
	for mut col in d.pixels {
		for mut rect in col {
			rect.color = black
		}
	}
	d.window.refresh()
}

fn (mut d UiDisplay) pixel(x int, y int, val bool) {
	//	println('Display ($x,$y)=$val')
	// xor
	color := if val { white } else { black }
	newcolor := if color != d.pixels[x][y].color { white } else { black }
	d.pixels[x][y].color = newcolor
	d.window.refresh()
}

fn new_ui_display() (UiDisplay, thread) {
	mut app := &App{
		window: 0
	}

	mut pixels := [][]ui.Rectangle{len: w, init: []ui.Rectangle{len: h}}

	mut columns := []ui.Widget{}

	for x in 0 .. w {
		mut row_children := []ui.Widget{}
		for y in 0 .. h {
			pixels[x][y] = ui.rectangle()
			row_children << pixels[x][y]
		}
		columns << ui.column(
			heights: ui.stretch
			children: row_children
		)
	}

	window := ui.window(
		width: 640
		height: 320
		title: 'Display'
		state: app
		on_key_down: fn (e ui.KeyEvent, wnd &ui.Window) {
			println(e)
			wnd.ui.gg.quit()
		}
		mode: .resizable // .max_size //
		children: [
			ui.row(
				// margin_: 10
				// spacing: .02
				widths: ui.stretch // [ui.compact, ui.stretch, ui.stretch, ui.stretch, ui.stretch, ui.stretch] // or [30.0, ui.stretch, ui.stretch, ui.stretch, ui.stretch, ui.stretch]
				bg_color: gx.rgb(150, 150, 150)
				children: columns
			),
		]
	)

	return UiDisplay{
		pixels: pixels
		window: window
	}, go ui.run(window)
}

struct Vm {
mut:
	ram     [4096]byte
	pc      u16
	v       [16]byte
	i       u16
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
		time.sleep(50 * time.millisecond)
	}
	println('program end')
}

fn (mut m Vm) run_instruction(i Instr) {
	// TODO do some kind of matcher for the patterns like 7xkk etc?
	match true {
		i == 0x00E0 {
			m.display.clear()
		}
		i.a() == 6 {
			m.v[i.x()] = i.kk()
			println('V$i.x()=$i.kk(); $m.v')
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
		else {
			panic('unknown instruction $i.hex()')
		}
	}
}

fn main() {
	display, uithread := new_ui_display()

	mut vm := Vm{
		ram: [4096]byte{}
		pc: 0x200
		display: display
	}

	vm.load('/home/premek/downloads/displayNumbers.rom', vm.pc)
	vm.load('/home/premek/downloads/FONTS.chip8', 0)
	vm.run()

	uithread.wait()
}
