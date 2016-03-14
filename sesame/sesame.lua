gpio.mode(3,1)
gpio.write(3,0)

cnt=0
log={}

srv=net.createServer(net.TCP)

srv:listen(80,function(con)
	con:on("receive",function(c,p)
		cnt=cnt+1
		local gnt=0
		local a="count:"..cnt.." time:"..tmr.now().." heap:"..node.heap()
		if string.find(p,"GET /sesameopen9185") then
			gnt=1
			gpio.write(3,1)
			tmr.alarm(0,3000,0,function()
				gpio.write(3,0)
			end)
			a=a.."\naccess granted\n"
		else
			a=a.."\naccess denied\n"
		end
		c:send(a)
		c:close()
		print(a)
		log[cnt%10]={cnt=cnt,tmr=tmr.now(),gnt=gnt}
	end)
end)

function dumplog()
	for k,v in pairs(log) do
		local s=""
		for l,w in pairs(v) do
			s=s..l.."="..w..","
		end
		print(s)
	end
end

print("sesame v1.3 ready")
