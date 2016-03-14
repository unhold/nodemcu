http.get("http://api.thingspeak.com/apps/thinghttp/send_request?api_key=W2NNAGWNBJ3RFUJF",nil,function(sta,bod)
	print("get status: "..sta)
	if sta==200 then
		local tab=cjson.decode(bod)
		local rst=tonumber(tab["recent_swim_totals"]["moving_time"])
		print("Chris Crabon's recent swim time: "..rst.." sec")
	else
		print("failed")
	end
end)
