function Local.Init()
    InitializeBindings();
    Object.level = 1;
    Object.victory = false;
    Scene:createLevelSprite("victory_sprite");
    victory_sprite = Scene:getLevelSprite("victory_sprite");
    victory_sprite:setParentId(This:getId());
    victory_sprite:setVisible(false);
    victory_sprite:loadTexture("Sprites/LevelSprites/victory.png");
    victory_sprite:setZDepth(0.0)
    victory_sprite:useTextureSize()
    Object.ratio_victory_sprite = {x=victory_sprite:getSize().x/Scene:getCamera():getSize().x, y=victory_sprite:getSize().y/Scene:getCamera():getSize().y}

    Scene:loadFromFile("Sokoban.map.vili", function() 
        Scene:getGameObject("Terrain"):init(obe.Path("Data/Maps/level" .. Object.level .. ".txt"):find()) 
    end);

end

function InitializeBindings()
    Global.Actions["Reset"] = function()
        if Scene:getLevelName() == "Sokoban" then
            Object.victory = false;
            Scene:getGameObject("Terrain"):uninit();
            Scene:reload(function() Scene:getGameObject("Terrain"):init(obe.Path("Data/Maps/level" .. Object.level .. ".txt"):find()) end);
        end
    end
    Global.Actions["Next"] = function()
        if Scene:getLevelName() == "Sokoban" and Object.victory then
            Object.level = Object.level + 1;
            Object.victory = false;
            Scene:getGameObject("Terrain"):uninit();
            Scene:reload(function() 
                Scene:getGameObject("Terrain"):init(obe.Path("Data/Maps/level" .. Object.level .. ".txt"):find());
            end);
        end
    end
end


function Global.Game.Update(dt)
    if Scene:doesGameObjectExists("Terrain") and Scene:getGameObject("Terrain").initialized then
        if not Object.victory then
            victory_sprite:setVisible(false);
            Object.victory = true
            for i, v in pairs(Scene:getGameObject("Terrain").elements) do
                for j, v2 in pairs(v) do
                    if v2 ~= nil and v2[2] ~= nil and v2[2]:getType() == "Barrel" then
                        Object.victory = v2[2].activated and Object.victory or false
                    end
                end
            end
        end
        if Object.victory then
            victory_sprite:setSize(obe.UnitVector(Object.ratio_victory_sprite.x * Scene:getCamera():getSize().x, Object.ratio_victory_sprite.y * Scene:getCamera():getSize().y), obe.Referential.Center)
            victory_sprite:setPosition(Scene:getCamera():getPosition(obe.Referential.Center), obe.Referential.Center);
            victory_sprite:setVisible(true);
        end
    end
end
