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

--include script libs

gfx, Gfx = include 'lib/graphics'             --screen graphics data & component
local post_init = include 'lib/params'        --add params
App = {}
App.norns = include 'lib/ui'                  --norns UI component

--connect UI components

_app = { norns = App.norns() }

crops.connect_enc(_app.norns)
crops.connect_key(_app.norns)
crops.connect_screen(_app.norns)

--norns globals

function init()
    params:read()
    params:bang()

    post_init()
end

function cleanup()
    if params:string('autosave pset') == 'yes' then params:write() end
end
