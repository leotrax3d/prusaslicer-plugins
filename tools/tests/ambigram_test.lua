dofile("tools/tests/mock.lua")
dofile("plugins/com.leotrax3d.utilities/ambigram.lua")

local function run(o) objects = {}; execute(o); return world_boxes(objects[1]) end
local base = {text_a="Anna", text_b="", mirror=false, font_name="", text_size=20,
    text_depth=4, base_plate=true, plate_th=2, plate_margin=6, keyring=false}

local b = run(base)
local a = extent(b, function(x) return x.tag=="text:Anna" and not x.rot end)
local r = extent(b, function(x) return x.tag=="text:Anna" and x.rot end)
print("reading A " .. fmt(a))
print("reading B " .. fmt(r))
check("A centred in X", (a.x0+a.x1)/2, 0)
check("A centred in Y", (a.y0+a.y1)/2, 0)
check("B centred in X", (r.x0+r.x1)/2, 0)
check("B centred in Y", (r.y0+r.y1)/2, 0)
check("both sit on the plate", a.z0, 2)
check("B sits on the plate too", r.z0, 2)
check("same thickness", (r.z1-r.z0)-(a.z1-a.z0), 0)
local p = extent(b, function(x) return x.tag=="cube" end)
print("plate     " .. fmt(p))
check("plate margin left", a.x0-p.x0, 6)
check("plate margin right", p.x1-a.x1, 6)
check("plate under text", p.z1, 2)

-- mirror mode: the reflected copy must land on the plate, not below it
local m = run((function() local t={} for k,v in pairs(base) do t[k]=v end t.mirror=true return t end)())
local mr = extent(m, function(x) return x.rot end)
print("mirrored  " .. fmt(mr))
check("mirrored copy on the plate", mr.z0, 2)
check("mirrored copy same height", mr.z1, 6)
check("mirrored centred in X", (mr.x0+mr.x1)/2, 0)
check("mirrored centred in Y", (mr.y0+mr.y1)/2, 0)

-- two different words
local d = run((function() local t={} for k,v in pairs(base) do t[k]=v end t.text_b="Emma" return t end)())
check("second word present", extent(d,function(x) return x.tag=="text:Emma" end) and 1 or 0, 1)
local d2 = extent(d, function(x) return x.tag=="text:Emma" end)
check("second word centred", (d2.x0+d2.x1)/2, 0)

-- keyring: hole must be inside the plate, clear of the text
local k = run((function() local t={} for k2,v in pairs(base) do t[k2]=v end t.keyring=true return t end)())
local kp = extent(k, function(x) return x.tag=="cube" end)
local kh = extent(k, function(x) return x.type=="Negative" end)
local kt = extent(k, function(x) return x.tag=="text:Anna" and not x.rot end)
print("plate     " .. fmt(kp) .. "\nhole      " .. fmt(kh))
check("hole inside plate (left)", kh.x0-kp.x0, 2.5)
check("hole clear of text", kt.x0-kh.x1, 2.5 + 6)
check("hole passes through", kh.z1-kh.z0, 4)

-- no plate: text must sit on the bed
local n = run((function() local t={} for k2,v in pairs(base) do t[k2]=v end t.base_plate=false return t end)())
local na = extent(n, function(x) return not x.rot end)
check("no plate: text on bed", na.z0, 0)
done()
