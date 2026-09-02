-- Shared geometry helpers.
--
-- Two things here are worth knowing before using them.
--
-- Boolean ordering. PrusaSlicer applies volumes in list order: a Negative
-- subtracts from everything before it, and a Solid added afterwards is put back.
-- That ordering is the only boolean tool the API gives us -- there is no
-- intersection -- so shapes like a ring or a grooved base are built as
-- "cut a pocket, then restore the island in the middle".
--
-- Object origins. add_object takes a single `mesh` plus `other_volumes`, and the
-- main mesh has no translate of its own; only the object does. The builder below
-- works in one flat object space and, on emit, shifts the object so the first
-- volume lands where it should. Nothing has to assume where a primitive puts its
-- origin, and Mesh:translate -- whose semantics this project has not verified --
-- is not needed.

local M = {}

--- Places a cylinder by its bounding box rather than its assumed origin.
-- make_cylinder's origin is one of the open questions in DEVINFO.md, so every
-- cylinder in this bundle goes through here.
--@return table mesh plus x/y/z, ready for builder:add
function M.cylinder_at(radius, height, cx, cy, z0)
    local mesh = api.make_cylinder(radius, height)
    local b = mesh:bounds()
    return {
        mesh = mesh,
        x = cx - (b.min_x + b.max_x) * 0.5,
        y = cy - (b.min_y + b.max_y) * 0.5,
        z = z0 - b.min_z
    }
end

--- A rectangular slab with rounded vertical corners, as a list of solid pieces.
-- Built as two overlapping bars in a cross plus four corner cylinders, which is
-- a union and therefore expressible with Solid volumes alone. Spans
-- [0,w] x [0,d] x [0,h] in object space.
--@param r number corner radius; <= 0.05 yields a plain cube
--@return table list of {mesh, x, y, z}
function M.rounded_slab(w, d, h, r)
    r = math.min(r or 0, w * 0.5, d * 0.5)

    if r <= 0.05 then
        return { { mesh = api.make_cube(w, d, h), x = 0, y = 0, z = 0 } }
    end

    local pieces = {
        { mesh = api.make_cube(w, d - 2 * r, h), x = 0, y = r, z = 0 },
        { mesh = api.make_cube(w - 2 * r, d, h), x = r, y = 0, z = 0 }
    }

    for _, c in ipairs({ { r, r }, { w - r, r }, { r, d - r }, { w - r, d - r } }) do
        pieces[#pieces + 1] = M.cylinder_at(r, h, c[1], c[2], 0)
    end

    return pieces
end

--- Collects volumes in object space and emits them as one object.
local Builder = {}
Builder.__index = Builder

function M.builder()
    return setmetatable({ volumes = {} }, Builder)
end

--- Adds a volume. The first one added becomes the object's main mesh, so it must
-- be solid and unrotated -- a slab piece, never a label or a cut.
--@param opts table mesh, x?, y?, z?, type?, rotate?, params?
function Builder:add(opts)
    self.volumes[#self.volumes + 1] = {
        mesh = opts.mesh,
        x = opts.x or 0,
        y = opts.y or 0,
        z = opts.z or 0,
        type = opts.type,
        rotate = opts.rotate,
        params = opts.params
    }
    return self
end

--- Adds a ready-made VolumeDefinition, as returned by labels.lua.
function Builder:add_definition(def)
    local t = def.translate or {}
    return self:add {
        mesh = def.mesh,
        x = t.x or 0, y = t.y or 0, z = t.z or 0,
        type = def.type, rotate = def.rotate, params = def.params
    }
end

--- Adds each piece of a rounded_slab, offset to `at` and sharing one type.
function Builder:add_slab(pieces, at, vtype)
    at = at or {}
    for _, p in ipairs(pieces) do
        self:add {
            mesh = p.mesh,
            x = p.x + (at.x or 0),
            y = p.y + (at.y or 0),
            z = p.z + (at.z or 0),
            type = vtype
        }
    end
    return self
end

--- Emits the collected volumes as a single object placed at `pos`.
-- The first volume carries the object; every other translate is expressed
-- relative to it, which keeps all the arithmetic above in one flat space.
function Builder:emit(pos, object_params)
    pos = pos or {}
    local first = self.volumes[1]
    local others = {}

    for i = 2, #self.volumes do
        local v = self.volumes[i]
        others[#others + 1] = {
            mesh = v.mesh,
            type = v.type,
            rotate = v.rotate,
            params = v.params,
            translate = { x = v.x - first.x, y = v.y - first.y, z = v.z - first.z }
        }
    end

    api.project:add_object {
        mesh = first.mesh,
        translate = {
            x = (pos.x or 0) + first.x,
            y = (pos.y or 0) + first.y,
            z = (pos.z or 0) + first.z
        },
        other_volumes = others,
        object_params = object_params
    }
end

return M
