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
    softcut.buffer(off + 1, 1)
    softcut.buffer(off + 2, 2)
end
do
    local idx = 3

    stereo('loop', idx, 0)
    stereo('rec', idx, 1)
    stereo('play', idx, 1)
    -- stereo('level', idx, 0)
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
            '1/2', '1', '2', '3', '4', '5', '6'
        },
        v = { 0.5, 1, 2, 3, 4, 5, 6 }
    },
    [2] = {
        k = { 
            '-6', '-5', '-4', '-3', '-2', '-1', '-1/2', '1/2', '1', '2', '3', '4', '5', '6'
        },
        v = { -6, -5, -4, -3, -2, -1, -0.5, 0.5, 1, 2, 3, 4, 5, 6 }
    },
    rec = {
        k = { 
            '0', 
            -- '1/2', 
            '1', '2', '3', '4' 
        },
        v = { 
            0, 
            -- 0.5, 
            1, 2, 3, 4 
        }
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
        options = rates.rec.k, default = tab.key(rates.rec.k, '1'),
        action = function(i)
            rate[3] = rates.rec.v[i]; update_rate()
            crops.dirty.screen = true
        end
    }
    for idx = 1,2 do
        params:add{
            type = 'option', id = 'rate '..idx,
            options = rates[idx].k, default = tab.key(rates[idx].k, '1'),
            action = function(i)
                rate[idx] = rates[idx].v[i]; update_rate()
                crops.dirty.screen = true
            end
        }
    end
    params:add{
        type = 'control', id = 'slew',
        controlspec = cs.def{ min = 0, max = 0.5, default = 0.01 },
        action = function(v)
            slew = v; update_slew()
            crops.dirty.screen = true
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
            crops.dirty.screen = true
        end
    }
end

local function get_rate(idx)
    local k = (idx==3) and 'rec' or idx
    return rates[k].v[params:get('rate '..k)]
end

params:add_separator('clock')
do
    local heads = { 1, 2, 3 }
    local loop_points = {}
    for i = 1,3 do 
        loop_points[i] = { 0, 0 } 
    end

    local function set_loop_points(t)
        local mar = (0.5*2) + (5*3)
        for i = 1,3 do
            loop_points[i][1] = (i - 1) * (mar)
            loop_points[i][2] = (i- 1) * (mar) + t
        end
    end

    local beats = 1

    local quant_secs = 0.005
    local quant

    function clock.tempo_change_handler(bpm)
        quant = quant_secs / (60 / bpm)
    end
    clock.tempo_change_handler(clock.get_tempo())
    
    params:add{
        type = 'control', id = 'clock mult',
        controlspec = cs.def { 
            min = 0, max = 8, default = 1, quantum = 1/8/16,
        },
        action = function(v)
            beats = math.max(v, quant)
            set_loop_points(beats * clock.get_beat_sec())
            
            crops.dirty.screen = true
        end
    }


    for i = 1,3 do
        stereo('loop_start', i, 0)
        stereo('loop_end', i, buf_time)
    end
    
    local tick = { 100, 100, 100 }
    local tick_all = 100

    local function res(i)
        local st = loop_points[heads[i]][1] --- 0.1
        local en = loop_points[heads[i]][2] + 0.14--+ 0.25
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
            local time = beats

            if tick_all >= time then
                resall()
            else
                for i = 1,2 do
                    if tick[i] >= time then res(i) end
                end
            end
            
            clock.sync(quant)

            for i = 1,3 do 
                local rate = math.abs(get_rate(i))
                tick[i] = tick[i] + (quant * rate)
            end
            tick_all = tick_all + quant
        end
    end)

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
            
            crops.dirty.screen = true
        end
    }
    params:add{
        type = 'binary', behavior = 'trigger', id = 'reset',
        action = function()
            resall()
            
            crops.dirty.screen = true
        end
    }
end

local output_route = 'stereo'
local feedback = { 0, 0, 0 }

local function update_feedback(idx)
    local off = (idx - 1) * 2
    local v = feedback[idx]

    if output_route == 'stereo' then
        softcut.level_cut_cut(1 + off, 2 + 4, v)
        softcut.level_cut_cut(2 + off, 1 + 4, v)
    elseif route == 'split' then
        softcut.level_cut_cut(1 + off, 1 + 4, v)
        softcut.level_cut_cut(2 + off, 2 + 4, v)
    end
end

params:add_separator('feedback')
for _,idx in pairs{ 3, 1, 2 } do
    local off = (idx - 1) * 2
    local name = idx==3 and 'rec' or idx

    params:add{
        type = 'control', id = name..' > rec', controlspec = cs.def{ default = 0 },
        action = function(v)
            feedback[idx] = v; update_feedback(idx)
            
            crops.dirty.screen = true
        end
    }
end
params:add{
    type = 'binary', behavior = 'toggle', id = 'freeze',
    action = function(froze)
        stereo('pre_level', 3, froze)
        stereo('rec_level', 3, ~ froze & 1)

        print('frozen', froze)
        
        crops.dirty.screen = true
    end
}
params:add{
    type = 'binary', behavior = 'trigger', id = 'clear',
    action = function()
        softcut.buffer_clear()
        params:set('freeze', 0)

        crops.dirty.screen = true
    end
}

