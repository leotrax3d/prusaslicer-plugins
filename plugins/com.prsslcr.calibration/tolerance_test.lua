-- Tolerance Test -- determines the fit allowance your parts need.
--
-- Produces a plate with a row of holes, each one a different amount larger than
-- the test pin printed alongside it. After printing, work along the row to find
-- the first hole the pin seats cleanly in; that clearance is what your own
-- designs need for this printer and this filament.
--
-- Pure geometry: no G-code tricks and no setting changes mid-print.

local labels = require('labels')

info = {
    id = "tolerance_test",
    type = "project.plugin",
    title = "Tolerance Test",
    menu = "Calibration/Tolerance Test",
    params = {
        {name = "pin_diameter",  label = "Pin Diameter  [mm]",  type = "float", default = 6},
        {name = "min_clearance", label = "Min Clearance  [mm]", type = "float", default = 0.0},
        {name = "max_clearance", label = "Max Clearance  [mm]", type = "float", default = 0.5},
        {name = "steps",         label = "Num Steps",           type = "int",   default = 6},
        {name = "thickness",     label = "Plate Thickness [mm]",type = "float", default = 6},
        {name = "enable_labels", label = "Engrave Labels",      type = "bool",  default = true}
    }
}

local MARGIN = 4.0      -- material margin around the holes [mm]
local LABEL_ROW = 6.0   -- depth of the label strip in front of the holes [mm]
local PIN_GAP = 10.0    -- gap between the test pin and the plate [mm]

function execute(opts)
    local steps = math.max(2, opts.steps)
    local pin_d = opts.pin_diameter
    local thickness = opts.thickness

    local pitch = pin_d + opts.max_clearance + MARGIN
    local plate_w = pitch * steps
    local plate_d = pin_d + opts.max_clearance + MARGIN * 2 + LABEL_ROW
    local hole_cy = LABEL_ROW + (plate_d - LABEL_ROW) * 0.5

    local bed = api.project:current_bed()

    -- Print solid: for a fit test the hole wall must not flex, otherwise you
    -- measure infill density rather than tolerance.
    bed:print_presets():set("fill_density", "100%")
    bed:print_presets():set("perimeters", 3)

    local other_volumes = {}
    local clearance_span = opts.max_clearance - opts.min_clearance

    for i = 1, steps do
        local clearance = opts.min_clearance + clearance_span * (i - 1) / (steps - 1)
        local hole_cx = pitch * (i - 0.5)

        -- Overhang both ends slightly so the cut passes cleanly through.
        table.insert(other_volumes, {
            mesh = api.make_cylinder((pin_d + clearance) * 0.5, thickness + 2),
            type = VolumeType.Negative,
            translate = { x = hole_cx, y = hole_cy, z = -1 }
        })

        if opts.enable_labels then
            table.insert(other_volumes, labels.top_label {
                text = labels.fmt(clearance, 2),
                center_x = hole_cx,
                center_y = LABEL_ROW * 0.5,
                top_z = thickness,
                size = 3.5
            })
        end
    end

    api.project:add_object {
        mesh = api.make_cube(plate_w, plate_d, thickness),
        other_volumes = other_volumes,
        object_params = {
            fill_density = "100%"
        }
    }

    -- The test pin as its own object, so it prints loose beside the plate.
    api.project:add_object {
        mesh = api.make_cylinder(pin_d * 0.5, thickness * 2),
        translate = { x = plate_w * 0.5, y = -(plate_d * 0.5 + PIN_GAP) },
        object_params = {
            fill_density = "100%"
        }
    }
end
