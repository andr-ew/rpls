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

nest = include 'lib/nest/core'
Key, Enc = include 'lib/nest/norns'
Text = include 'lib/nest/text'
of = include 'lib/nest/util/of'

post_read = include 'lib/params'
x, y, redraw_graphics = include 'lib/gfx'
include 'lib/ui'

function init()
    params:read()

    post_read()

    params:bang()
end

function cleanup()
    params:write()
end
