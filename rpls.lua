-- rpls
--
-- varispeed multitap echo
--
-- v1.0 @andrew
--
-- K2: page
-- K3: freeze
-- E1-E3: various

--git submodule libs

include 'lib/crops/core'                      --crops, a UI component framework
_enc = include 'lib/crops/routines/enc'
_key = include 'lib/crops/routines/key'
_screen = include 'lib/crops/routines/screen'

--script globals

rates = {
    [1] = {
        k = { '-1/2', '1/2', '3/4', '1', '3/2', '2', '3', '4', '5', '6' },
        v = { -0.5, 0.5, 0.75, 1, 1.5, 2, 3, 4, 5, 6 }
    },
    [2] = {
        k = { '-6', '-5', '-4', '-3', '-2', '-1', '-1/2', '1/2', '3/4', '1', '3/2', '2', '3', '4', '5', '6' },
        v = { -6, -5, -4, -3, -2, -1, -0.5, 0.5, 0.75, 1, 1.5, 2, 3, 4, 5, 6 }
    },
    rec = {
        k = { '0', '1', '2', '3', '4' },
        v = { 0, 1, 2, 3, 4 }
    }
}
function get_rate(idx)
    local k = (idx==3) and 'rec' or idx
    return rates[k].v[params:get('rate '..k)]
end

heads = { 1, 2, 3 }

loop_points = {}
for i = 1,3 do loop_points[i] = { 0, 0 } end

tick = { 100, 100, 100 }
tick_all = 100
tick_tri = 0

--include script libs

Gfx = include 'lib/graphics'                  --screen graphics component
local post_init = include 'lib/params'        --add params & softcut functionality
App = {}
App.norns = include 'lib/ui'                  --norns UI component

--connect UI components

_app = { norns = App.norns() }

crops.connect_enc(_app.norns)
crops.connect_key(_app.norns)
crops.connect_screen(_app.norns, 60)

--norns globals

function init()
    params:read()
    params:bang()

    post_init()
end

function cleanup()
    if params:string('autosave pset') == 'yes' then params:write() end
end
