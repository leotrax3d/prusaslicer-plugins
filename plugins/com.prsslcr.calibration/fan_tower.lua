-- Fan Tower -- findet die beste Bauteilkühlung.
--
-- Die Lüfterdrehzahl ist Firmware-Zustand, lässt sich also sauber pro Höhenband
-- per M106 umschalten. Neben dem Hauptturm steht eine dünne Säule: der Druckkopf
-- muss pro Schicht zwischen beiden hin- und herfahren, wodurch die Säule kaum
-- Zeit zum Abkühlen bekommt. Dort zeigt sich schlechte Kühlung zuerst.

local labels = require('labels')

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

local PILLAR_SIZE = 4.0  -- Kantenlänge der Kühl-Testsäule [mm]
local PILLAR_GAP  = 15.0 -- Abstand zwischen Turm und Säule [mm]

--- Fan-Prozent in einen G-Code-Befehl übersetzen.
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

function execute(opts)
    local steps = math.max(2, opts.steps)
    local step_height = opts.step_height
    local size = opts.size
    local total_height = step_height * steps

    local bed = api.project:current_bed()
    local layer_height = bed:print_presets():value("layer_height")

    api.project:clear_layer_custom_steps(bed)

    -- Dünne Wände und wenig Infill, damit die Kühlung sichtbar wird und nicht
    -- die Wandstärke das Ergebnis dominiert.
    bed:print_presets():set("fill_density", "10%")
    bed:print_presets():set("perimeters", 2)
    bed:print_presets():set("top_solid_layers", 3)
    bed:print_presets():set("bottom_solid_layers", 3)

    local other_volumes = {}

    -- Die Kühl-Testsäule als zweites Volume desselben Objekts.
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

        -- Erst eine Schicht oberhalb des Bandanfangs schalten, damit der Wechsel
        -- nicht schon in die letzte Schicht des vorherigen Bands fällt.
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
