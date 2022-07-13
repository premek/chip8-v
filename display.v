import gx
import gg

const (
	black = gx.rgb(0, 0, 0)
	white = gx.rgb(255, 255, 255)
)

type Display = [][]gx.Color

fn new_display(w int, h int) Display {
	display := [][]gx.Color{len: w, init: []gx.Color{len: h}}

	mut context := gg.new_context(
		bg_color: black
		width: pwidth
		height: pheight
		window_title: 'Polygons'
		frame_fn: fn [display] (mut ctx gg.Context) {
			frame(display, mut ctx)
		}
	)

	go context.run()

	return display
}

fn (mut display Display) clear() {
	println('display clear')
	for mut col in display {
		for mut p in col {
			p = black
		}
	}
}

fn (mut display Display) pixel(x int, y int, val bool) {
	// println('Display ($x,$y)=$val')
	// xor
	color := if val { white } else { black }
	newcolor := if color != display[x][y] { white } else { black }
	display[x][y] = newcolor
}

fn frame(display Display, mut ctx gg.Context) {
	ctx.begin()
	for x, col in display {
		for y, pixel in col {
			ctx.draw_square_filled(x * psize, y * psize, psize, pixel)
		}
	}
	ctx.end()
}
