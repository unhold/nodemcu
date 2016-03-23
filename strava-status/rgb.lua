DIN_PIN=7
PSW_PIN=3

RGB_MAX=64
RGB_CNT=20
RGB_OFF=string.char(0,0,0)
RGB_RED=string.char(0,RGB_MAX,0)
RGB_YEL=string.char(RGB_MAX/2,RGB_MAX/2,0)
RGB_GRN=string.char(RGB_MAX,0,0)

RGB_TABLE={
	["r"]=0,	["o"]=30,	["y"]=60,	["l"]=90,
	["g"]=120,	["a"]=150,	["c"]=180,	["u"]=210,
	["b"]=240,	["p"]=270,	["m"]=300,	["e"]=330}

function rgb_color(angle,max)
	function rgb_comp(angle,color,max)
		local dist=math.abs(angle-color)
		if dist>180 then
			dist=360-dist end
		if dist>120 then
			return 0
		else
			return max-max*dist/120
		end
	end
	angle=angle%360
	return string.char(
		rgb_comp(angle,120,max),
		rgb_comp(angle,0,max),
		rgb_comp(angle,240,max))
end

function rgb_on()
	gpio.mode(PSW_PIN,gpio.OUTPUT)
	gpio.write(PSW_PIN,1)
end

function rgb_off()
	gpio.mode(DIN_PIN,gpio.FLOAT)
	gpio.mode(PSW_PIN,gpio.OUTPUT)
	gpio.write(PSW_PIN,0)
end

function rgb_status(color,timeout,done)
	tmr.stop(0)
	str=RGB_OFF:rep(RGB_CNT/2-2)..color:rep(2)..RGB_OFF:rep(RGB_CNT/2-2)
	rgb_on()
	ws2812.write(DIN_PIN,str)
	timeout=timeout or 2000
	tmr.alarm(0,timeout,tmr.ALARM_SINGLE,function()
		rgb_off()
		if done then done() end
	end)
end

function rgb_setup(done,err)
	enduser_setup.start(done,function(num,str)
			print("enduser_setup error "..num..": "..str)
			rgb_status(RGB_RED,nil,err)
		end)
end

function rgb_color_scale(color,eights)
	local res=""
	for i=1,3 do
		res=res..string.char(color:byte(i)*3^eights*256/2^eights/6561)
	end
	return res
end

function rgb_bar(color,eights,reverse)
	if reverse then color=color:reverse() end
	local str=color:rep(eights/8)
	if eights%8~=0 then
		str=str..rgb_color_scale(color,eights%8)
	else
		str=str..RGB_OFF
	end
	str=str..RGB_OFF:rep(RGB_CNT-eights/8-1)
	if reverse then str=str:reverse() end
	rgb_on()
	ws2812.write(DIN_PIN,str)
end

function rgb_animate(color,count,reverse,done,index,delay)
	index=index or 0
	delay=delay or 20
	if index<count then
		index=index+1
		if index%8==0 then delay=delay+5 end
		rgb_bar(color,index,reverse)
		tmr.alarm(0,delay,tmr.ALARM_SINGLE,function()
			rgb_animate(color,count,reverse,done,index,delay)
		end)
	else
		tmr.alarm(0,3000,tmr.ALARM_SINGLE,function()
			if done then done() end
		end)
	end
end

RGB_STRAVA_FIELDS={
	{"distance", 2000000, "m", false},
	{"count", 40, "c", true},
	{"moving_time", 288000, "g", false},
	{"achievement_count", 20, "y", true},
	{"elevation_gain", 20000, "r", false}}

function rgb_strava(table,done,index)
	index=index or 1
	if index>#RGB_STRAVA_FIELDS then
		if done then done() end
		return
	end
	local name,max,color,reverse=unpack(RGB_STRAVA_FIELDS[index])
	local value=table[name] or 0
	value=value*160/max
	if value==0 then value=1 end
	print(name..": "..value)
	local color=rgb_color(RGB_TABLE[color],RGB_MAX)
	rgb_animate(color,value,reverse,function()
		rgb_strava(table,done,index+1)
	end)
end
