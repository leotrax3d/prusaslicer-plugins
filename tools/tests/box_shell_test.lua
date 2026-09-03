dofile("tools/tests/mock.lua")
dofile("plugins/com.leotrax3d.utilities/box_generator.lua")

local o = {inner_width=80, inner_depth=60, inner_height=40, wall=2.0, floor_th=1.6,
    corner_radius=3, columns=3, rows=2, divider_th=1.6, divider_pct=100,
    stackable=true, finger_notch=true, with_lid=true, lid_height=8,
    clearance=0.25, label="SCREWS"}
execute(o)

print("objects: " .. #objects)
local box = world_boxes(objects[1])
local solids = extent(box, function(b) return b.type=="Solid" and b.tag=="cube" or (b.type=="Solid" and b.tag=="cyl") end)
print("box shell   " .. fmt(extent(box, function(b) return b.type=="Solid" end)))
check("outer width",  select(1, (function() local r=extent(box,function(b) return b.type=="Solid" end) return r.x1-r.x0 end)()), 84)
local shell = extent(box, function(b) return b.type=="Solid" end)
check("outer depth", shell.y1-shell.y0, 64)
check("outer height", shell.z1-shell.z0, 41.6)
check("sits on bed", shell.z0, 0)

-- cavity: the first Negative group (cube/cyl at z=floor)
local cav = extent(box, function(b) return b.type=="Negative" and b.tag=="cube" and b.z0>=1.5 end)
print("cavity      " .. fmt(cav))
check("cavity wall left", cav.x0-shell.x0, 2.0)
check("cavity wall front", cav.y0-shell.y0, 2.0)
check("cavity floor", cav.z0-shell.z0, 1.6)

-- groove island must sit inside the groove pocket, both under the floor
local island = extent(box, function(b) return b.type=="Solid" and b.z1<1.6 and b.z1>0 end)
print("groove island " .. fmt(island))
check("island inset", island.x0-shell.x0, 0.5+2.0+0.25)
check("island top = groove depth", island.z1, 1.0)

-- dividers: 2 across + 1 deep = 3
local n = 0
for _,b in ipairs(box) do if b.type=="Solid" and b.z0==1.6 then n=n+1 end end
check("divider count", n, 3)

local lid = world_boxes(objects[2])
local ls = extent(lid, function(b) return b.type=="Solid" end)
local lc = extent(lid, function(b) return b.type=="Negative" and b.tag~="text:SCREWS" end)
print("lid shell   " .. fmt(ls))
print("lid cavity  " .. fmt(lc))
check("lid outer width", ls.x1-ls.x0, 84+2*(0.25+2))
check("lid pocket width", lc.x1-lc.x0, 84+0.5)
check("lid pocket clears box", (lc.x1-lc.x0)-84, 0.5)
check("lid clear of box on bed", ls.y0 - 64, 12)
done()
