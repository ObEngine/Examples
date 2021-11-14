function makeTexture(name, path)
    local texture = Engine.Scene:createSprite(name);
    texture:setPosition(obe.Transform.UnitVector(2.4, 1));
    texture:setSize(obe.Transform.UnitVector(1, 0.5));
    texture:loadTexture(path);
    texture:setVisible(false);
    return texture;
end

function Local.Init()
    Object.character1 = Engine.Scene:getGameObject("character1");
    Object.character2 = Engine.Scene:getGameObject("character2");

    Object.nobody_win = makeTexture("nobody_win", "Sprites/GameObjects/Game/nobody_win.png");
    Object.p1_win = makeTexture("p1_win", "Sprites/GameObjects/Game/p1_win.png");
    Object.p2_win = makeTexture("p2_win", "Sprites/GameObjects/Game/p2_win.png");
    Object.run_again = false;
    Object.run_again_count = 0;
end

function Event.Game.Update(evt)
    if not Object.run_again then
        if Object.character1.dead and Object.character2.dead then
            Object.nobody_win:setVisible(true);
            Object.run_again = true;
        elseif Object.character1.dead then
            Object.p2_win:setVisible(true);
            Object.run_again = true;
        elseif Object.character2.dead then
            Object.p1_win:setVisible(true);
            Object.run_again = true;
        end
    end
    if Object.run_again then
        Object.run_again_count = Object.run_again_count + evt.dt;
    end
    if Object.run_again_count > 5 then
        Engine.Scene:loadFromFile("scenes://main.map.vili");
    end
end
