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

local rates = { -2, -1, -0.5, 0.5, 1, 2 }
local function get_rate(idx)
    local id = 'rate '..idx
    return idx==3 and 1 or rates[params:get(id)]
end

local function time()
    local loop_points = {}
    for i = 1,3 do loop_points[i] = { 0, 0 } end

    local heads = { 1, 2, 3 }
    local time = 1

    params:add{
        type='control', id='time',
        controlspec = cs.def{ min = 0.001, max = 2*3, default = 4 },
        action = function(v)
            time = v/3

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
    
    local tick = { 10, 10, 10 }
    local quant = 0.001

    local function res(i)
        local st = loop_points[heads[i]][1]-- + play_mar
        local en = loop_points[heads[i]][2]-- - play_mar
        local rate = get_rate(i)
        local rev = rate < 0

        stereo('position', i, rev and en or st)

        tick[i] = 0
    end

    local function resall()
        for i = 1,3 do
            res(i)
        end
        table.insert(heads, 1, table.remove(heads, #heads))
    end
    
    clock.run(function()
        while true do
            if tick[3] >= time then
                resall()
            else
                for i = 1,3 do
                    local rate = get_rate(i)
                    local div = math.abs(rate)

                    if tick[i] >= time/div then res(i) end
                end
            end
            
            clock.sleep(quant)
            for i = 1,3 do tick[i] = tick[i] + quant end
        end
    end)
end

local function globals()
    params:add{
        type='control', id='fade',
        controlspec = cs.def { default = 0.0025, min = 0.0025, quantum = 1/100/10, step = 0, max = 0.5 },
        action = function(v)
            for i = 1,6 do
                softcut.fade_time(i, v)
                play_mar = v
                rec_mar = v*2
            end
        end
    }
end

local function head(idx)
    stereo('enable', idx, 1)
    stereo('level_slew_time', idx, 0.1)
    stereo('recpre_slew_time', idx, 0.1)

    local off = (idx - 1) * 2
    softcut.pan(off + 1, -1)
    softcut.pan(off + 2, 1)
    softcut.buffer(off + 1, 1)
    softcut.buffer(off + 2, 2)
end

local function rechead()
    idx = 3
    local off = (idx - 1) * 2

    head(idx)

    stereo('loop', idx, 0)
    stereo('rec', idx, 1)
    stereo('play', idx, 1)
    stereo('level', idx, 0)
    stereo('pre_level', idx, 0)
    stereo('rec_level', idx, 1)
    -- stereo('fade_time', idx, rec_fade)

    do
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
    params:add{
        type = 'control', id = 'feedback', controlspec = cs.def{ default = 0.5 },
        action = function(v)
            softcut.level_cut_cut(1 + off, 2 + off, v)
            softcut.level_cut_cut(2 + off, 1 + off, v)
            -- stereo('pre_level', idx, v)
        end
    }
end

local function playhead(idx)
    local off = (idx - 1) * 2

    head(idx)
    
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

    do
        local pan = 0
        local lvl = 1
        local update = function()
            local p, v = pan, lvl
            softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level(off + 2, v * ((p < 0) and 1 + p or 1))
        end

        params:add{
            type='control', id = 'vol '..idx,
            controlspec = cs.def { default = 1 },
            action = function(v) lvl = v; update() end
        }
        params:add{
            type='control', id = 'pan '..idx,
            controlspec = cs.def { min = -1, max = 1, default = 0 },
            action = function(v) pan = v; update() end
        }
    end
    do
        local names = { '-2x', '-1x', '-1/2x', '1/2x', '1x', '2x' }
        params:add{
            type='option', id = 'rate '..idx,
            options = names, default = 5,
            action = function(v)
                stereo('rate', idx, rates[v])
            end
        }
    end
end

local function filter()
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
        type = 'control', id = 'res',
        controlspec = cs.def{ default = 0.4 },
        action = function(v)
            for i = 1,2 do
                stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v))
            end
            stereo('pre_filter_rq', 3, util.linexp(0, 1, 0.01, 20, 1 - v))
        end
    }
end

playhead(1)
playhead(2)
rechead()
globals()
time()
filter()
    
params:set('rate 1', 3)
params:set('rate 2', 1)
params:set('level 2', 0.5)

local function post_read()
    softcut.pan(2, -1)
    softcut.pan(1, 1)
end

return post_read