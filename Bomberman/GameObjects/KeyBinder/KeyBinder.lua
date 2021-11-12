function Local.Init(p1list, p2list, keyTypes)
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
    print("before sprite assignment");
    local s = This:getSprite();
    print("target will be", s);
    canvas:render(This.Sprite);
    config = {};
    goAway = false;
    launched = false;
end

function Event.Game.Update(dt)
    if configure then
        local allPressedButtons = obe.Input.GetAllPressedButtons();
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
            canvas:render();
            waitForZero = true;
        end
    end
    if goAway then
        Engine.Scene:getCamera():setSize(
            Engine.Scene:getCamera():getSize().y / 2 - 1 * dt, obe.Referential.Center
        );
        if Engine.Scene:getCamera():getSize().y < 0 and not launched then
            goAway = false;
            launched = true;
            LaunchGame();
        end
    end
end

function SaveConfiguration()
    local configPath = obe.Path("Data/config.cfg.vili"):find();
    binding = Vili.ViliParser(configPath);
    for k, v in pairs(config) do
        binding:root():at("KeyBinding", "game"):getDataNode(k):set(gkeyTypes[k] .. ":" .. v);
    end
    binding:writeFile(configPath);
    goAway = true;
    InputManager:configure(binding:root():at("KeyBinding"));
end

function LaunchGame()
    Engine.Scene:loadFromFile('Main.map.vili');
end

function Local.Delete()

end
