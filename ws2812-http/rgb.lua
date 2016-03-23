DIN_PIN=7
PSW_PIN=3

RGB_MAX=24

RGB_RED=string.char(0,RGB_MAX,0)
RGB_YEL=string.char(RGB_MAX/2,RGB_MAX/2,0)
RGB_GRN=string.char(RGB_MAX,0,0)

RGB_TABLE={
	["r"]=0,	["o"]=30,	["y"]=60,	["l"]=90,
	["g"]=120,	["a"]=150,	["c"]=180,	["u"]=210,
	["b"]=240,	["p"]=270,	["m"]=300,	["e"]=330}

function rgb_on()
	gpio.write(PSW_PIN,1)
end

function rgb_off()
	gpio.mode(DIN_PIN,gpio.INPUT)
	gpio.write(PSW_PIN,0)
end

function rgb_status(color,timeout)
	tmr.stop(0)
	rgb_on()
	ws2812.write(DIN_PIN,color)
	timeout=timeout or 5000
	tmr.alarm(0,timeout,tmr.ALARM_SINGLE,rgb_off)
end

function rgb_init()
	gpio.mode(PSW_PIN,gpio.OUTPUT)
	rgb_status(RGB_YEL)
end

function rgb_setup(cont)
	enduser_setup.start(
		function()
			rgb_status(RGB_GRN)
			if cont then
				tmr.alarm(1,100,tmr.ALARM_SINGLE,cont)
			end
		end,
		function(num,str)
			print("enduser_setup ERROR "..num..": "..str)
			rgb_status(RGB_RED)
		end)
end

function rgb_str(str)
	local k=string.char(0,0,0)
	local res=""
	for c in str:gmatch(".") do
		res=res..(RGB_TABLE[c] and rgb_color(RGB_TABLE[c],RGB_MAX) or k)
	end
	res=res..k
	res=res:rep((20+str:len())/(str:len()+1))
	rgb_status(res,10000)
end

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

function rgb_num(num)
	num=tonumber(num)
	local c=string.char(0,0,0)
	if num then
		c=rgb_color(num,RGB_MAX)
	end
	rgb_status(c:rep(20),10000)
end

httpOK="HTTP/1.1 200 OK\r\n\r\n"

httpSlider=httpOK..[[
<html>
<body>
<input type="range" min="0" max="360" value="60" onchange="setColorNumber(this)">
<p id="status">move slider</p>
<script>
function setColorNumber(elem) {
	var status=document.getElementById("status")
	var xhp=new window.XMLHttpRequest()
	xhp.open("POST","/slider",true)
	xhp.setRequestHeader("color",elem.value)
	xhp.onreadystatechange=function() {
		if (xhp.readyState==4) {
			if (xhp.status==200) status.innerHTML=xhp.responseText
			else status.innerHTML="error "+xhp.status+": "+xhp.statusText
		}
	}
	status.innerHTML="waiting for response..."
	xhp.send()
}
</script>
</body>
</html>
]]

function rgb_srv()
	srv=net.createServer(net.TCP)
	srv:listen(80,function(sk)
		sk:on("receive",function(sk,dat)
			if dat:match("^GET /slider ") then
				sk:send(httpSlider)
			elseif dat:match("^POST /slider ") then
				local arg=dat:match("color: %d+")
				if arg then
					arg=arg:sub(8)
					rgb_num(arg)
					sk:send(httpOK.."color "..arg.." set")
				else
					sk:send("HTTP/1.1 400 Bad Request\r\n\r\nbad request")
				end
			else
				get=dat:match("^GET /.../%S+")
				if get then
					local root=get:sub(6,8)
					local arg=get:sub(10)
					if root=="str" then
						rgb_str(arg)
					elseif root=="num" then
						rgb_num(arg)
					end
					sk:send(httpOK..root.." "..arg.." set")
				else
					sk:send("HTTP/1.1 404 Not Found\r\n\r\npage not found")
				end
			end
			sk:close()
		end)
	end)
end
