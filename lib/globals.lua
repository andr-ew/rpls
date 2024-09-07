local rpls = {}

rpls.mapping = false

rpls.rates = {
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
rpls.heads = { 1, 2, 3 }
rpls.get_rate = function() return 1 end

rpls.loop_points = {}
for i = 1,3 do rpls.loop_points[i] = { 0, 0 } end

rpls.tick = { 100, 100, 100 }
rpls.tick_all = 100
rpls.tick_tri = 0

rpls.page_focus = 1
    
rpls.pages_all = { 'C', 'R', '>', 'F' }

rpls.pages = { 'C', 'R', '>', 'F' }

rpls.set_param = function(id, v) params:set(id, v) end
rpls.get_param = function(id) return patcher.get_value_by_destination(id) end

rpls.of_param = function(id) return {
    rpls.get_param(id),
    rpls.set_param, id,
} end

return rpls
