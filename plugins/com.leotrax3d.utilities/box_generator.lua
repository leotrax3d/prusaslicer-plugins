-- Parametric Box Generator -- storage boxes, drawer inserts and organiser trays.
--
-- Builds a box from its *inside* dimensions, because that is what you actually
-- know: the thing you want to put in it. Walls, floor and lid are added outside
-- those numbers, so raising the wall thickness never shrinks the usable space.
--
-- Everything is procedural geometry. No settings are changed and no G-code is
-- injected, which makes this the one plugin here that cannot be undermined by
-- the slicer recomputing something per layer.

info = {
    id = "box_generator",
    type = "project.plugin",
    title = "Box Generator",
    menu = "Generators/Parametric Box",
    params = {
        {name = "inner_width",   label = "Inner Width [mm]",        type = "float",  default = 80},
        {name = "inner_depth",   label = "Inner Depth [mm]",        type = "float",  default = 60},
        {name = "inner_height",  label = "Inner Height [mm]",       type = "float",  default = 40},
        {name = "wall",          label = "Wall Thickness [mm]",     type = "float",  default = 2.0},
        {name = "floor_th",      label = "Floor Thickness [mm]",    type = "float",  default = 1.6},
        {name = "corner_radius", label = "Corner Radius [mm]",      type = "float",  default = 3.0},
        {name = "columns",       label = "Compartments Across",     type = "int",    default = 1},
        {name = "rows",          label = "Compartments Deep",       type = "int",    default = 1},
        {name = "divider_th",    label = "Divider Thickness [mm]",  type = "float",  default = 1.6},
        {name = "divider_pct",   label = "Divider Height [%]",      type = "int",    default = 100},
        {name = "stackable",     label = "Stacking Groove",         type = "bool",   default = false},
        {name = "finger_notch",  label = "Finger Notch",            type = "bool",   default = false},
        {name = "with_lid",      label = "Generate Lid",            type = "bool",   default = false},
        {name = "lid_height",    label = "Lid Height [mm]",         type = "float",  default = 8},
        {name = "clearance",     label = "Fit Clearance [mm]",      type = "float",  default = 0.25},
        {name = "label",         label = "Front Label",             type = "string", default = ""}
    }
}

local PART_GAP = 12.0    -- space between the box and the lid on the bed [mm]
local GROOVE_INSET = 0.5 -- how far the stacking groove sits in from the outer face [mm]
local GROOVE_DEPTH = 1.6 -- nominal groove depth, reduced if the floor is thin [mm]
local BREAK = 1.0        -- overshoot so a cut passes cleanly through a face [mm]

