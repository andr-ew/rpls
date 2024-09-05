-- rpls
--
-- varispeed multitap echo
--
-- v1.1.1 @andrew
--
-- K2: page
-- K3: freeze
-- E1-E3: various

--device globals

g = grid.connect()

local wide = g and g.device and g.device.cols >= 16 or false

--git submodule libs

include 'lib/crops/core'                                    --crops, a UI component framework
Grid = include 'lib/crops/components/grid'
Enc = include 'lib/crops/components/enc'
Key = include 'lib/crops/components/key'
Screen = include 'lib/crops/components/screen'

patcher = include 'lib/patcher/patcher'                     --modulation maxtrix
Patcher = include 'lib/patcher/ui/using_map_key'            --mod matrix patching UI utilities

--script files

rpls = include 'lib/globals'
Gfx = include 'lib/ui/graphics'                             --screen graphics component
rpls.params = include 'lib/params'                          --params & softcut functionality
App = {}
App.norns = include 'lib/ui/norns'                          --norns UI component
App.grid = include 'lib/ui/grid'                            --grid UI

rpls.crow_outputs_enabled = true

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

--add params
    
rpls.params.pre_init()
rpls.params.add_softcut_params()
rpls.params.add_patcher_params()
rpls.params.add_pset_params()

--connect UI components

_app = { 
    grid = App.grid({ wide = wide, y = 1 }), 
    norns = App.norns() 
}

crops.connect_enc(_app.norns)
crops.connect_key(_app.norns)
crops.connect_screen(_app.norns, 60)
crops.connect_grid(_app.grid, g)

--norns globals

function init()
    params:read()
    params:bang()
    
    crow_add()
    rpls.params.post_init()
end

function cleanup()
    if params:string('autosave pset') == 'yes' then params:write() end
end
