local p = {}

cs = require 'controlspec'

local buf_time = 16777216 / 48000 --exact time from the sofctcut source
local play_mar = 0.1
local rec_mar = 0.2
-- rec_fade = 0.1

local function stereo(command, pair, ...)
    local off = (pair - 1) * 2
    for i = 1, 2 do
        softcut[command](off + i, ...)
    end
end

function p.pre_init()
    audio.level_cut(1.0)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)

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
end

local function defaults(silent)
    params:set('rate 1', tab.key(rpls.rates[1].k, '2'), silent)
    params:set('rate 2', tab.key(rpls.rates[2].k, '-1/2'), silent)
    params:set('vol 1', 0.5 * 5, silent)
    params:set('vol rec', 0 * 5, silent)
    params:set('rec > rec', 0.5 * 5, silent)
    params:set('hp', 0.25 * 7, silent)
    params:set('lp', 0.8 * 7, silent)
end

function p.add_softcut_params()
    params:add_separator('rate')
    do
        local slew
        local function update_slew()
            for i = 1,6 do
                softcut.rate_slew_time(i, slew)
            end
        end
        local clk
        local reset = 0
        local function slew_temp(idx, v)
            local wait = v --0.1

            if clk then 
                rpls.set_param('slew', reset)
                clock.cancel(clk) 
            end
            clk = clock.run(function() 
                -- stereo('rate_slew_time', idx, v)

                reset = params:get('slew')
                rpls.set_param('slew', v)

                clock.sleep(wait)
                -- update_slew()
                rpls.set_param('slew', reset)
            end)
        end

        rpls.slew_temp = slew_temp

        local rate = { 1, 1, 1 }
        local wob = 0
        
        --TODO: just put the rates table in a dang global
        rpls.get_rate = function(idx)
            -- local k = (idx==3) and 'rec' or idx
            -- return rates[k].v[rate[idx]]
            return rate[idx]
        end

        local function update_rate()
            for i = 1,3 do
                stereo('rate', i, rate[i] + wob)
            end
        end
        patcher.add_destination_and_param{
            type='option', id = 'rate rec',
            options = rpls.rates.rec.k, default = tab.key(rpls.rates.rec.k, '1'),
            action = function(i)
                rate[3] = rpls.rates.rec.v[i]; update_rate()
                crops.dirty.screen = true
                crops.dirty.grid = true
            end
        }
        for idx = 1,2 do
            patcher.add_destination_and_param{
                type = 'option', id = 'rate '..idx,
                options = rpls.rates[idx].k, default = tab.key(rpls.rates[idx].k, '1'),
                action = function(i)
                    rate[idx] = rpls.rates[idx].v[i]; update_rate()
                    crops.dirty.screen = true
                    crops.dirty.grid = true
                end
            }
        end
        patcher.add_destination_and_param{
            type = 'control', id = 'slew',
            controlspec = cs.def{ min = 0, max = 0.5, default = 0.01, units = 's' },
            action = function(v)
                slew = v; update_slew()
                crops.dirty.screen = true
            end
        }
        patcher.add_destination_and_param{
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
        
    local freeze = 0

    params:add_separator('clock')
    do
        local function set_loop_points(t)
            local mar = (0.5*2) + (5*3)
            for i = 1,3 do
                rpls.loop_points[i][1] = (i - 1) * (mar)
                rpls.loop_points[i][2] = (i - 1) * (mar) + t
            end
        end

        local beats = 1

        local quant_secs = 0.005
        local quant

        function clock.tempo_change_handler(bpm)
            local beat_sec = 60 / bpm
            quant = quant_secs / beat_sec
            
            set_loop_points(beats * beat_sec)
        end
        clock.tempo_change_handler(clock.get_tempo())
        
        patcher.add_destination_and_param{
            type = 'control', id = 'clock mult',
            controlspec = cs.def { 
                min = 0, max = 8, default = 2, quantum = 1/4/32, units = 'v',
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

        local function res(i)
            local st = rpls.loop_points[rpls.heads[i]][1] --- 0.1
            local en = rpls.loop_points[rpls.heads[i]][2] + 0.14--+ 0.25
            local rate = rpls.get_rate(i)
            local rev = rate < 0

            stereo('position', i, rev and en or st)
            if rpls.crow_outputs_enabled then crow.output[i%3 + 1]() end

            rpls.tick[i] = 0
        end

        local function resall()
            table.insert(rpls.heads, 1, table.remove(rpls.heads, #rpls.heads))
            for i = 1,3 do
                res(i)
            end
            rpls.tick_all = 0
        end
       
        clock.run(function()
            while true do
                local time = beats

                if rpls.tick_all >= time then
                    resall()
                else
                    for i = 1,2 do
                        if rpls.tick[i] >= time then res(i) end
                    end
                end
                
                clock.sync(quant)

                for i = 1,3 do 
                    local rate = math.abs(rpls.get_rate(i))
                    rpls.tick[i] = rpls.tick[i] + (quant * rate)
                end
                rpls.tick_all = rpls.tick_all + quant

                if freeze == 0 then
                    rpls.tick_tri = (rpls.tick_tri + (quant / (math.max(beats, quant*1.2) * 3)))
                end

                crops.dirty.screen = true
                if rpls.grid_graphics then crops.dirty.grid = true end
            end
        end)

        patcher.add_destination_and_param{
            type='control', id='fade',
            controlspec = cs.def { default = 0.07, min = 0.0025, quantum = 1/100/10, step = 0, max = 0.5, units = 's' },
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
        patcher.add_destination_and_param{
            type = 'binary', behavior = 'trigger', id = 'reset',
            action = function()
                resall()
                
                crops.dirty.screen = true
            end
        }
    end

    local output_route = 'stereo'
    local feedback = { 0, 0, 0 }

    rpls.feedback = feedback

    local function update_feedback(idx)
        local off = (idx - 1) * 2
        local v = feedback[idx]

        if output_route == 'stereo' then
            softcut.level_cut_cut(1 + off, 1 + 4, 0)
            softcut.level_cut_cut(2 + off, 2 + 4, 0)
            softcut.level_cut_cut(1 + off, 2 + 4, v)
            softcut.level_cut_cut(2 + off, 1 + 4, v)
        elseif output_route == 'split' then
            softcut.level_cut_cut(1 + off, 1 + 4, v)
            softcut.level_cut_cut(2 + off, 2 + 4, v)
            softcut.level_cut_cut(1 + off, 2 + 4, 0)
            softcut.level_cut_cut(2 + off, 1 + 4, 0)
        end
    end

    local function ampdb(amp) return math.log(amp, 10) * 20.0 end
    local function dbamp(db) return 10.0^(db*0.05) end

    local function volt_amp(volt, db0val)
        local minval = -math.huge
        local maxval = 0
        local range = dbamp(maxval) - dbamp(minval)

        local scaled = volt/db0val
        local db = ampdb(scaled * scaled * range + dbamp(minval))
        local amp = dbamp(db)

        return amp
    end

    params:add_separator('feedback')
    for _,idx in pairs{ 3, 1, 2 } do
        local off = (idx - 1) * 2
        local name = idx==3 and 'rec' or idx

        patcher.add_destination_and_param{
            type = 'control', id = name..' > rec',
            controlspec = cs.def{ min = 0, max = 5, default = 0, units = 'v' },
            action = function(v)
                feedback[idx] = volt_amp(v, 5); update_feedback(idx)
                
                crops.dirty.screen = true
            end
        }
    end
    patcher.add_destination_and_param{
        type = 'binary', behavior = 'toggle', id = 'freeze',
        action = function(froze)
            freeze = froze

            stereo('pre_level', 3, froze)
            stereo('rec_level', 3, ~ froze & 1)

            crops.dirty.screen = true
            crops.dirty.grid = true
        end
    }
    patcher.add_destination_and_param{
        type = 'binary', behavior = 'trigger', id = 'clear',
        action = function()
            softcut.buffer_clear()
            params:set('freeze', 0)

            crops.dirty.screen = true
            crops.dirty.grid = true
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

    rpls.levels = levels

    local update_level = function(idx)
        local off = (idx - 1) * 2
        local p, v = 0, levels[idx]

        if output_route == 'stereo' then
            if idx==1 then
                softcut.pan(off + 1, 1)
                softcut.pan(off + 2, -1)
            else
                softcut.pan(off + 1, -1)
                softcut.pan(off + 2, 1)
            end

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

            patcher.add_destination_and_param{
                type='control', id = 'vol '..name,
                controlspec = cs.def{ min = 0, max = 5, default = 4, units = 'v' },
                action = function(v) 
                    levels[idx] = volt_amp(v, 4); update_level(idx)

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
        stereo('pre_filter_dry', 3, 0)
        stereo('pre_filter_'..pre, 3, 1)

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

                    params[action](params, 'lp')
                    _menu.rebuild_params() --questionable?

                    rpls.pages = {
                        'C', 'R', '>', params:string('state') == 'enabled' and 'F' or nil 
                    }

                    crops.dirty.screen = true
                    crops.dirty.grid = true
                end
            }
        end

        for i,filter in ipairs(both) do
            local pre = filter==pre

            patcher.add_destination_and_param {
                type = 'control', id = filter,
                controlspec = cs.def{ 
                    default = defaults[filter] * 7, quantum = 1/100/2, step = 0, units = 'v',
                    min = 0, max = 7,
                },
                action = (
                    pre and (
                        function(v) 
                            stereo('pre_filter_fc', 3, util.linexp(0, 1, 2, 20000, v/7)) 
                            crops.dirty.screen = true
                        end
                    ) or (
                        function(v) 
                            for i = 1,2 do
                                stereo('post_filter_fc', i, util.linexp(0, 1, 2, 20000, v/7)) 
                                crops.dirty.screen = true
                            end
                        end
                    )
                )
            }
        end
        patcher.add_destination_and_param {
            type = 'control', id = 'q',
            controlspec = cs.def{ default = 0.4 * 5, min = 0, max = 5 },
            action = function(v)
                for i = 1,2 do
                    stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v/5))
                end
                stereo('pre_filter_rq', 3, util.linexp(0, 1, 0.01, 20, 1 - v/5))
                
                crops.dirty.screen = true
            end
        }
    end

    defaults()
end
    
function p.add_patcher_params()
    params:add_separator('patcher')
    params:add_group('assignments', #patcher.destinations)
    patcher.add_assignment_params(function() 
        crops.dirty.screen = true
    end)
end
    
--add pset params
function p.add_pset_params()
    params:add_separator('pset')

    params:add{
        id = 'reset all params', type = 'binary', behavior = 'trigger',
        action = function()
            for _,p in ipairs(params.params) do if p.save then
                params:set(p.id, p.default or (p.controlspec and p.controlspec.default) or 0, true)
            end end

            defaults(true)
    
            params:bang()
        end
    }
    params:add{
        id = 'overwrite default pset', type = 'binary', behavior = 'trigger',
        action = function()
            params:write()
        end
    }
    params:add{
        id = 'autosave pset', type = 'option', options = { 'yes', 'no' },
        action = function()
            params:write()
        end
    }
end

function p.post_init()
    params:set('freeze', 0)
end

return p
