dofile("secret.lua")

DHT_PIN=6
DHT_SAMPLES=3
DHT_PAUSE_MS=2000
TEMP_OFF=0
HUMI_OFF=0
VBAT_OFF=-200
rst=true

function mili_str(n)
    return string.format("%d.%03d",n/1000,n%1000)
end

function med_avg_OFF(tbl)
    if #tbl<2 then return nil end
    table.sort(tbl)
    local first=#tbl/2
    local last=#tbl-first+1
    local sum=0
    for idx=first,last,1 do
        sum=sum+tbl[idx]--
    end
    return sum/(last-first+1)
end

function med_avg(tbl)
    table.sort(tbl)
    return tbl[(#tbl+1)/2]--
end

function dht_measure(cont)
    local samples=DHT_SAMPLES
    local temp={}
    local humi={}
    local vbat={}
    tmr.alarm(0,DHT_PAUSE_MS,tmr.ALARM_AUTO,function()
    	local v=adc.readvdd33()
        local s,t0,h0,t1,h1=dht.read(DHT_PIN)
        local t=1000*t0+t1
        local h=1000*h0+h1
        print("#"..samples.." err"..s.." "..mili_str(t).."°C "..mili_str(h).."% "..mili_str(v).."V")
        table.insert(vbat,v)
        if s==dht.OK then
            table.insert(temp,t)
            table.insert(humi,h)
        end
        samples=samples-1
        if samples==0 then
            tmr.stop(0)
            local t=med_avg(temp)
            if t then t=t+TEMP_OFF end
            local h=med_avg(humi)
            if h then h=h+HUMI_OFF end
            local v=med_avg(vbat)
            if v then v=v+VBAT_OFF end
            cont(t,h,#temp,v)
        end
    end)
end

function ts_update(temp,humi,nmes,vbat,cont)
    local rstc=-1
    if rst then
        rst=false
        _,rstc=node.bootreason()
    end
    local t={}
    if temp then t["field1"]=mili_str(temp) end
    if humi then t["field2"]=mili_str(humi) end
    t["field3"]=nmes
    t["field4"]=mili_str(vbat)
    t["field5"]=rstc
    t["field6"]=node.heap()
    local url="http://api.thingspeak.com/update?api_key="..THINGSPEAK_KEY
    for k,v in pairs(t) do
        url=url.."&"..k.."="..v
    end
    print("HTTP GET "..url)
    http.get(url,nil,function(s,b)
        if s==200 then
            print("Thingspeak update "..b.." OK")
        else
            print("HTTP error "..s)
        end
        if cont then cont(s) end
    end)
end

function ifttt_warn(cont)
    url="http://maker.ifttt.com/trigger/esp_battery_low/with/key/"..IFTTT_KEY
    print("HTTP GET "..url)
    http.get(url,nil,function(s)
        if s==200 then
            print("IFTTT warn OK")
        else
            print("HTTP error "..s)
        end
        if cont then cont(s) end
    end)
end

function app()
    if adc.readvdd33()+VBAT_OFF<2800 then low_bat=true end
    if low_bat then ifttt_warn(nil) end
    dht_measure(function(temp,humi,nmes,vbat)
        ts_update(temp,humi,nmes,vbat,function()
            if low_bat then
                node.dsleep(0)
            elseif not stop then
                node.dsleep(293500000)
            end
        end)
    end)
end

app()
