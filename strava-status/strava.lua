function strava(done,err)
	local sk=net.createConnection(net.TCP)
	sk:on("connection",function(sk)
		sk:send("GET /apps/thinghttp/send_request?api_key=IFMUCDJ3EJZVKZTR HTTP/1.1\r\nHost: api.thingspeak.com\r\n\r\n")
	end)
	sk:on("receive",function(sk,dat)
		sk:close()
		local _,e=dat:find("\r\n\r\n")
		local j=dat:sub(e+1):gsub("=>",": ")
		local ok,table=pcall(cjson.decode, j)
		if ok then
			rgb_strava(table,done)
		else
			print("JSON decode failed")
			rgb_status(RGB_RED,nil,err)
		end
	end)
	sk:connect(80,"api.thingspeak.com")
end
