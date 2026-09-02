-- Speed Tower -- finds the highest print speed that still holds quality.
--
-- Unlike fan speed, print speed is not firmware state but a slicer setting. It is
-- therefore not switched via G-code but applied through modifier volumes that
-- override the speed parameters per height band -- the same approach Prusa's own
-- Flow Tower uses.

info = {
    id = "speed_tower",
    type = "project.plugin",
    title = "Speed Tower",
    menu = "Calibration/Speed Tower",
    params = {
        {name = "min_speed",     label = "Min Speed  [mm/s]",  type = "float", default = 30},
        {name = "max_speed",     label = "Max Speed  [mm/s]",  type = "float", default = 150},
        {name = "steps",         label = "Num Steps",          type = "int",   default = 5},
        {name = "step_height",   label = "Step Height  [mm]",  type = "float", default = 8},
        {name = "size",          label = "Tower Size  [mm]",   type = "float", default = 20},
        {name = "enable_labels", label = "Engrave Labels",     type = "bool",  default = true}
    }
}

-- Modules are required inside execute() rather than at file level: the scan that
-- collects `info` runs each file in a bare Lua engine that has neither `api` nor
-- the custom `require`, so a top-level require aborts the file and the plugin
-- never appears in the menu. Prusa's own flow_tower.lua does the same.
function execute(opts)
    local labels = require('labels')

    local steps = math.max(2, opts.steps)
    local step_height = opts.step_height
    local size = opts.size
    local total_height = step_height * steps

    local bed = api.project:current_bed()

    -- Few perimeters and an open interior, so speed determines the result rather
    -- than the perimeter count.
    bed:print_presets():set("fill_density", "0%")
    bed:print_presets():set("perimeters", 2)
    bed:print_presets():set("top_solid_layers", 0)
    bed:print_presets():set("bottom_solid_layers", 3)

    local other_volumes = {}
    local speed_span = opts.max_speed - opts.min_speed

    for i = 1, steps do
        local band_z = step_height * (i - 1)
        local speed = opts.min_speed + speed_span * (i - 1) / (steps - 1)

        -- The modifier covers exactly one height band and sets the speeds there.
        table.insert(other_volumes, {
            mesh = api.make_cube(size, size, step_height),
            type = VolumeType.Modifier,
            translate = { z = band_z },
            params = {
                perimeter_speed = speed,
                external_perimeter_speed = speed,
                infill_speed = speed,
                solid_infill_speed = speed
            }
        })

        if opts.enable_labels then
            table.insert(other_volumes, labels.front_label {
                text = labels.fmt(speed, 0),
                center_x = size * 0.5,
                center_z = band_z + step_height * 0.5,
                face_y = 0,
                size = math.min(6, step_height * 0.6)
            })
        end
    end

    api.project:add_object {
        mesh = api.make_cube(size, size, total_height),
        other_volumes = other_volumes,
        object_params = {
            fill_density = "0%"
        }
    }
end
