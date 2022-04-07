struct TextDisplay {
mut:
	pixels [64][32]bool
}

fn (d TextDisplay) print() {
	for y in 0 .. h {
		for x in 0 .. w {
			print(if d.pixels[x][y] { '#' } else { ' ' })
		}
		println('')
	}
}

fn (mut d TextDisplay) clear() {
	d.pixels = [64][32]bool{init: [32]bool{}}
	d.print()
}

fn (mut d TextDisplay) pixel(x int, y int, val bool) {
	// xor
	d.pixels[x][y] = d.pixels[x][y] != val
	d.print()
}

fn new_text_display() TextDisplay {
	mut d := TextDisplay{}
	d.clear()
	return d
}
