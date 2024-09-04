-- rpls
--
-- varispeed multitap echo
--
-- v1.1 @andrew
--
-- K2: page
-- K3: freeze
-- E1-E3: various

--git submodule libs

include 'lib/crops/core'                                    --crops, a UI component framework
Grid = include 'lib/crops/components/grid'
Enc = include 'lib/crops/components/enc'
Key = include 'lib/crops/components/key'
Screen = include 'lib/crops/components/screen'

patcher = include 'lib/patcher/patcher'                     --modulation maxtrix
Patcher = include 'lib/patcher/ui/using_map_key'            --mod matrix patching UI utilities

--script globals

rpls = {}

rpls.mapping = false

rates = {
    [1] = {
        k = { '-1/2', '1/2', '1', '2', '3', '4', '5', '6' },
        v = { -0.5, 0.5, 1, 2, 3, 4, 5, 6 }
    },
    [2] = {
        k = { '-6', '-5', '-4', '-3', '-2', '-1', '-1/2', '1/2', '1', '2', '3', '4', '5', '6' },
        v = { -6, -5, -4, -3, -2, -1, -0.5, 0.5, 1, 2, 3, 4, 5, 6 }
    },
    rec = {
        k = { '0', '1', '2', '3', '4' },
        v = { 0, 1, 2, 3, 4 }
    }
}
heads = { 1, 2, 3 }
get_rate = function() return 1 end

loop_points = {}
for i = 1,3 do loop_points[i] = { 0, 0 } end

tick = { 100, 100, 100 }
tick_all = 100
tick_tri = 0

--set up modulation sources

local add_actions = {}
for i = 1,2 do
    add_actions[i] = patcher.crow.add_source(i)
end

--set up crow

local function crow_add()
    for _,action in ipairs(add_actions) do action() end

    for n = 1,3 do
        crow.output[n].action = 'pulse()'
    end
end
norns.crow.add = crow_add

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
    
    crow_add()
    post_init()
end

function cleanup()
    if params:string('autosave pset') == 'yes' then params:write() end
end
