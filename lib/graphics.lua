local PI, TAU = math.pi, 2 * math.pi

local function poly_points(args)
    local n = args.faces
    local c = { x = args.x, y = args.y }
    local r = args.r
    local rot = args.rotation
    
    local pts = {}
    
    for i = 1,n do
        local th = ((TAU / n) * i) + rot

        pts[i] = {
            x = (c.x + (math.cos(th) * r)) // 1,
            y = (c.y + (math.sin(th) * r)) // 1,
        }
    end

    return pts
end

local function _edge(props)
    if crops.device == 'screen' and crops.mode == 'redraw' then
        local pts = props.points
        local faces = #pts
        local i = props.n
        local nxt = i % faces + 1

        screen.line_width(1)
        screen.level(props.level)
        screen.move(pts[i].x, pts[i].y)
        screen.line(pts[nxt].x, pts[nxt].y)
        screen.stroke()
    end
end

local function _polygon(props)
    local faces = props.faces

    local pts = poly_points(props)

    for i = 1,faces do
        _edge{ points = pts, n = i, level = props.level }
    end
end

local function _point(props)
    if crops.device == 'screen' and crops.mode == 'redraw' then
        local pts = props.points
        local n = props.n
        local x = props.x

        local a, b = pts[n], pts[n % #pts + 1]
        local dx, dy = b.x - a.x, b.y - a.y

        local pt = {
            x = a.x + (x * dx),
            y = a.y + (x * dy)
        }

        screen.level(props.level)
        screen.pixel(pt.x // 1, pt.y // 1)
        screen.stroke()
    end
end
    
-- softcut.event_position(function(i, secs)
--     local st = loop_points[heads[i]][1]
--     local en = loop_points[heads[i]][2] + 0.14

--     local ph = (secs - st) / (en - st)
--     phase[i] = ph
-- end)

local function Gfx()
    return function()
        local pts = poly_points{
            faces = 3, x = 128/2, y = 64/2, r = 32, 
            rotation = TAU * (1 - tick_tri),
        }

        for vc = 1,3 do
            local head = 3 - heads[vc] + 1

                _edge{ 
                    points = pts, n = head, 
                    level = util.round(vc==3 and (
                        1 + params:get('vol rec') * 4
                    ) or (
                        3 + params:get('vol '..vc) * 2
                    ))
                }
        end

        for vc = 1,3 do
            if params:get('freeze') == 0 or vc ~= 3 then
                local head = 3 - heads[vc] + 1
                local st = loop_points[head][1]
                local en = loop_points[head][2] + 0.14
                local ph = math.min(tick[vc] / (en - st), 1)
            
                _point{ points = pts, n = head, x = ph, level = 15 }
            end
        end
    end
end

return Gfx
