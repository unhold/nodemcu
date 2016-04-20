slider=[[
HTTP/1.1 200 OK\r\n\r\n
<html>
<body>
<input type="range" min="0" max="360" value="60" onchange="setColorNumber(this)">
<p id="status">move slider</p>
<script>
function setColorNumber(elem) {
    var status=document.getElementById("status")
    var xhp=new window.XMLHttpRequest()
    xhp.open("POST","/post",true)
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

srv=net.createServer(net.TCP)
srv:listen(80,function(sk)
    sk:on("receive",function(sk,dat)
        print(dat)
        local get=dat:match("^GET /%S*")
        if get then
            get=get:sub(6)
            print("get="..get)
            if get=="slider" then
                sk:send(slider)
            else
                sk:send("HTTP/1.1 404 Not found\r\n\r\n")
            end
        end
        if dat:match("^POST /post") then
            local color=dat:match("color: %d+")
            if color then
                print(color)
                color=color:sub(8)
                print("color="..color)
            else
                color=0
            end
            sk:send("HTTP/1.1 200 OK\r\n\r\ncolor "..color.." set\r\n")
        end
        sk:close()
    end)
end)