-- Required inside execute(): the scan pass that reads `info` runs each file in a
-- bare Lua engine with neither `api` nor the slicer's custom require, so a
-- top-level require would silently cost this plugin its menu entry.
function execute(opts)
    local shapes = require('shapes')
    local labels = require('labels')

    local wall = math.max(0.4, opts.wall)
    local floor_th = math.max(0.2, opts.floor_th)
    local clearance = math.max(0, opts.clearance)

    local iw, id, ih = opts.inner_width, opts.inner_depth, opts.inner_height
    local ow, od = iw + 2 * wall, id + 2 * wall
    local oh = ih + floor_th

    -- The outer radius is what the user asked for; the cavity follows it inwards
    -- so the wall keeps a constant thickness around the corner.
    local outer_r = math.max(0, opts.corner_radius)
    local inner_r = math.max(0, outer_r - wall)

    local box = shapes.builder()

    -- Shell, then cavity. Order matters: the Negative only cuts what precedes it.
    box:add_slab(shapes.rounded_slab(ow, od, oh, outer_r))
    box:add_slab(
        shapes.rounded_slab(iw, id, ih + BREAK, inner_r),
        { x = wall, y = wall, z = floor_th },
        VolumeType.Negative
    )

    -- A stacking groove: a pocket around the underside that the walls of the box
    -- below drop into. There is no ring primitive and no boolean intersection, so
    -- it is cut as a full pocket and the middle is put back as a later Solid.
    if opts.stackable then
        local depth = math.min(GROOVE_DEPTH, floor_th - 0.6)
        local ring = wall + clearance
        local island_w = ow - 2 * (GROOVE_INSET + ring)
        local island_d = od - 2 * (GROOVE_INSET + ring)

        if depth > 0.2 and island_w > 2 and island_d > 2 then
            box:add_slab(
                shapes.rounded_slab(ow - 2 * GROOVE_INSET, od - 2 * GROOVE_INSET,
                                    depth + BREAK, math.max(0, outer_r - GROOVE_INSET)),
                { x = GROOVE_INSET, y = GROOVE_INSET, z = -BREAK },
                VolumeType.Negative
            )
            box:add_slab(
                shapes.rounded_slab(island_w, island_d, depth,
                                    math.max(0, outer_r - GROOVE_INSET - ring)),
                { x = GROOVE_INSET + ring, y = GROOVE_INSET + ring, z = 0 }
            )
        end
    end

    -- A half-round bite out of the top of the front wall, to get a finger in.
    -- rotate{x = 90} turns the cylinder's axis from Z to -Y, so the body spans
    -- y = [translate.y - length, translate.y] and its local Y extent becomes Z.
    if opts.finger_notch then
        local nr = math.min(10, iw * 0.3)
        if nr > 1 and ih > nr * 0.5 then
            local mesh = api.make_cylinder(nr, wall + 2 * BREAK)
            local b = mesh:bounds()
            box:add {
                mesh = mesh,
                type = VolumeType.Negative,
                rotate = { x = 90 },
                x = ow * 0.5 - (b.max_x - b.min_x) * 0.5 - b.min_x,
                y = wall + BREAK,
                z = oh - (b.max_y - b.min_y) * 0.5 - b.min_y
            }
        end
    end

    if opts.label ~= "" then
        local size = math.max(3, math.min(8, oh * 0.3))
        box:add_definition(labels.front_label {
            text = opts.label,
            center_x = ow * 0.5,
            center_z = math.min(oh * 0.4, oh - size),
            face_y = 0,
            size = size
        })
    end

    -- Dividers come after the cavity, so they survive it. Partial-height dividers
    -- let you sweep the whole tray out in one go while still keeping things apart.
    local dt = math.max(0.4, opts.divider_th)
    local dh = ih * math.max(5, math.min(100, opts.divider_pct)) / 100
    local columns = math.max(1, opts.columns)
    local rows = math.max(1, opts.rows)

    for i = 1, columns - 1 do
        box:add {
            mesh = api.make_cube(dt, id, dh),
            x = wall + iw * i / columns - dt * 0.5,
            y = wall,
            z = floor_th
        }
    end

    for j = 1, rows - 1 do
        box:add {
            mesh = api.make_cube(iw, dt, dh),
            x = wall,
            y = wall + id * j / rows - dt * 0.5,
            z = floor_th
        }
    end

    box:emit({ x = 0, y = 0, z = 0 })

    -- The lid is a shallow tray that slips over the box, generated open side up
    -- so it prints without support in the orientation it arrives in.
    if opts.with_lid then
        local lw = ow + 2 * (clearance + wall)
        local ld = od + 2 * (clearance + wall)
        local lh = math.max(floor_th + 1, opts.lid_height)
        local lid_r = outer_r + wall + clearance

        local lid = shapes.builder()
        lid:add_slab(shapes.rounded_slab(lw, ld, lh, lid_r))
        lid:add_slab(
            shapes.rounded_slab(ow + 2 * clearance, od + 2 * clearance, lh, outer_r + clearance),
            { x = wall, y = wall, z = floor_th },
            VolumeType.Negative
        )

        -- On the front face, not the top: the lid is generated upside down, so
        -- anything engraved into its top surface would come out mirrored once the
        -- lid is turned over. A vertical face has no such handedness.
        if opts.label ~= "" then
            local size = math.max(3, math.min(8, lh * 0.4))
            lid:add_definition(labels.front_label {
                text = opts.label,
                center_x = lw * 0.5,
                center_z = lh * 0.5,
                face_y = 0,
                size = size
            })
        end

        lid:emit({ x = 0, y = od + PART_GAP, z = 0 })
    end
end
