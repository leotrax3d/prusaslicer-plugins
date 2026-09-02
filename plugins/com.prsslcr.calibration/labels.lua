-- Gemeinsame Helfer zum Beschriften von Kalibrier-Objekten.
--
-- Beschriftungen werden als VolumeType.Negative gesetzt, also in die Oberfläche
-- graviert. Zwei Annahmen stecken hier drin, die wir noch nicht am laufenden
-- Slicer verifiziert haben (siehe docs/api-notes.md):
--
--   1. api.emboss_text erzeugt die Glyphen in der XY-Ebene, extrudiert nach +Z.
--   2. `rotate` wird um den lokalen Ursprung des Volumes angewendet, und zwar
--      vor `translate`.
--
-- Sollte sich das als falsch herausstellen, muss nur diese Datei angepasst
-- werden -- alle Plugins beschriften ausschließlich hierüber.

local M = {}

--- Graviert Text in die Oberseite eines Objekts.
-- Braucht keine Rotation und ist daher der robustere der beiden Wege.
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
            -- Der Körper liegt in [z, z + depth]; er soll die Oberseite treffen.
            z = opts.top_z - depth
        }
    }
end

--- Graviert Text in die Vorderseite (kleinstes Y) eines Objekts.
-- Nach rotate{x = 90} zeigt die lokale Y-Achse nach +Z und die Extrusion nach -Y.
-- Der Körper liegt danach in y = [translate.y - depth, translate.y], soll aber
-- ab der Fläche nach innen schneiden -- daher translate.y = face_y + depth.
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

--- Formatiert eine Zahl kurz und ohne überflüssige Nullen.
function M.fmt(value, decimals)
    local s = string.format("%." .. (decimals or 2) .. "f", value)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

return M
