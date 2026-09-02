-- Fan Tower -- finds the right amount of part cooling.
--
-- Fan speed is firmware state, so it can be stepped cleanly per height band with
-- M106. A thin pillar stands beside the main tower: the head has to travel
-- between the two every layer, leaving the pillar almost no time to cool. That is
-- where insufficient cooling shows up first.

info = {
    id = "fan_tower",
    type = "project.plugin",
    title = "Fan Tower",
    menu = "Calibration/Fan Tower",
    params = {
        {name = "min_fan",       label = "Min Fan Speed  [%]", type = "int",   default = 0},
        {name = "max_fan",       label = "Max Fan Speed  [%]", type = "int",   default = 100},
        {name = "steps",         label = "Num Steps",          type = "int",   default = 5},
        {name = "step_height",   label = "Step Height  [mm]",  type = "float", default = 8},
        {name = "size",          label = "Tower Size  [mm]",   type = "float", default = 20},
        {name = "enable_labels", label = "Engrave Labels",     type = "bool",  default = true}
    }
}

local PILLAR_SIZE = 4.0  -- edge length of the cooling test pillar [mm]
local PILLAR_GAP  = 15.0 -- gap between tower and pillar [mm]

--- Translates a fan percentage into a G-code command.
local function fan_gcode(percent)
    local pwm = math.floor(percent * 255 / 100 + 0.5)
    if pwm <= 0 then
        return "M107"
    end
    if pwm > 255 then
        pwm = 255
    end
    return "M106 S" .. pwm
end

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
    local layer_height = bed:print_presets():value("layer_height")

    api.project:clear_layer_custom_steps(bed)

    -- Thin walls and light infill, so cooling drives the result rather than
    -- wall thickness masking it.
    bed:print_presets():set("fill_density", "10%")
    bed:print_presets():set("perimeters", 2)
    bed:print_presets():set("top_solid_layers", 3)
    bed:print_presets():set("bottom_solid_layers", 3)

    local other_volumes = {}

    -- The cooling test pillar, as a second volume of the same object.
    table.insert(other_volumes, {
        mesh = api.make_cube(PILLAR_SIZE, PILLAR_SIZE, total_height),
        translate = {
            x = size + PILLAR_GAP,
            y = (size - PILLAR_SIZE) * 0.5
        }
    })

    local fan_span = opts.max_fan - opts.min_fan

    for i = 1, steps do
        local band_z = step_height * (i - 1)
        local fan = opts.min_fan + fan_span * (i - 1) / (steps - 1)
        local rounded_fan = math.floor(fan + 0.5)

        -- Switch one layer above the band start, so the change does not land in
        -- the last layer of the preceding band.
        api.project:insert_layer_custom_gcode(bed, band_z + layer_height, fan_gcode(rounded_fan))

        if opts.enable_labels then
            table.insert(other_volumes, labels.front_label {
                text = rounded_fan,
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
            fill_density = "10%"
        }
    }
end
