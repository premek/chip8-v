struct TextDisplay {
mut:
	pixels [64][32]bool
	dirty  bool
}

fn (mut d TextDisplay) refresh() {
	if !d.dirty {
		return
	}
	for y in 0 .. h {
		for x in 0 .. w {
			print(if d.pixels[x][y] { '#' } else { ' ' })
		}
		println('')
	}
	d.dirty = false
}

fn (mut d TextDisplay) clear() {
	d.pixels = [64][32]bool{init: [32]bool{}}
	d.dirty = true
}

fn (mut d TextDisplay) pixel(x int, y int, val bool) {
	// xor
	d.pixels[x][y] = d.pixels[x][y] != val
	d.dirty = true
}

fn new_text_display() TextDisplay {
	mut d := TextDisplay{}
	d.clear()
	return d
}
