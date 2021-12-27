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
                label = 'vol',
                state = of.param('vol '..i),
                controlspec = of.controlspec('vol '..i),
            }
        end
    end
end

--TODO: new rates
-- r: 0, 1, 2, 3, 4
-- 1/2: (+/-) 1/2, 1, 2, 3, 4, 5
Altpages[1] = function()
    return function()
    end
end

Pages[2] = function()
    return function()
    end
end
Altpages[2] = function()
    return function()
    end
end

Pages[3] = function()
    return function()
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
