local function Togglehold()
    local downtime = nil
    local blink = false

    local _fill = Grid.toggle()

    return function(props)
        if crops.device == 'grid' then
            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args) 

                if x == props.x and y == props.y then
                    if z==1 then
                        downtime = util.time()
                    elseif z==0 then
                        if downtime and ((util.time() - downtime) > 0.5) then 
                            print('togglehold clear')

                            -- blink = true
                            -- blink_level = 1
                            blink = true
                            crops.dirty.grid = true

                            clock.run(function() 
                                -- clock.sleep(0.1)
                                -- blink = 1
                                -- crops.dirty.grid = true

                                params:delta(props.id_hold)

                                clock.sleep(0.2)
                                blink = false
                                -- crops.dirty.grid = true

                                -- clock.sleep(0.4)
                                -- blink = false
                                crops.dirty.grid = true
                            end)
                        else
                            params:delta(props.id_toggle)
                        end
                        
                        downtime = nil
                    end
                end
            else
                local g = crops.handler
                
                local lvl = props.levels[blink and 3 or (params:get(props.id_toggle) + 1)]

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

local function UI(args)
    local wide = args.wide
    local y = args.y

    local _focus = Grid.integer()
    local _freeze = Togglehold()
    local _wob = Grid.momentary()

    local _rates = {}
    for i = 1,3 do _rates[i] = Produce.grid.integer_trigger() end

    local downtimes = {}

    return function(props)
        local right = (wide and 16 or 8) 

        _freeze {
            x = right, y = y, levels = { 4, 8, 15 },
            id_toggle = 'freeze', id_hold = 'clear', 
        }

        _focus{
            x = right - 2 - #rpls.pages + 1, y = y, size = #rpls.pages, 
            levels = { 4, props.focused and 15 or 6 },
            state = crops.of_variable(rpls.page_focus, function(v) 
                rpls.page_focus = v
                crops.dirty.screen = true 
                crops.dirty.grid = true 
            end),
            input = function()
                script_focus = 'rpls'
            end
        }

        if wide then
            _wob{
                x = 3, y = y, state = rpls.of_param('~'),
            }

            for i,k in ipairs({ 1, 2, 'rec' }) do
                local id = 'rate '..k
                local p = params:lookup_param(id)

                _rates[i]{
                    x = ((i%3) * 3) + 1, y = y, edge = 'falling', 
                    levels = { 4, 15 }, min = 1, max = #p.options, wrap = false,
                    -- state = crops.of_param(id),
                    state = crops.of_variable(
                        rpls.get_param(id),
                        function(v)
                            local t = util.time() - (downtimes[i] or util.time())
                            local st = (1.75 + (math.random() * 0.5)) * (t)

                            rpls.slew_temp(i, st)
                            rpls.set_param(id, v)

                            downtime = nil
                        end
                    ),
                    input = function(n, z) if z==1 then
                        downtimes[i] = util.time()
                    end end
                }
            end
        end
    end
end

local function Graphics(args)
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then
            local g = crops.handler
                
            local beats = patcher.get_value_by_destination('clock mult')

            --draw left side
            do
                local ph = math.min(rpls.tick[1] / beats, 1)
                local pos = rpls.get_rate(1) > 0 and ph or 1-ph
                local d = math.floor(pos * 6)

                for i = 0,5 do
                    g:led(i + 3, 8 - i, 4) 
                end
                g:led(d + 3, 8 - d, 8)
            end
            --draw right side
            do
                local ph = math.min(rpls.tick[2] / beats, 1)
                local pos = rpls.get_rate(2) > 0 and ph or 1-ph
                local d = math.floor(pos * 6)

                for i = 0,5 do
                    g:led(i + 8, 3 + i, 4) 
                end

                g:led(d + 8, 3 + d, 8)
            end
            --draw bottom
            do
                local ph = math.min(rpls.tick[3] / beats, 1)

                for i = 0,8 do
                    g:led(4 + i, 8, 4)
                end
                g:led(3 + math.floor(ph * 10), 8, 8)
            end
        end
    end
end

local function App(args)
    local _ui = UI(args)
    local _gfx = Graphics()

    return function()
        -- local right = 16
        
        _ui{ focused = true }
        _gfx()
    end
end
    
return App, UI, Graphics
