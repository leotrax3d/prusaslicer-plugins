-- Shared helpers for labelling calibration objects.
--
-- Labels are placed as VolumeType.Negative, so they are engraved into the
-- surface. Two assumptions are baked in here that have not been verified
-- against a running slicer (see DEVINFO.md, "Unverified assumptions"):
--
--   1. api.emboss_text places glyphs in the XY plane, extruded along +Z.
--   2. `rotate` is applied about the volume's local origin, before `translate`.
--
-- If either turns out to be wrong, only this file needs correcting -- every
-- plugin labels exclusively through these helpers.

local M = {}

--- Engraves text into the top face of an object.
-- Needs no rotation, making it the more robust of the two helpers.
--@param opts table text, center_x, center_y, top_z, size?, depth?, font?
--@return table VolumeDefinition
function M.top_label(opts)
    local depth = opts.depth or 0.6
    local mesh = api.emboss_text {
        font = opts.font or api.get_default_font(),
        text = tostring(opts.text),
        depth = depth,
        line_height = opts.size or 5
    }
    local b = mesh:bounds()

    return {
        mesh = mesh,
        type = VolumeType.Negative,
        translate = {
            x = opts.center_x - (b.max_x - b.min_x) * 0.5 - b.min_x,
            y = opts.center_y - (b.max_y - b.min_y) * 0.5 - b.min_y,
            -- The body spans [z, z + depth]; it must meet the top face.
            z = opts.top_z - depth
        }
    }
end

--- Engraves text into the front face (minimum Y) of an object.
-- After rotate{x = 90} the local Y axis points along +Z and the extrusion along
-- -Y. The body then spans y = [translate.y - depth, translate.y], but has to cut
-- inwards from the face, hence translate.y = face_y + depth.
--@param opts table text, center_x, center_z, face_y, size?, depth?, font?
--@return table VolumeDefinition
function M.front_label(opts)
    local depth = opts.depth or 0.6
    local mesh = api.emboss_text {
        font = opts.font or api.get_default_font(),
        text = tostring(opts.text),
        depth = depth,
        line_height = opts.size or 5
    }
    local b = mesh:bounds()

    return {
        mesh = mesh,
        type = VolumeType.Negative,
        rotate = { x = 90 },
        translate = {
            x = opts.center_x - (b.max_x - b.min_x) * 0.5 - b.min_x,
            y = opts.face_y + depth,
            z = opts.center_z - (b.max_y - b.min_y) * 0.5 - b.min_y
        }
    }
end

--- Formats a number compactly, without trailing zeros.
function M.fmt(value, decimals)
    local s = string.format("%." .. (decimals or 2) .. "f", value)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

return M
