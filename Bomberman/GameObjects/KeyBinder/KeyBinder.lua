local gkeyTypes;

function Local.Init(p1list, p2list, keyTypes)
    local project_config_file = obe.System.Path("projectcfg://config.vili"):find();
    if project_config_file:success() then
        goAway = true;
        This.Sprite:setVisible(false);
        return;
    end

    gkeyTypes = keyTypes;
    local window_size = Engine.Window:getSize();
    canvas = obe.Canvas.Canvas(window_size.x, window_size.y);
    p1label = canvas:Text("p1label")(
        {
            text = "Player 1 Configuration :",
            size = 72,
            x = 0,
            y = window_size.y / 2 - 200,
            color = {r = 0, g = 0, b = 0, a = 255}
        }
    );
    p2label = canvas:Text("p2label")(
        {
            text = "Player 2 Configuration :",
            size = 72,
            x = window_size.x / 2,
            y = window_size.y / 2 - 200,
            color = {r = 0, g = 0, b = 0, a = 255}
        }
    );

    waitForZero = false;
    confs = {};
    indexes = {P1 = 2, P2 = 2};
    confs.P1 = canvas:Text("p1conf")(
        {
            text = p1list[1] .. " Button : ",
            size = 42,
            x = 50,
            y = window_size.y / 2 - 100,
            color = {r = 0, g = 0, b = 0, a = 255}
        }
    );
    confs.P2 = canvas:Text("p2conf")(
        {
            text = "",
            size = 42,
            x = window_size.x / 2 + 50,
            y = window_size.y / 2 - 100,
            color = {r = 0, g = 0, b = 0, a = 255}
        }
    );
    lists = {P1 = p1list, P2 = p2list};
    current = "P1";
    configure = true;
    canvas:render(This.Sprite);
    config = {};
    goAway = false;
    launched = false;
end

function Event.Game.Update(evt)
    if configure then
        local allPressedButtons = Engine.Input:getPressedInputs();
        if waitForZero then
            if #allPressedButtons == 0 then
                waitForZero = false;
            end
        elseif #allPressedButtons > 0 then
            local pressedButton = allPressedButtons[1]:getName();
            confs[current].text = confs[current].text .. pressedButton;
            config[lists[current][indexes[current] - 1]] = pressedButton;

            if indexes[current] > #lists[current] then
                if current == "P1" then
                    current = "P2";
                    confs[current].text = lists[current][1] .. " Button : ";
                else
                    configure = false;
                    SaveConfiguration();
                end
            else
                confs[current].text = confs[current].text .. "\n" ..
                                          lists[current][indexes[current]] .. " Button : ";
                indexes[current] = indexes[current] + 1;
            end
            canvas:render(This.Sprite);
            waitForZero = true;
        end
    end
    if goAway then
        Engine.Scene:getCamera():setSize(
            Engine.Scene:getCamera():getSize().y / 2 - 1 * evt.dt, obe.Transform.Referential.Center
        );
        if Engine.Scene:getCamera():getSize().y < 0 and not launched then
            goAway = false;
            launched = true;
            LaunchGame();
        end
    end
end

function SaveConfiguration()
    local input_game_config = {};
    for action_name, input_name in pairs(config) do
        input_game_config[action_name] = gkeyTypes[action_name] .. ":" .. input_name;
    end
    local input_config = {game = input_game_config};
    local full_config = {Input = input_config};
    vili.to_file("projectcfg://config.vili", full_config);
    goAway = true;
    Engine.Input:configure(vili.from_lua(input_config));
end

function LaunchGame()
    Engine.Scene:loadFromFile("scenes://main.map.vili");
end

function Local.Delete()

end
