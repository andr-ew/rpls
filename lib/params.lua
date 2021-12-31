cs = require 'controlspec'

local buf_time = 16777216 / 48000 --exact time from the sofctcut source
local play_mar = 0.1
local rec_mar = 0.2
-- rec_fade = 0.1

audio.level_cut(1.0)
audio.level_adc_cut(1)
audio.level_eng_cut(1)

local function stereo(command, pair, ...)
    local off = (pair - 1) * 2
    for i = 1, 2 do
        softcut[command](off + i, ...)
    end
end

for idx = 1,3 do
    stereo('enable', idx, 1)
    stereo('level_slew_time', idx, 0.1)
    stereo('recpre_slew_time', idx, 0.1)

    local off = (idx - 1) * 2
    softcut.pan(off + 1, -1)
    softcut.pan(off + 2, 1)
    softcut.buffer(off + 1, 1)
    softcut.buffer(off + 2, 2)
end
do
    local idx = 3
    local off = (idx - 1) * 2

    stereo('loop', idx, 0)
    stereo('rec', idx, 1)
    stereo('play', idx, 1)
    -- stereo('level', idx, 0)
    stereo('pre_level', idx, 0)
    stereo('rec_level', idx, 1)
    -- stereo('fade_time', idx, rec_fade)

end
for idx = 1,2 do
    stereo('rec', idx, 0)
    stereo('play', idx, 1)
    stereo('loop', idx, 0)
    stereo('level_input_cut', 1, idx, 0)
    stereo('level_input_cut', 2, idx, 0)
    stereo('pre_level', idx, 1)
    -- stereo('fade_time', idx, play_mar)

    -- stereo('post_filter_dry', idx, 0)
    -- stereo('rec', idx, 1)
    -- stereo('pre_level', idx, 0.75)
end

local rates = {
    [1] = {
        k = { 
            '1/2x', '1x', '2x', '3x', '4x', '5x', '6x'
        },
        v = { 0.5, 1, 2, 3, 4, 5, 6 }
    },
    [2] = {
        k = { 
            '-6x', '-5x', '-4x', '-3x', '-2x', '-1x', '-1/2x', '1/2x', '1x', '2x', '3x', '4x', '5x', '6x'
        },
        v = { -6, -5, -4, -3, -2, -1, -0.5, 0.5, 1, 2, 3, 4, 5, 6 }
    },
    rec = {
        k = { '0x', '1/2x', '1x', '2x', '3x', '4x' },
        v = { 0, 0.5, 1, 2, 3, 4 }
    }
}

params:add_separator('rate')
do
    local slew
    local function update_slew()
        for i = 1,6 do
            softcut.rate_slew_time(i, slew)
        end
    end
    local clk
    local function slew_temp(idx, v)
        local wait = v --0.1

        if clk then clock.cancel(clk) end
        clk = clock.run(function() 
            stereo('rate_slew_time', idx, v)
            clock.sleep(wait)
            update_slew()
        end)
    end

    local rate = { 1, 1, 1 }
    local wob = 0
    local function update_rate()
        for i = 1,3 do
            stereo('rate', i, rate[i] + wob)
        end
    end
    params:add{
        type='option', id = 'rate rec',
        options = rates.rec.k, default = tab.key(rates.rec.k, '1x'),
        action = function(i)
            rate[3] = rates.rec.v[i]; update_rate()
        end
    }
    for idx = 1,2 do
        params:add{
            type = 'option', id = 'rate '..idx,
            options = rates[idx].k, default = tab.key(rates[idx].k, '1x'),
            action = function(i)
                rate[idx] = rates[idx].v[i]; update_rate()
            end
        }
    end
    params:add{
        type = 'control', id = 'slew',
        controlspec = cs.def{ min = 0, max = 0.5, default = 0.01 },
        action = function(v)
            slew = v; update_slew()
        end
    }
    params:add{
        type = 'binary', behavior = 'momentary', id = '~',
        action = function(v)
            -- warble logic courtesy of cranes
            local function sl()
                slew_temp(3, 0.6 + (math.random(-30,10)/100))
            end
            if v > 0 then
                wob = (math.random(-10,10)/1000)*5
                sl()
                update_rate()
            else
                wob = 0
                sl()
                update_rate()
            end
        end
    }
end

local function get_rate(idx)
    local k = (idx==3) and 'rec' or idx
    return rates[k].v[params:get('rate '..k)]
end

