module main

fn test_instr() {
	i := Instr(0x12ef)
	assert i.hi() == 0x12
	assert i.lo() == 0xef
	assert i.kk() == i.lo()
	assert i.nnn() == 0x2ef
	assert i.a() == 0x1
	assert i.x() == 0x2
	assert i.y() == 0xe
	assert i.n() == 0xf
	assert i.hex() == '12EF'
	assert i.tostring() == '(12EF, nnn:2EF, x:2, y:E, n:F)'
}
