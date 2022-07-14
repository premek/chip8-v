import gg

const (
	w       = 64
	h       = 32
	pwidth  = 640
	pheight = 320
	psize   = pwidth / w

	/*
	1234      123C
	qwer --\\ 456D
	asdf --// 789E
	zxcv      A0BF
	*/
	keys    = {
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
)

struct Pattern {
	pattern []u8
	handler fn (mut m Vm)
}

fn new_pattern(pattern string, handler fn (mut m Vm)) Pattern {
	return Pattern{pattern.runes().map(u8('0x$it'.int())), handler}
}

fn (p Pattern) matches(i Instr) bool {
	for b in 0 .. 4 {
		a := i.getn(b)

		if a != p.pattern[b] {
			return false
		}
	}
	return true
}

fn main() {
	app := '/home/premek/downloads/br8kout.ch8'
	// '/home/premek/downloads/test_opcode.ch8'
	// '/home/premek/downloads/IBM Logo.ch8'
	// '/home/premek/downloads/ghostEscape.ch8'
	// '/home/premek/downloads/br8kout.ch8'
	// '/home/premek/downloads/FONTS.chip8'
	mut vm := new_vm(app)
	vm.run()
}

fn (mut d Display) key_pressed(key u8) bool {
	println(key)
	println(d.pressed_keys)
	for i, k in d.pressed_keys {
		if k {
			panic('$i $k')
		}
	}
	return false // d.keys_pressed[key]
}

fn debug(s string) {
	// println(s)
}
