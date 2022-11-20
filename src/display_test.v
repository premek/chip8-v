module main

fn test_display() {
	mut d := new_display(4, 3)
	assert d.len == 4
	assert d[0].len == 3
	assert d[0][0] == false
	assert d[3][2] == false
	d.pixel(1, 2, true)
	assert d[1][2] == true
	// xor
	d.pixel(1, 2, true)
	assert d[1][2] == false
	d.pixel(1, 2, true)
	assert d[1][2] == true
	d.clear()
	assert d[1][2] == false
}
