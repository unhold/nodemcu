dofile("rgb.lc")
dofile("strava.lc")
function done()
	tmr.stop(0)
	rgb_off()
	node.dsleep(0)
end
rgb_setup(strava(done,done),done)
