DAYNAMES={"mon","tue","wed","thu","fri","sat","sun"}

function get_hms(epoch)
	local daytime=epoch%86400
	local hour=daytime/3600
	local minute=daytime/60%60
	local second=daytime%60
	return hour,minute,second
end

function get_ymd(epoch)
	local day=epoch/86400
	local year=1970+day/365
	day=day%365-(year-1969)/4
	if day<1 then
		year=year-1
		if year%4==0 then
			day=day+366
		else
			day=day+365
		end
	end
	local days_in_month={31,28,31,30,31,30,31,31,30,31,30,31}
	if year%4==0 then table[2]=29 end
	local month=1
	while day>days_in_month[month] do
		day=day-days_in_month[month]
		month=month+1
	end
	return year,month,day
end

function get_epoch(year,month,day,hour,minute,second,tzoff)
	month,day,hour,minute,second=month or 0,day or 0,hour or 0,minute or 0,second or 0
	local days_in_month={31,28,31,30,31,30,31,31,30,31,30,31}
	if year%4==0 then table[2]=29 end
	for m=1,month-1,1 do
		day=day+days_in_month[m]
	end
	day=day+(year-1970)*365+(year-1969)/4
	return ((day*24+hour)*60+minute)*60+second
end

function get_weekday(epoch)
	return (epoch/86400+3)%7+1
end

function get_cest_off(epoch)
	local function get_last_sunday(epoch)
		return epoch-get_weekday(epoch)%7*86400
	end
	local y=get_ymd(epoch)
	local switch=get_last_sunday(get_epoch(y,3,31,1))
	if epoch<switch then return 3600,switch end
	local switch=get_last_sunday(get_epoch(y,10,31,1))
	if epoch<switch then return 7200,switch end
	local switch=get_last_sunday(get_epoch(y+1,3,31,1))
	return 3600,switch
end

function handle_cest(epoch)
	if not next_cest_switch or epoch>=next_cest_switch then
		cest_off,next_cest_switch=get_cest_off(epoch)
	end
end

function date_sync(cont)
	sntp.sync("2.at.pool.ntp.org",function()
		epoch=rtctime.get()
		handle_cest(epoch)
		print("sntp synced to "..epoch)
		if cont then cont() end
	end,function(err)
		print("sntp error "..err)
	end)
end

function date_echo(epoch)
	local l_cest_off=cest_off
	if not epoch then
		epoch=epoch or rtctime.get()
	else
		l_cest_off=get_cest_off(epoch)
	end
	local h,m,s=get_hms(epoch+l_cest_off)
	local Y,M,D=get_ymd(epoch+l_cest_off)
	local W=get_weekday(epoch+l_cest_off)
	print(string.format("%d UTC+%d (CE%sT) %02d-%02d-%02d (%s) %02d:%02d:%02d",
		epoch,
		l_cest_off/3600,
		(l_cest_off==7200 and "S" or ""),
		Y,M,D,
		DAYNAMES[W],
		h,m,s))
end

date_sync(function()
	tmr.alarm(0,60000,tmr.ALARM_AUTO,date_sync)
	date_echo()
	tmr.alarm(1,1000,tmr.ALARM_AUTO,date_echo)
end)
