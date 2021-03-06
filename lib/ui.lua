local e = {
    { x = x[1], y = y[1] },
    { x = x[1], y = y[3] },
    { x = x[2], y = y[3] },
}
local k = {
    {  },
    { x = x[1], y = y[4] },
    { x = x[2], y = y[4] },
}

local Pages = {}
local Altpages = {}

local function ctl(_comp, i, id, lab)
    lab = lab or id
    _comp{
        n = i, x = e[i].x, y = e[i].y,
        label = lab, 
        state = of.param(id),
        controlspec = of.controlspec(id),
    }
end

Pages[1] = function()
    local _time = Text.enc.control()
    local _vol = { Text.enc.control(), Text.enc.control() }

    return function()
        ctl(_time, 1, 'time')

        for i = 1,2 do
            ctl(_vol[i], i+1, 'vol '..i)
        end
    end
end
local function Tap()
    local _tap = Text.key.trigger()

    local tap_blink = 0
    local tap_clock = nil
    local tap_buf = {}

    return function()
        _tap{
            n = 2, x = k[2].x, y = k[2].y, label = 'tap',
            lvl = tap_blink*11 + 4,
            action = function(_, _, t)
                if t < 1 and t > 0 then
                    table.insert(tap_buf, t)
                    if #tap_buf > 2 then table.remove(tap_buf, 1) end

                    local avg = 0
                    for i,v in ipairs(tap_buf) do avg = avg + v end
                    avg = avg / #tap_buf

                    params:set('time', avg)

                    if tap_clock then clock.cancel(tap_clock) end
                    tap_clock = clock.run(function() 
                        while true do
                            tap_blink = 1; redraw()
                            clock.sleep(avg*0.5)
                            tap_blink = 0; redraw()
                            clock.sleep(avg*0.5)
                        end
                    end)
                else
                    tap_buf = {}
                    if tap_clock then clock.cancel(tap_clock) end
                    tap_clock = nil
                    tap_blink = 0
                end
            end
        }
    end
end
Altpages[1] = function()
    local _volrec = Text.enc.control()
    local _fade = Text.enc.control()
    local _slew = Text.enc.control()

    local _tap = Tap()
    local _res = Text.key.trigger()

    return function()
        ctl(_volrec, 1, 'vol rec')
        ctl(_fade, 2, 'fade')
        ctl(_slew, 3, 'slew')

        _tap{}
        _res{
            n = 3, x = k[3].x, y = k[3].y, label = 'reset',
            state = of.param('reset')
        }
    end
end

Pages[2] = function()
    local _raterec = Text.enc.number()
    local _rateplay = { Text.enc.number(), Text.enc.number() }

    return function()
        _raterec{
            n = 1, x = e[1].x, y = e[1].y,
            label = 'rate rec', 
            state = of.param('rate rec'),
            min = 1, inc = 1,
            max = #params:lookup_param('rate rec').options,
            formatter = function(v)
                return params:lookup_param('rate rec').options[v]
            end,
        }
        for i = 1,2 do
            _rateplay[i]{
                n = 1+i, x = e[1+i].x, y = e[1+i].y,
                label = 'rate '..i,
                state = of.param('rate '..i),
                min = 1, inc = 1,
                max = #params:lookup_param('rate '..i).options,
                formatter = function(v)
                    return params:lookup_param('rate '..i).options[v]
                end,
            }
        end
    end
end
Altpages[2] = function()
    local _e1 = Text.enc.control()
    local _e2 = Text.enc.control()
    local _e3 = Text.enc.control()

    local _k2 = Text.key.momentary()
    local _k3 = { trig = Key.trigger(), lbl = Text.label() }

    return function()
        ctl(_e1, 1, 'rec -> rec')
        ctl(_e2, 2, '1 -> rec')
        ctl(_e3, 3, '2 -> rec')

        _k2{
            n = 2, x = k[2].x, y = k[2].y, label = '~',
            state = of.param('~')
        }
        local froze = params:get('freeze') > 0
        _k3.trig{
            n = 3,
            action = function()
                if not froze then
                    params:set('freeze', 1)
                else
                    params:delta('clear')
                    params:set('freeze', 0)
                end
                redraw()
            end
        }
        _k3.lbl{
             x = k[3].x, y = k[3].y, lvl = 4,
             label = (not froze) and 'freeze' or 'clear'
        }
    end
end

Pages[3] = function()
    local _q = Text.enc.control()
    local _hp = Text.enc.control()
    local _lp = Text.enc.control()

    return function()
        ctl(_q, 1, 'q')
        ctl(_hp, 2, 'hp')
        ctl(_lp, 3, 'lp')
    end
end
Altpages[3] = function()
    local _e1 = Text.enc.control()
    local _e2 = Text.enc.control()
    local _e3 = Text.enc.control()
    local _verbon = Text.key.toggle()

    return function()
        ctl(_e1, 1, 'rev_return_level', 'verb lvl')
        ctl(_e2, 2, 'rev_cut_input', 'verb cut')
        ctl(_e3, 3, 'rev_monitor_input', 'verb mon')

        _verbon{
            n = 2, x = k[2].x, y = k[2].y, label = 'verb on',
            state = { params:get('reverb') - 1, function(v) params:set('reverb', v+1) end }
        }
    end
end

local function App()
    _pages = {}
    for i,Page in ipairs(Pages) do _pages[i] = Page() end
    _altpages = {}
    for i,Altpage in ipairs(Altpages) do _altpages[i] = Altpage() end

    local page = 1
    local _tab = Text.key.option()

    local alt = 0
    local _alt = Key.momentary()

    return function()
        _alt{
            n = 1,
            state = { alt, function(v) alt = v; redraw() end },
        }

        if alt==0 then
            _pages[page]{}

            _tab{
                n = { 2, 3 }, x = { { 118-116 }, { 122-116 }, { 126-116 } }, y = 50, 
                align = { 'right', 'bottom' },
                font_size = 16, margin = 3,
                options = { '.', '.', '.' },
                state = { page, function(v) page = v end }
            }
        else
            _altpages[page]{}
        end
    end
end

local _app = App()
nest.connect_enc(_app)
nest.connect_key(_app)
nest.connect_screen(_app)
