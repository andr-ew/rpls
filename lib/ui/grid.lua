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


local function App(args)
    local wide = args.wide
    local y = args.y

    local _focus = Grid.integer()
    local _freeze = Togglehold()

    return function()
        local right = (wide and 16 or 8) 

        _freeze {
            x = right, y = y, levels = { 4, 8, 15 },
            id_toggle = 'freeze', id_hold = 'clear', 
        }

        _focus{
            x = right - 2 - #rpls.pages + 1, y = y, size = #rpls.pages, 
            levels = { 4, 15 },
            state = crops.of_variable(rpls.page_focus, function(v) 
                rpls.page_focus = v

                crops.dirty.screen = true 
                crops.dirty.grid = true 
            end),
        }
    end
end
    
return App
