gpio.mode(8,gpio.INPUT)
tmr.alarm(0,5000,tmr.ALARM_SINGLE,function() dofile("user.lua") end)
uart.on("data",0,function() tmr.stop(0) end,1)
print("Enter anything to stop boot")
