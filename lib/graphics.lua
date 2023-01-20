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

local function _polygon(props)
    local faces = props.faces

    local pts = poly_points(props)

    for i = 1,faces do
        _edge{ points = pts, n = i, level = props.level }
    end
end

local _recur_poly
do
    local r_limit_lower = 3
    local r_limit_upper = 256

    local function draw(direction, faces, x, y, fb_vc, outer_r, outer_rate, outer_lvl)
        local inner_r = direction<0 and (
            outer_r * math.sin(TAU / 12)
        ) or (
            outer_r / math.sin(TAU / 12)
        )

        if inner_r >= r_limit_lower and inner_r <= r_limit_upper then
            local inner_rate = outer_rate * (get_rate(fb_vc) / get_rate(3))
            local inner_lvl = outer_lvl * outer_lvl

            _polygon{
                faces = faces, x = x, y = y, r = inner_r, level = util.round(inner_lvl * 5),
                rotation = TAU * (1 - tick_tri) * inner_rate,
            }

            draw(direction, faces, x, y, fb_vc, inner_r, inner_rate, inner_lvl)
        end
    end

    _recur_poly = function(props)
        draw(
            props.direction, props.faces, props.x, props.y, 
            props.feedback_voice, props.r, 1, props.feedback
        )
    end
end


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
                local pos = get_rate(vc) > 0 and ph or 1-ph
            
                _point{ points = pts, n = head, x = pos, level = 15 }
            end
        end

        _recur_poly{
            direction = -1, faces = 3, x = 128/2, y = 64/2, r = 32, 
            feedback = 0.9, feedback_voice = 1, 
        }
        _recur_poly{
            direction = 1, faces = 3, x = 128/2, y = 64/2, r = 32, 
            feedback = 0.9, feedback_voice = 2, 
        }
    end
end

return Gfx
