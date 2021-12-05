-- rpls

cs = require 'controlspec'

buf_time = 16777216 / 48000 --exact time from the sofctcut source
play_fade = 0.1
rec_fade = 0.05

audio.level_cut(1.0)
audio.level_adc_cut(1)
audio.level_eng_cut(1)

local function stereo(command, pair, ...)
    local off = (pair - 1) * 2
    for i = 1, 2 do
        softcut[command](off + i, ...)
    end
end

local function Time()
    loop_points = {}
    for i = 1,3 do loop_points[i] = { 0, 0 } end

    heads = { 1, 2, 3 }
    time = 1

    local function update(i)
        local st = loop_points[heads[i]][1]
        local en = loop_points[heads[i]][2]
        local mar = rec_fade

        stereo('loop_start', i, i==3 and (st-mar) or (st))
        stereo('loop_end', i, i==3 and (en+mar) or (en))
    end

    params:add{
        type='control', id='time',
        controlspec = cs.def{ min = 0.4, max = 5*3, default = 4 },
        action = function(v)
            time = v/3

            local mar = play_fade*4 + (5*3)
            for i = 1,3 do
                loop_points[i][1] = (i - 1) * (mar)
                loop_points[i][2] = (i- 1) * (mar) + time

                update(i)
            end
        end
    }


    for i = 1,3 do
        -- update(i)
        local st = loop_points[heads[i]][1]
        stereo('position', i, st)
    end
    clock.run(function()
        while true do
            for i = 1,3 do
                update(i)
                local st = loop_points[heads[i]][1]
                -- stereo('position', i, st)
            end
            
            clock.sleep(time)
            table.insert(heads, 1, table.remove(heads, #heads))
        end
    end)
end

local function Head(idx)
    stereo('enable', idx, 1)
    stereo('level_slew_time', idx, 0.1)
    stereo('recpre_slew_time', idx, 0.1)

    local off = (idx - 1) * 2
    softcut.pan(off + 1, -1)
    softcut.pan(off + 2, 1)
    softcut.buffer(off + 1, 1)
    softcut.buffer(off + 2, 2)
end

local function Rechead()
    idx = 3
    local off = (idx - 1) * 2

    Head(idx)

    stereo('loop', idx, 1)
    stereo('rec', idx, 1)
    stereo('play', idx, 0)
    stereo('pre_level', idx, 0)
    stereo('rec_level', idx, 1)
    stereo('fade_time', idx, rec_fade)

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
            controlspec = cs.def{ min = -1, max = 1, default = 0.5 },
            action = function(v) pan = v; update() end
        }
    end
    params:add{
        type = 'control', id = 'feedback', controlspec = cs.def{ default = 0.5 },
        action = function(v)
            softcut.level_cut_cut(1 + off, 2 + off, v)
            softcut.level_cut_cut(2 + off, 1 + off, v)
        end
    }
end

local function Playhead(idx)
    local off = (idx - 1) * 2

    Head(idx)
    
    stereo('rec', idx, 0)
    stereo('play', idx, 1)
    stereo('loop', idx, 1)
    stereo('level_input_cut', 1, idx, 0)
    stereo('level_input_cut', 2, idx, 0)
    stereo('pre_level', idx, 1)
    stereo('fade_time', idx, play_fade)

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
            type='control', id = 'level '..idx,
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
        local rates = { -2, -1, -0.5, 0.5, 1, 2 }
        params:add{
            type='option', id = 'rate '..idx,
            options = names, default = 5,
            action = function(v)
                stereo('rate', idx, rates[v])
            end
        }
    end
end

Time()
Playhead(1)
Playhead(2)
Rechead()

function init()
    params:set('rate 1', 3)
    params:set('rate 2', 1)
    params:set('level 2', 0.5)

    params:bang()
end
