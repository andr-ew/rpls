local gfx = {}

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

local function Gfx()
    return function()
        local pts = poly_points{
            faces = 3, x = 128/2, y = 64/2, r = 32, rotation = TAU * 1.3/3,
        }

        for i = 1,3 do
            _edge{ points = pts, n = i, level = i==3 and 1 or 4 }
        end

        _point{ points = pts, n = 1, x = 0.5, level = 15 }
        _point{ points = pts, n = 2, x = 0.25, level = 15 }
        _point{ points = pts, n = 3, x = 0.75, level = 15 }
    end
end

return gfx, Gfx