local input_route = 'stereo'
local input_pan = 0
local function update_input_pan()
    local idx = 3
    local off = (idx - 1) * 2
    local v = 1
    local p = output_route == 'split' and -1 or input_pan

    if input_route == 'stereo' then
        softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
        softcut.level_input_cut(2, off + 1, 0)
        softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
        softcut.level_input_cut(1, off + 2, 0)
    elseif input_route == 'mono' then
        softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
        softcut.level_input_cut(1, off + 2, v * ((p < 0) and 1 + p or 1))
        softcut.level_input_cut(2, off + 1, v * ((p > 0) and 1 - p or 1))
        softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
    end
end

params:add_separator('input')
do
    local idx = 3
    local off = (idx - 1) * 2

    local ir_op = { 'stereo', 'mono' } 
    params:add{
        type = 'option', id = 'input routing', options = ir_op, name = 'routing',
        action = function(v) 
            input_route = ir_op[v]; update_input_pan() 
        end
    }
    params:add{
        type = 'control', id = 'input pan', name = 'pan',
        controlspec = cs.def{ min = -1, max = 1, default = 0.7 },
        action = function(v) input_pan = v; update_input_pan() end
    }
end

local levels = { 1, 1, 1 }

local update_level = function(idx)
    local off = (idx - 1) * 2
    local p, v = 0, levels[idx]

    if output_route == 'stereo' then
        softcut.pan(off + 1, -1)
        softcut.pan(off + 2, 1)

        if idx==1 then p = -p end
        softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
        softcut.level(off + 2, v * ((p < 0) and 1 + p or 1))
    elseif output_route == 'split' then
        softcut.pan(off + 1, ({ -1, 1, 0 })[idx])
        softcut.pan(off + 2, 0)
        
        if idx==3 then 
            softcut.level(off + 1, 0)
        else
            softcut.level(off + 1, v)
        end
        softcut.level(off + 2, 0)
    end
end

params:add_separator('output')
do
    for idx = 1,3 do
        local off = (idx - 1) * 2
        local name = idx==3 and 'rec' or idx

        params:add{
            type='control', id = 'vol '..name,
            controlspec = cs.def { default = 1 },
            action = function(v) 
                levels[idx] = v; update_level(idx)

                crops.dirty.screen = true
            end
        }
        -- params:add{
        --     type='control', id = 'pan '..name,
        --     controlspec = cs.def { min = -1, max = 1, default = 0 },
        --     action = function(v) 
        --         pan = v; update() 
        --         crops.dirty.screen = true
        --     end
        -- }
    end
    
    local or_op = { 'stereo', 'split' } 
    params:add{
        type = 'option', id = 'output routing', options = or_op, name = 'routing',
        action = function(v) 
            output_route = or_op[v]
            for i = 1,3 do
                update_feedback(i)
                update_level(i)
            end
            update_input_pan()
        end
    }
end

params:add_separator('filter')
do
    local pre = 'hp'
    local post = 'lp'
    local both = { 'hp', 'lp' }
    local defaults = { hp = 0, lp = 1 }

    stereo('pre_filter_fc_mod', 3, 0)

    do
        local states = { 'enabled', 'bypass' }
        params:add{
            id = 'state', type = 'option', options = states,
            action = function(v)
                local dry, wet, action

                if states[v] == 'enabled' then
                    dry, wet = 0, 1
                    action = 'show'
                elseif states[v] == 'bypass' then
                    dry, wet = 1, 0
                    action = 'hide'
                end

                for i = 1,2 do
                    stereo('post_filter_dry', i, dry)
                    stereo('post_filter_'..post, i, wet)
                end
                stereo('pre_filter_dry', 3, dry)
                stereo('pre_filter_'..pre, 3, wet)

                for _,id in ipairs{ 'hp', 'lp', 'q' } do
                    params[action](params, id)
                end
                _menu.rebuild_params() --questionable?
            end

        }
    end

    for i,filter in ipairs(both) do
        local pre = filter==pre

        params:add {
            type = 'control', id = filter,
            controlspec = cs.def{ default = defaults[filter], quantum = 1/100/2, step = 0 },
            action = (
                pre and (
                    function(v) 
                        stereo('pre_filter_fc', 3, util.linexp(0, 1, 2, 20000, v)) 
                        crops.dirty.screen = true
                    end
                ) or (
                    function(v) 
                        for i = 1,2 do
                            stereo('post_filter_fc', i, util.linexp(0, 1, 2, 20000, v)) 
                            crops.dirty.screen = true
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
            
            crops.dirty.screen = true
        end
    }
end
    
params:set('rate 1', tab.key(rates[1].k, '2'))
params:set('rate 2', tab.key(rates[2].k, '-1/2'))
params:set('vol 1', 0.5)
params:set('vol rec', 0)
params:set('rec > rec', 0.5)

local function post_init()
    softcut.pan(2, -1)
    softcut.pan(1, 1)

    params:set('freeze', 0)
end

return post_init
