const (
	w       = 64
	h       = 32
	pwidth  = 640
	pheight = 320
	psize   = pwidth / w
)

type Display = [][]bool

fn (mut display Display) clear() {
	for mut col in display {
		for mut p in col {
			p = false
		}
	}
}

fn (mut display Display) pixel(x int, y int, val bool) {
	display[x][y] = val != display[x][y]
}

fn new_display(w int, h int) Display {
	return [][]bool{len: w, init: []bool{len: h}}
}
