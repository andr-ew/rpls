local x,y = {}, {}

local mar = { left = 0, top = 7, right = 2, bottom = 2 }
local w = 128 - mar.left - mar.right
local h = 64 - mar.top - mar.bottom

x[1] = mar.left
x[1.5] = 128 * 2/5
x[2] = 128 * 2/3
y[1] = mar.top
y[3] = 64 - mar.bottom - 10
y[4] = 64 - mar.bottom

local e = {
    { x = x[1], y = y[1] },
    { x = x[1], y = y[4] },
    { x = x[2], y = y[4] },
}
local k = {
    {  },
    -- { x = x[1.5], y = y[1] },
    { x = x[2], y = y[1] },
    { x = x[2] + 28, y = y[1] },
}

local function Control()
    return function(props)
        _enc.control{
            n = props.n, 
            controlspec = params:lookup_param(props.id).controlspec,
            state = {
                params:get(props.id), 
                params.set, params, props.id,
            },
        }
        _screen.list{
            x = e[props.n].x, y = e[props.n].y, margin = 3,
            text = { 
                [props.label or props.id] = util.round(params:get(props.id), props.round or 0.01) 
            },
        }
    end
end
local function Option()
    local remainder = 0.0

    return function(props)
        _enc.integer{
            n = props.n, 
            min = 1, max = #params:lookup_param(props.id).options,
            state = {
                params:get(props.id), 
                params.set, params, props.id,
            },
            state_remainder = { remainder, function(v) remainder = v end }
        }
        _screen.list{
            x = e[props.n].x, y = e[props.n].y, margin = 3,
            text = { [props.label or props.id] = params:string(props.id) },
        }
    end
end
local function ToggleHold()
    local downtime = nil
    local blink = false
    local blink_level = 2

    return function(props)
        if crops.device == 'key' and crops.mode == 'input' then
            local n, z = table.unpack(crops.args) 

            if n == props.n then
                if z==1 then
                    downtime = util.time()
                elseif z==0 then
                    if downtime and ((util.time() - downtime) > 0.5) then 
                        blink = true
                        blink_level = 1
                        crops.dirty.screen = true

                        clock.run(function() 
                            clock.sleep(0.1)
                            blink_level = 2
                            crops.dirty.screen = true

                            params:delta(props.id_hold)

                            clock.sleep(0.2)
                            blink_level = 1
                            crops.dirty.screen = true

                            clock.sleep(0.4)
                            blink = false
                            crops.dirty.screen = true
                        end)
                    else
                        _key.toggle{
                            n = props.n, edge = 'falling',
                            state = {
                                params:get(props.id_toggle), 
                                params.set, params, props.id_toggle,
                            },
                        }
                    end
                    
                    downtime = nil
                end
            end
        end

        _screen.text{
            x = k[props.n].x, y = k[props.n].y,
            text = blink and (
                props.label_hold or props.id_hold
            ) or (
                props.label_toggle or props.id_toggle
            ),
            level = ({ 4, 15 })[
                blink and blink_level or (params:get(props.id_toggle) + 1)
            ],
        }
    end
end

local Pages = {}

Pages['C'] = function()
    local _clock, _vol1, _vol2 = Control(), Control(), Control()

    return function()
        _clock{ id = 'clock mult', label = 'clk', n = 1, round = 0.001 }
        _vol1{ id = 'vol 1', n = 2, label = 'vol1' } 
        _vol2{ id = 'vol 2', n = 3, label = 'vol2' } 
    end
end

Pages['R'] = function()
    local _rr, _r1, _r2 = Option(), Option(), Option()

    return function()
        _rr{ id = 'rate rec', n = 1, label = 'rate r' }
        _r1{ id = 'rate 1', n = 2, label = 'rate1' }
        _r2{ id = 'rate 2', n = 3, label = 'rate2' }
    end
end
Pages['>'] = function()
    local _frr, _f1r, _f2r = Control(), Control(), Control()

    return function()
        _frr{ id = 'rec > rec', n = 1, label = 'r > r' }
        _f1r{ id = '1 > rec', n = 2, label = '1 > r' }
        _f2r{ id = '2 > rec', n = 3, label = '2 > r' }
    end
end
Pages['F'] = function()
    local _q, _hp, _lp = Control(), Control(), Control()

    return function()
        _q{ id = 'q', n = 1 }
        _hp{ id = 'hp', n = 2 }
        _lp{ id = 'lp', n = 3 }
    end
end

local function Norns()
    local pages_all = { 'C', 'R', '>', 'F' }
    local _pages = {}

    for i, name in ipairs(pages_all) do
        _pages[i] = Pages[name]()
    end

    local _freeze_clear = ToggleHold()

    local page = 1
    local alt = 0

    local _gfx = Gfx()

    return function()
        _key.momentary{
            n = 1,
            state = { alt, function(v) alt = v; crops.dirty.screen = true end },
        }

        local pages = { 'C', 'R', '>', params:string('state') == 'enabled' and 'F' or nil }

        _pages[util.wrap(page, 1, #pages)]()

        _key.integer{
            n_next = 2, min = 1, max = #pages,
            state = { page, function(v) page = v; crops.dirty.screen = true end },
        }
        _screen.list{
            x = k[2].x, y = k[2].y, margin = 2,
            text = pages, focus = page,
        }

        _freeze_clear{
            n = 3, 
            id_toggle = 'freeze', id_hold = 'clear', 
            label_toggle = 'frz', label_hold = 'clr'
        }

        _gfx()
    end
end

return Norns
