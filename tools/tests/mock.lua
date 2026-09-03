-- A mock of the slicer's Lua API, enough to check placement arithmetic.
--
-- Primitives return bounding boxes rather than meshes, and the mock deliberately
-- gives them awkward origins: the cylinder is centred in XY, the cube is not, and
-- emboss_text starts at a non-zero offset. Anything that assumes where a
-- primitive puts its origin therefore fails here, which is the point -- those
-- origins are an open question in DEVINFO.md and the plugins position everything
-- from Mesh:bounds() instead.
--
-- world_boxes() replays the volume list the way the slicer would: `rotate` about
-- the volume's local origin, then `translate`, then the object's own translate.
package.path = "plugins/com.leotrax3d.utilities/?.lua;" .. package.path
VolumeType = {Solid="Solid", Negative="Negative", Modifier="Modifier"}

local function mesh(minx,maxx,miny,maxy,minz,maxz,tag)
    return {tag=tag, bounds=function(self)
        return {min_x=minx,max_x=maxx,min_y=miny,max_y=maxy,min_z=minz,max_z=maxz} end}
end

objects = {}
api = {
    make_cube = function(w,d,h) return mesh(0,w,0,d,0,h,"cube") end,
    -- deliberately NOT centred, to prove nothing assumes a centred cylinder
    make_cylinder = function(r,h) return mesh(-r,r,-r,r,0,h,"cyl") end,
    get_default_font = function() return "font" end,
    get_font = function(n) error("no font "..n) end,
    emboss_text = function(o)
        local w = #o.text * o.line_height * 0.6
        -- offset origin on purpose: real emboss_text is not guaranteed centred
        return mesh(3, 3+w, -1, -1+o.line_height, 0, o.depth, "text:"..o.text)
    end,
    project = {
        add_object = function(_, o) objects[#objects+1] = o end
    }
}
api.project.add_object = function(self, o) objects[#objects+1] = o end

-- world-space AABB of every volume of an object, by type
function world_boxes(obj)
    local t = obj.translate or {}
    local out = {}
    local function push(m, tr, ty, rot)
        local b = m:bounds()
        local x0,x1,y0,y1,z0,z1 = b.min_x,b.max_x,b.min_y,b.max_y,b.min_z,b.max_z
        if rot and rot.z == 180 then x0,x1,y0,y1 = -x1,-x0,-y1,-y0 end
        if rot and rot.y == 180 then x0,x1,z0,z1 = -x1,-x0,-z1,-z0 end
        if rot and rot.x == 90  then
            local ny0,ny1 = -z1,-z0
            local nz0,nz1 = y0,y1
            y0,y1,z0,z1 = ny0,ny1,nz0,nz1
        end
        tr = tr or {}
        out[#out+1] = {tag=m.tag, type=ty or "Solid", rot=rot,
            x0=x0+(tr.x or 0)+(t.x or 0), x1=x1+(tr.x or 0)+(t.x or 0),
            y0=y0+(tr.y or 0)+(t.y or 0), y1=y1+(tr.y or 0)+(t.y or 0),
            z0=z0+(tr.z or 0)+(t.z or 0), z1=z1+(tr.z or 0)+(t.z or 0)}
    end
    push(obj.mesh, nil, "Solid", nil)
    for _,v in ipairs(obj.other_volumes or {}) do push(v.mesh, v.translate, v.type, v.rotate) end
    return out
end

function extent(boxes, pred)
    local r
    for _,b in ipairs(boxes) do
        if pred(b) then
            r = r or {x0=b.x0,x1=b.x1,y0=b.y0,y1=b.y1,z0=b.z0,z1=b.z1}
            r.x0=math.min(r.x0,b.x0); r.x1=math.max(r.x1,b.x1)
            r.y0=math.min(r.y0,b.y0); r.y1=math.max(r.y1,b.y1)
            r.z0=math.min(r.z0,b.z0); r.z1=math.max(r.z1,b.z1)
        end
    end
    return r
end

function fmt(r) return string.format("x[%.2f,%.2f] y[%.2f,%.2f] z[%.2f,%.2f]",
    r.x0,r.x1,r.y0,r.y1,r.z0,r.z1) end

local fails = 0
function check(name, got, want, tol)
    tol = tol or 1e-6
    local ok = math.abs(got-want) <= tol
    if not ok then fails = fails + 1 end
    print(string.format("%s %-46s got %.3f  want %.3f", ok and "ok  " or "FAIL", name, got, want))
end
function done() os.exit(fails == 0 and 0 or 1) end
