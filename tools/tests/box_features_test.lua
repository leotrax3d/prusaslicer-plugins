dofile("tools/tests/mock.lua")
dofile("plugins/com.leotrax3d.utilities/box_generator.lua")
local base = {inner_width=80, inner_depth=60, inner_height=40, wall=2.0, floor_th=1.6,
    corner_radius=3, columns=1, rows=1, divider_th=1.6, divider_pct=100,
    stackable=false, finger_notch=true, with_lid=false, clearance=0.25, label="A"}
execute(base)
local b = world_boxes(objects[1])
local notch = extent(b, function(x) return x.rot and x.rot.x==90 and x.tag=="cyl" end)
print("notch " .. fmt(notch))
check("notch cuts through front wall (y0)", notch.y0, -1)
check("notch exits wall (y1)", notch.y1, 3)
check("notch centred on top edge", (notch.z0+notch.z1)/2, 41.6)
check("notch centred in X", (notch.x0+notch.x1)/2, 42)
local lab = extent(b, function(x) return x.tag=="text:A" end)
print("label " .. fmt(lab))
check("label starts at front face", lab.y0, 0)
check("label depth into wall", lab.y1, 0.6)

-- square corners and a radius larger than the box both have to stay sane
objects = {}
execute((function() local t={} for k,v in pairs(base) do t[k]=v end t.corner_radius=0 t.finger_notch=false t.label="" return t end)())
local sq = extent(world_boxes(objects[1]), function(x) return x.type=="Solid" end)
check("r=0 outer width", sq.x1-sq.x0, 84)
objects = {}
execute((function() local t={} for k,v in pairs(base) do t[k]=v end t.corner_radius=999 t.finger_notch=false t.label="" return t end)())
local rr = extent(world_boxes(objects[1]), function(x) return x.type=="Solid" end)
check("r clamped: width still 84", rr.x1-rr.x0, 84)
check("r clamped: depth still 64", rr.y1-rr.y0, 64)

-- partial-height dividers
objects = {}
execute((function() local t={} for k,v in pairs(base) do t[k]=v end t.columns=2 t.divider_pct=50 t.finger_notch=false t.label="" return t end)())
local d = extent(world_boxes(objects[1]), function(x) return x.type=="Solid" and x.z0==1.6 end)
check("divider height 50%", d.z1-d.z0, 20)
done()
