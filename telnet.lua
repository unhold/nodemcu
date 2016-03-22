function telnet_srv()
	srv=net.createServer(net.TCP)
	srv:listen(23,function(c)
		c:on("disconnection",function(c) node.output(nil) end)
		c:on("receive",function(c,d) node.input(d) end)
		node.output(function(s) if c then c:send(s) end end)
	end)
end

telnet_srv()