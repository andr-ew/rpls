local e = {
    { x = x[1], y = y[1] },
    { x = x[1], y = y[3] },
    { x = x[2], y = y[3] },
}
local k = {
    { x = x[1], y = y[3] },
    { x = x[2], y = y[4] },
}

local Pages = {}
local Altpages = {}

Pages[1] = function()
    local _time = Text.enc.control()
    local _vol = { Text.enc.control(), Text.enc.control() }

    return function()
        _time{
            n = 1, x = e[1].x, y = e[1].y,
            label = 'time', 
            state = of.param('time'),
            controlspec = of.controlspec('time'),
        }
        for i = 1,2 do
            _vol[i]{
                n = 1+i, x = e[1+i].x, y = e[1+i].y,
                label = 'vol '..i,
                state = of.param('vol '..i),
                controlspec = of.controlspec('vol '..i),
            }
        end
    end
end
Altpages[1] = function()
    return function()
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
    return function()
    end
end

Pages[3] = function()
    local _q = Text.enc.control()
    local _hp = Text.enc.control()
    local _lp = Text.enc.control()

    return function()
        _q{
            n = 1, x = e[1].x, y = e[1].y,
            label = 'q', 
            state = of.param('q'),
            controlspec = of.controlspec('q'),
        }
        _hp{
            n = 2, x = e[2].x, y = e[2].y,
            label = 'hp', 
            state = of.param('hp'),
            controlspec = of.controlspec('hp'),
        }
        _lp{
            n = 3, x = e[3].x, y = e[3].y,
            label = 'lp', 
            state = of.param('lp'),
            controlspec = of.controlspec('lp'),
        }
    end
end
Altpages[3] = function()
    return function()
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
