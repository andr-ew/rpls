-- rpls
--
-- tidal repitch echo /
-- phonetic fracture prism
--
-- v0 @andrew
--
-- send audio in.
--
-- K2-K3: page
-- E1-E3: various
-- K1: alt
--
-- time flows thru 3 pools
-- the first reads, 
-- the others write
--
-- set the rate & size of 
-- these pools to draw
-- concentric prisms
--
-- ( ok it's a bit like a multi-tap 
-- delay, but each tap plays 
-- back at a different rate )

--git submodule libs

include 'lib/crops/core'                      --crops, a UI component framework
_enc = include 'lib/crops/routines/enc'
_key = include 'lib/crops/routines/key'
_screen = include 'lib/crops/routines/screen'

--script globals

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
