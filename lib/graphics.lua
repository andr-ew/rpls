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

    local function draw(ratio, faces, x, y, outer_r, outer_rate, outer_lvl)
        local inner_r = math.abs(ratio) > 1 and (
            outer_r * math.sin(TAU / 12)
        ) or (
            outer_r / math.sin(TAU / 12)
        )

        if inner_r >= r_limit_lower and inner_r <= r_limit_upper then
            local inner_rate = outer_rate * ratio
            local inner_lvl = outer_lvl * outer_lvl

            _polygon{
                faces = faces, x = x, y = y, r = inner_r, level = util.round(inner_lvl * 5),
                rotation = TAU * (1 - tick_tri) * inner_rate,
            }

            draw(ratio, faces, x, y, inner_r, inner_rate, inner_lvl)
        end
    end

    _recur_poly = function(props)
        draw(
            props.ratio, props.faces, props.x, props.y, 
            props.r, 1, props.feedback
        )
    end
end

local function Capture()
    local count = 1
    local done = false

    local dir = '/home/we/dust/'..norns.state.shortname..'_capture_'..os.time()..'/'
    if not util.file_exists(dir) then
        util.make_dir(dir)
    end

    return function(props)
        if crops.device == 'screen' and crops.mode == 'redraw' then
            if props.cond and not done then
                _norns.screen_export_png(dir..'frame'..string.format('%.4i', count)..'.png')
                count = count + 1
            elseif not done then
                print('PNG sequence written to '..dir..' !')
                print([[
                    after you've converted with norns-convert_screenshots.bash, use gifski to convert frames to gif:

                    gifski --fps 30 -o clip.gif frame*.png
                ]])
                done = true
            end
        end
    end
end

local function Gfx()
    -- local _cap = Capture()

    return function()
        local pts = poly_points{
            faces = 3, x = 128/2, y = 64/2, r = 32, 
            --rotation = TAU * (1 - tick_tri),
            rotation = TAU * (1 - 0.4/3),
        }

        for vc = 1,3 do
            local head = 3 - ({ 3, 1, 2 })[vc] + 1

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
                local head = 3 - ({ 3, 1, 2 })[vc] + 1
                local st = loop_points[head][1]
                local en = loop_points[head][2] + 0.14
                local ph = math.min(tick[vc] / (en - st), 1)
                local pos = get_rate(vc) > 0 and ph or 1-ph
            
                _point{ points = pts, n = head, x = 0.5, level = 15 }
            end
        end

        for i = 1,2 do 
            local fb = params:get(i..' > rec')
            local ratio = get_rate(i) / get_rate(3)

            if fb > 0 and math.abs(ratio) ~= 1 then
                _recur_poly{
                    faces = 3, x = 128/2, y = 64/2, r = 32, 
                    ratio = ratio, feedback = math.log(1 + fb, 2)
                }
            end
        end

        -- _cap{ cond = tick_tri <= 1 }
    end
end

return Gfx
