function Local.Init()
    Object.level = 1;
    Object.victory = false;

    victory_sprite = Engine.Scene:createSprite("victory_sprite");
    victory_sprite:setParentId(This:getId());
    victory_sprite:setVisible(false);
    victory_sprite:loadTexture("Sprites/Scenes/victory.png");
    victory_sprite:setZDepth(0);
    victory_sprite:useTextureSize();

    local camera_size = Engine.Scene:getCamera():getSize();
    Object.ratio_victory_sprite = {
        x = victory_sprite:getSize().x / camera_size.x,
        y = victory_sprite:getSize().y / camera_size.y
    }

    Engine.Scene:loadFromFile("Data/Maps/Sokoban.map.vili", function()
        Engine.Scene:getGameObject("Terrain"):init(
            obe.System.Path("Data/Maps/level" .. Object.level .. ".txt"):find())
    end);

end

function Event.Actions.Reset()
    if Engine.Scene:getLevelName() == "Sokoban" then
        Object.victory = false;
        Engine.Scene:getGameObject("Terrain"):uninit();
        Engine.Scene:reload(function()
            Engine.Scene:getGameObject("Terrain"):init(
                obe.System.Path("Data/Maps/level" .. Object.level .. ".txt"):find())
        end);
    end
end

function Event.Actions.Next()
    if Engine.Scene:getLevelName() == "Sokoban" and Object.victory then
        Object.level = Object.level + 1;
        Object.victory = false;
        Engine.Scene:getGameObject("Terrain"):uninit();
        Engine.Scene:reload(function()
            Engine.Scene:getGameObject("Terrain"):init(
                obe.System.Path("Data/Maps/level" .. Object.level .. ".txt"):find());
        end);
    end
end

function Event.Game.Update(dt)
    if Engine.Scene:doesGameObjectExists("Terrain") and
        Engine.Scene:getGameObject("Terrain").initialized then
        if not Object.victory then
            victory_sprite:setVisible(false);
            Object.victory = true
            for i, v in pairs(Engine.Scene:getGameObject("Terrain").elements) do
                for j, v2 in pairs(v) do
                    if v2 ~= nil and v2[2] ~= nil and v2[2]:getType() ==
                        "Barrel" then
                        Object.victory =
                            v2[2].activated and Object.victory or false
                    end
                end
            end
        end
        if Object.victory then
            victory_sprite:setSize(obe.Transform.UnitVector(
                                       Object.ratio_victory_sprite.x *
                                           Engine.Scene:getCamera():getSize().x,
                                       Object.ratio_victory_sprite.y *
                                           Engine.Scene:getCamera():getSize().y),
                                   obe.Transform.Referential.Center)
            victory_sprite:setPosition(Engine.Scene:getCamera():getPosition(
                                           obe.Transform.Referential.Center),
                                       obe.Transform.Referential.Center);
            victory_sprite:setVisible(true);
        end
    end
end

function Event.Game.Render()
    collectgarbage();
end