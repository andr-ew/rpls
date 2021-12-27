x,y = {}, {}

local mar = { left = 2, top = 4, right = 2, bottom = 4 }
local w = 128 - mar.left - mar.right
local h = 64 - mar.top - mar.bottom

x[1] = mar.left
x[2] = 128/2
y[1] = mar.top
y[2] = nil
y[3] = mar.top + h*(6/8)
y[4] = mar.top + h*(7/8)

local function redraw_graphics()
end

return x, y, redraw_graphics
