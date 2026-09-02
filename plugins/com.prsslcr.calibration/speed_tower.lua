-- Speed Tower -- findet die höchste Druckgeschwindigkeit ohne Qualitätsverlust.
--
-- Anders als beim Fan Tower ist Geschwindigkeit kein Firmware-Zustand, sondern
-- eine Slicer-Einstellung. Sie wird deshalb nicht per G-Code geschaltet, sondern
-- über Modifier-Volumes gesetzt, die pro Höhenband die Speed-Parameter
-- überschreiben -- dasselbe Verfahren, das Prusas Flow Tower verwendet.

local labels = require('labels')

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

function execute(opts)
    local steps = math.max(2, opts.steps)
    local step_height = opts.step_height
    local size = opts.size
    local total_height = step_height * steps

    local bed = api.project:current_bed()

    -- Wenige Wände und offener Innenraum: so entscheidet die Geschwindigkeit
    -- über das Ergebnis und nicht die Anzahl der Perimeter.
    bed:print_presets():set("fill_density", "0%")
    bed:print_presets():set("perimeters", 2)
    bed:print_presets():set("top_solid_layers", 0)
    bed:print_presets():set("bottom_solid_layers", 3)

    local other_volumes = {}
    local speed_span = opts.max_speed - opts.min_speed

    for i = 1, steps do
        local band_z = step_height * (i - 1)
        local speed = opts.min_speed + speed_span * (i - 1) / (steps - 1)

        -- Der Modifier deckt genau ein Höhenband ab und setzt dort die Speeds.
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
