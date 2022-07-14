import gx
import gg

const (
	black = gx.rgb(0, 0, 0)
	white = gx.rgb(255, 255, 255)
)

struct Display {
mut:
	pixels       [][]gx.Color
	context      gg.Context
	pressed_keys [512]bool // FIXME key_code_max
}

fn new_display(w int, h int) Display {
	mut display := Display{} // FIXME 'shared'?
	display.pixels = [][]gx.Color{len: w, init: []gx.Color{len: h}}
	c := gg.new_context(
		bg_color: black
		width: pwidth
		height: pheight
		window_title: 'Polygons'
		frame_fn: fn [display] (mut ctx gg.Context) {
			frame(display, mut ctx)
		}
		keyup_fn: fn [mut display] (c gg.KeyCode, m gg.Modifier, data voidptr) {
			//	display.pressed_keys[c] = false
		}
		keydown_fn: fn [mut display] (c gg.KeyCode, m gg.Modifier, data voidptr) {
			display.pressed_keys[c] = true
			println('$c pressed')
			println(display)
			//	println(display.pressed_keys)
		}
	)
	display.context = c
	go c.run()

	return display
}

fn (mut display Display) clear() {
	debug('display clear')
	for mut col in display.pixels {
		for mut p in col {
			p = black
		}
	}
}

fn (mut display Display) pixel(x int, y int, val bool) {
	// debug('Display ($x,$y)=$val')
	// xor
	color := if val { white } else { black }
	newcolor := if color != display.pixels[x][y] { white } else { black }
	display.pixels[x][y] = newcolor
}

fn frame(display Display, mut ctx gg.Context) {
	ctx.begin()
	for x, col in display.pixels {
		for y, pixel in col {
			ctx.draw_square_filled(x * psize, y * psize, psize, pixel)
		}
	}
	ctx.show_fps()
	ctx.end()
}
