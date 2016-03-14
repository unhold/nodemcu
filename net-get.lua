GOOGLE_GET="GET / HTTP/1.1\r\nHost: google.com\r\nConnection: close\r\n\r\n"

s=net.createConnection(net.TCP,0)
s:on("connection",function (_) print("connected") end)
s:on("disconnection",function(_) print("disconnected") end)
s:on("receive",function(_,d) print(d) end)
s:connect(80,"google.com")
s:send(GOOGLE_GET)
