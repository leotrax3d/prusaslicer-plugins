-- Ambigram Generator -- a word that stays readable when you turn it around.
--
-- This builds an *overlay* ambigram: the plate carries both readings physically,
-- one laid on top of the other, unioned into a single shape. Turn it 180 degrees
-- and the second word is the one your eye picks out. Choose "Mirror" and the
-- word is overlaid with its own reflection instead, so it reads correctly in a
-- mirror.
--
-- What this deliberately is not: the dual-view sculpture where two different
-- words are extruded along perpendicular axes and *intersected*, so each viewing
-- direction shows one word and nothing else. That needs boolean intersection.
-- The plugin API offers Solid and Negative volumes -- union and difference -- and
-- no way to read a mesh's geometry back, so the intersection cannot be built or
-- approximated. See DEVINFO.md.
--
-- Nor is it the hand-drawn kind, where each glyph is redesigned to read as a
-- different letter upside down. That is glyph design, not geometry.
--
-- Overlay ambigrams work best on short words in a heavy, wide font, where the
-- two readings share most of their strokes. Long words in a thin font give a
-- tangle. Try a few fonts -- it costs one dialog.

info = {
    id = "ambigram",
    type = "project.plugin",
    title = "Ambigram",
    menu = "Generators/Ambigram",
    params = {
        {name = "text_a",      label = "Text",                     type = "string", default = "Ambigram"},
        {name = "text_b",      label = "Second Text (blank = same)", type = "string", default = ""},
        {name = "mirror",      label = "Mirror instead of Rotate", type = "bool",   default = false},
        {name = "font_name",   label = "Font (blank = default)",   type = "string", default = ""},
        {name = "text_size",   label = "Text Height [mm]",         type = "float",  default = 20},
        {name = "text_depth",  label = "Text Depth [mm]",          type = "float",  default = 4},
        {name = "base_plate",  label = "Base Plate",               type = "bool",   default = true},
        {name = "plate_th",    label = "Plate Thickness [mm]",     type = "float",  default = 2},
        {name = "plate_margin",label = "Plate Margin [mm]",        type = "float",  default = 6},
        {name = "keyring",     label = "Keyring Hole",             type = "bool",   default = false}
    }
}

local KEYRING_R = 2.5    -- hole radius, sized for a split ring [mm]
local KEYRING_WEB = 2.5  -- material left around the hole [mm]
local BREAK = 1.0        -- overshoot so the hole passes cleanly through [mm]

function execute(opts)
    local shapes = require('shapes')

    -- api.get_font raises on an unknown name rather than returning nil, so an
    -- unrecognised font falls back instead of killing the whole run.
    local font = api.get_default_font()
    if opts.font_name ~= "" then
        local ok, requested = pcall(api.get_font, opts.font_name)
        if ok and requested then font = requested end
    end

    local depth = math.max(0.4, opts.text_depth)
    local size = math.max(2, opts.text_size)

    local function emboss(text)
        return api.emboss_text {
            font = font,
            text = text,
            depth = depth,
            line_height = size
        }
    end

    local text_b = opts.text_b ~= "" and opts.text_b or opts.text_a
    local mesh_a, mesh_b = emboss(opts.text_a), emboss(text_b)
    local ba, bb = mesh_a:bounds(), mesh_b:bounds()

    -- Both readings are centred on the origin, which is what makes them overlay:
    -- rotating the finished plate about its centre maps one onto the other.
    local span_x = math.max(ba.max_x - ba.min_x, bb.max_x - bb.min_x)
    local span_y = math.max(ba.max_y - ba.min_y, bb.max_y - bb.min_y)

    local margin = math.max(0, opts.plate_margin)
    local plate_th = opts.base_plate and math.max(0.2, opts.plate_th) or 0
    local tab = opts.keyring and (2 * KEYRING_R + 2 * KEYRING_WEB) or 0

    local art = shapes.builder()

    if opts.base_plate then
        local pw = span_x + 2 * margin + tab
        local pd = span_y + 2 * margin
        -- The keyring tab is added on the left, so the text stays centred on the
        -- plate's text area rather than on the plate including its tab.
        art:add {
            mesh = api.make_cube(pw, pd, plate_th),
            x = -(span_x * 0.5 + margin + tab),
            y = -pd * 0.5,
            z = 0
        }

        if opts.keyring then
            local hole = shapes.cylinder_at(
                KEYRING_R, plate_th + 2 * BREAK,
                -(span_x * 0.5 + margin + tab) + tab * 0.5, 0, -BREAK)
            art:add {
                mesh = hole.mesh, x = hole.x, y = hole.y, z = hole.z,
                type = VolumeType.Negative
            }
        end
    end

    -- First reading, as it comes out of emboss_text.
    art:add {
        mesh = mesh_a,
        x = -(ba.min_x + ba.max_x) * 0.5,
        y = -(ba.min_y + ba.max_y) * 0.5,
        z = plate_th - ba.min_z
    }

    -- Second reading, overlaid. `rotate` is applied about the volume's local
    -- origin before `translate`, so the rotated mesh sits at the negated
    -- position of its own centre; adding that centre back re-centres it.
    if opts.mirror then
        -- rotate{y = 180} maps (x, y, z) -> (-x, y, -z): mirrored across X, and
        -- flipped in Z, hence the max_z rather than min_z below.
        art:add {
            mesh = mesh_b,
            rotate = { y = 180 },
            x = (bb.min_x + bb.max_x) * 0.5,
            y = -(bb.min_y + bb.max_y) * 0.5,
            z = plate_th + bb.max_z
        }
    else
        -- rotate{z = 180} maps (x, y, z) -> (-x, -y, z): the 180 degree turn.
        art:add {
            mesh = mesh_b,
            rotate = { z = 180 },
            x = (bb.min_x + bb.max_x) * 0.5,
            y = (bb.min_y + bb.max_y) * 0.5,
            z = plate_th - bb.min_z
        }
    end

    art:emit({ x = 0, y = 0, z = 0 })
end
