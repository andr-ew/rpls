local x,y = {}, {}

local mar = { left = 0, top = 7, right = 2, bottom = 2 }
local w = 128 - mar.left - mar.right
local h = 64 - mar.top - mar.bottom

x[1] = mar.left
x[1.5] = 128 * 2/5
x[2] = 128 * 2/3 - 1
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
    local _ctl = { 
        enc = Patcher.enc.destination(Enc.control()), 
        screen = Patcher.screen.destination(Screen.list())
    }

    return function(props)
        local spec = params:lookup_param(props.id).controlspec

        _ctl.enc(props.id, rpls.mapping, {
            n = props.n, 
            controlspec = spec,
            state = rpls.of_param(props.id)
        })

        _ctl.screen(props.id, rpls.mapping, {
            -- x = e[props.n].x, y = e[props.n].y, margin = 3,
            -- text = { 
            --     [props.label or props.id] = util.round(params:get(props.id), props.round or 0.01) 
            -- },
            x = e[props.n].x, y = e[props.n].y, margin = 3,
            text = {
                props.label or props.id, 
                string.format(
                    props.format or '%.2f', rpls.get_param(props.id)
                )
                ..(spec.units or ''),
            },
            levels = { 4, 15 },
        }, props.label)
    end
end
local function Option()
    local _opt = { 
        enc = Patcher.enc.destination(Enc.integer()), 
        screen = Patcher.screen.destination(Screen.list()) 
    }

    return function(props)
        local options = params:lookup_param(props.id).options

        _opt.enc(props.id, rpls.mapping, {
            n = props.n, 
            min = 1, max = #params:lookup_param(props.id).options,
            state = rpls.of_param(props.id)
        })
        _opt.screen(props.id, rpls.mapping, {
            x = e[props.n].x, y = e[props.n].y, margin = 3,
            -- text = { [props.label or props.id] = params:string(props.id) },
            text = {
                props.label or props.id, 
                options[rpls.get_param(props.id)]
            },
            levels = { 4, 15 },
        }, props.label)
    end
end

local function ToggleHold()
    local downtime = nil
    local blink = false
    local blink_level = 2

    local _toggle = Key.toggle()
    local _text = Screen.text()

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
                        _toggle{
                            n = props.n, edge = 'falling',
                            state = rpls.of_param(props.id_toggle)
                        }
                    end
                    
                    downtime = nil
                end
            end
        end

        _text{
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

local function Clk()
    local _free = Patcher.enc.destination(Enc.control())
    local _sync = Patcher.enc.destination(Enc.integer())
    local _screen = Patcher.screen.destination(Screen.list())

    local function flip()
        local id = 'clock_mode'
        local p = params:lookup_param(id)
        local options = p.options

        params:set(id, params:get(id) % (#options) + 1)
    end

    local free_internal = nil 

    return function(props)
        local free = props.free
        
        local p = params:lookup_param(props.id)
        local options = p.options
        local spec = p.controlspec

        if free then
            local new_spec = cs.def{ 
                min = spec.minval - 0.5, max = spec.maxval, quantum = spec.quantum,
            }
            _free(props.id, rpls.mapping, {
                n = props.n, 
                controlspec = new_spec,
                state = {
                    free_internal or params:get('clock mult'),
                    function(v)
                        if v < spec.minval then
                            if v <= new_spec.minval then flip() end
                        else
                            rpls.set_param(props.id, v)
                        end

                        free_internal = v
                    end
                }
            })
        else
            local max = #params:lookup_param(props.id).options

            _sync(props.id, rpls.mapping, {
                n = props.n, 
                min = 1, max = max + 1,
                state = {
                    max - params:get(props.id) + 1,
                    function(v)
                        if v > max then flip()
                        else rpls.set_param(props.id, max - v + 1) end
                    end
                }
            })
        end

        _screen(props.id, rpls.mapping, {
            x = e[props.n].x, y = e[props.n].y, margin = 3,
            text = {
                props.label or props.id, 
                free and (
                        string.format(
                            props.format or '%.2f', rpls.get_param(props.id)
                        )
                        ..(spec.units or '')
                    ) or (
                        options[rpls.get_param(props.id)]
                    ),
            },
            levels = { 4, 15 },
        }, props.label)
    end
end

local Pages = {}

Pages['C'] = function()
    local _clock, _vol1, _vol2 = Clk(), Control(), Control()

    return function()
        do
            local free = params:string('clock_mode') == 'free'
            local id = free and 'clock mult' or 'clock mult sync'
            _clock{ id = id, free = free, label = 'clk', n = 1, round = 0.001 }
        end
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
    local _map = Key.momentary()

    local _pages = {}

    for i, name in ipairs(rpls.pages_all) do
        _pages[i] = Pages[name]()
    end

    local _focus = { key = Key.integer(), screen = Screen.list() }

    local _freeze_clear = ToggleHold()

    local _gfx = Gfx()

    return function()
        _map{
            n = 1, state = crops.of_variable(rpls.mapping, function(v) 
                rpls.mapping = v>0
                crops.dirty.screen = true
            end)
        }

        _pages[util.wrap(rpls.page_focus, 1, #rpls.pages)]()

        _focus.key{
            n_next = 2, min = 1, max = #rpls.pages,
            state = crops.of_variable(rpls.page_focus, function(v) 
                rpls.page_focus = v
                crops.dirty.screen = true 
                crops.dirty.grid = true 
            end),
        }
        _focus.screen{
            x = k[2].x, y = k[2].y, margin = 2,
            text = rpls.pages, focus = rpls.page_focus,
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
