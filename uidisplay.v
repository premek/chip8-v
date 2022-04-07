import ui
import gx

const (
	black = gx.rgb(0, 0, 0)
	white = gx.rgb(255, 255, 255)
)

struct App {
mut:
	window &ui.Window
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
