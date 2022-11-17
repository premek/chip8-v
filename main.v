import gg
import gx
import os

const (
	/*
	1234      123C
	qwer --\\ 456D
	asdf --// 789E
	zxcv      A0BF
	*/
	keys = {
		gg.KeyCode._1: 1
		gg.KeyCode._2: 2
		gg.KeyCode._3: 3
		gg.KeyCode._4: 0xC
		gg.KeyCode.q:  4
		gg.KeyCode.w:  5
		gg.KeyCode.e:  6
		gg.KeyCode.r:  0xD
		gg.KeyCode.a:  7
		gg.KeyCode.s:  8
		gg.KeyCode.d:  9
		gg.KeyCode.f:  0xE
		gg.KeyCode.z:  0xA
		gg.KeyCode.x:  0
		gg.KeyCode.c:  0xB
		gg.KeyCode.v:  0xF
	}
	black = gx.rgb(0, 0, 0)
	white = gx.rgb(255, 255, 255)
)

struct AppState {
mut:
	gg &gg.Context = unsafe { nil }
	vm &Vm = unsafe { nil }
}

[noreturn]
fn usage() {
	println('usage: ${os.args[0]} <filename>')
	exit(1)
}

fn main() {
	// app := '/home/premek/downloads/br8kout.ch8'
	// app := '/home/premek/downloads/Life [GV Samways, 1980].ch8'
	// app := '/home/premek/downloads/test_opcode.ch8'
	// app := '/home/premek/downloads/Delay Timer Test [Matthew Mikolay, 2010].ch8'
	// app := '/home/premek/downloads/chip8-test-rom.ch8'
	// app := '/home/premek/downloads/random_number_test.ch8'
	// app := '/home/premek/downloads/IBM Logo.ch8'
	// app := '/home/premek/downloads/Keypad Test [Hap, 2006].ch8'
	// app := '/home/premek/downloads/pong.rom'

	mut state := &AppState{}
	state.vm = new_vm(os.args[1] or { usage() })
	state.gg = gg.new_context(
		bg_color: black
		width: pwidth
		height: pheight
		window_title: 'vlang chip 8 '
		create_window: true
		frame_fn: frame
		keyup_fn: keyup
		keydown_fn: keydown
		user_data: state // passed to callback functions
	)

	spawn state.vm.run()
	state.gg.run()
}

fn frame(mut state AppState) {
	state.gg.begin()
	for x, col in state.vm.display {
		for y, pixel in col {
			color := if pixel {
				white
			} else {
				black
			}
			state.gg.draw_square_filled(x * psize, y * psize, psize, color)
		}
	}
	// state.gg.show_fps()
	state.gg.end()
}

fn keydown(c gg.KeyCode, m gg.Modifier, mut state AppState) {
	key := keys[c] or { return }
	state.vm.pressed_keys[key] = true
}

fn keyup(c gg.KeyCode, m gg.Modifier, mut state AppState) {
	key := keys[c] or { return }
	state.vm.pressed_keys[key] = false
}

fn debug(s string) {
	//	println(s)
}
