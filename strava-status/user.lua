dofile("rgb.lc")
dofile("strava.lc")
rgb_setup(function()
    strava(function() node.dsleep(2000000) end,
           function() node.dsleep(2000000) end)
end,function()
    error(1)
end)