params:add_separator('clock')
do
    local loop_points = {}
    for i = 1,3 do loop_points[i] = { 0, 0 } end

    local heads = { 1, 2, 3 }
    local time = 1

    params:add{
        type='control', id='time',
        controlspec = cs.def{ min = 0.001, max = 2*3, default = 4 },
        action = function(v)
            time = util.round(v/3, 0.001)

            local mar = (0.5*2) + (5*3)
            for i = 1,3 do
                loop_points[i][1] = (i - 1) * (mar)
                loop_points[i][2] = (i- 1) * (mar) + time
            end
        end
    }


    for i = 1,3 do
        stereo('loop_start', i, 0)
        stereo('loop_end', i, buf_time)
    end
    
    local tick = { 100, 100, 100 }
    local tick_all = 100
    local quant = 0.001

    local function res(i)
        local st = loop_points[heads[i]][1] --- 0.1
        local en = loop_points[heads[i]][2] + 0.25
        local rate = get_rate(i)
        local rev = rate < 0

        stereo('position', i, rev and en or st)

        tick[i] = 0
    end

    local function resall()
        table.insert(heads, 1, table.remove(heads, #heads))
        for i = 1,3 do
            res(i)
        end
        tick_all = 0
    end
    
    clock.run(function()
        while true do
            if tick_all >= time then
                resall()
            else
                for i = 1,2 do
                    if tick[i] >= time then res(i) end
                end
            end
            
            clock.sleep(quant)

            for i = 1,3 do 
                local rate = math.abs(get_rate(i))
                tick[i] = tick[i] + (quant * rate)
            end
            tick_all = tick_all + quant
        end
    end)
end
params:add{
    type='control', id='fade',
    controlspec = cs.def { default = 0.07, min = 0.0025, quantum = 1/100/10, step = 0, max = 0.5 },
    action = function(v)
        for i = 1,4 do
            softcut.fade_time(i, v)
            play_mar = v
            rec_mar = v*2
        end
        for i = 5,6 do
            softcut.fade_time(i, v) --*2
            play_mar = v
            rec_mar = v*2
        end
    end
}

params:add_separator('feedback')
for _,idx in pairs{ 3, 1, 2 } do
    local off = (idx - 1) * 2
    local name = idx==3 and 'rec' or idx

    params:add{
        type = 'control', id = name..' -> rec', controlspec = cs.def{ default = 0 },
        action = function(v)
            softcut.level_cut_cut(1 + off, 2 + 4, v)
            softcut.level_cut_cut(2 + off, 1 + 4, v)
            -- stereo('pre_level', idx, v)
        end
    }
end

params:add_separator('mix')
for idx = 1,3 do
    local off = (idx - 1) * 2
    local name = idx==3 and 'rec' or idx

    local pan = 0
    local lvl = 1
    local update = function()
        local p, v = pan, lvl
        if idx==1 then p = -p end
        softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
        softcut.level(off + 2, v * ((p < 0) and 1 + p or 1))
    end

    params:add{
        type='control', id = 'vol '..name,
        controlspec = cs.def { default = 1 },
        action = function(v) lvl = v; update() end
    }
    params:add{
        type='control', id = 'pan '..name,
        controlspec = cs.def { min = -1, max = 1, default = 0 },
        action = function(v) pan = v; update() end
    }
end
do
    local idx = 3
    local off = (idx - 1) * 2

    local route = 'stereo'
    local pan = 0
    local function update()
        local v, p = 1, pan

        if route == 'stereo' then
            softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level_input_cut(2, off + 1, 0)
            softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
            softcut.level_input_cut(1, off + 2, 0)
        elseif route == 'mono' then
            softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level_input_cut(1, off + 2, v * ((p < 0) and 1 + p or 1))
            softcut.level_input_cut(2, off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
        end
    end
    local ir_op = { 'stereo', 'mono' } 
    params:add{
        type = 'option', id = 'input routing', options = ir_op,
        action = function(v) route = ir_op[v]; update() end
    }
    params:add{
        type = 'control', id = 'input pan', 
        controlspec = cs.def{ min = -1, max = 1, default = 0.7 },
        action = function(v) pan = v; update() end
    }
end

params:add_separator('filter')
do
    local pre = 'hp'
    local post = 'lp'
    local both = { pre, post }
    local defaults = { hp = 0, lp = 1 }

    for i = 1,2 do
        stereo('post_filter_dry', i, 0)
        stereo('post_filter_'..post, i, 1)
    end
    stereo('pre_filter_fc_mod', 3, 0)
    stereo('pre_filter_dry', 3, 0)
    stereo('pre_filter_'..pre, 3, 1)

    for i,filter in ipairs(both) do
        local pre = i==1

        params:add {
            type = 'control', id = filter,
            controlspec = cs.def{ default = defaults[filter], quantum = 1/100/2, step = 0 },
            action = (
                pre and (
                    function(v) 
                        stereo('pre_filter_fc', 3, util.linexp(0, 1, 2, 20000, v)) 
                    end
                ) or (
                    function(v) 
                        for i = 1,2 do
                            stereo('post_filter_fc', i, util.linexp(0, 1, 2, 20000, v)) 
                        end
                    end
                )
            )
        }
    end
    params:add {
        type = 'control', id = 'q',
        controlspec = cs.def{ default = 0.4 },
        action = function(v)
            for i = 1,2 do
                stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v))
            end
            stereo('pre_filter_rq', 3, util.linexp(0, 1, 0.01, 20, 1 - v))
        end
    }
end
    
params:set('rate 1', tab.key(rates[1].k, '2x'))
params:set('rate 2', tab.key(rates[2].k, '-1/2x'))
params:set('vol 1', 0.5)
params:set('vol rec', 0)
params:set('rec -> rec', 0.5)

local function post_init()
    softcut.pan(2, -1)
    softcut.pan(1, 1)
end

return post_init
