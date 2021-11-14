Object.Terrain = {};
Object.TerrainElements = {};

function inASpawnZone(x, y)
    if not (x == 1 and y == 1) and not (x == 2 and y == 1) and not (x == 1 and y == 2) and
        not (x == 11 and y == 9) and not (x == 10 and y == 9) and not (x == 11 and y == 8) and
        not (x == 11 and y == 1) and not (x == 10 and y == 1) and not (x == 11 and y == 2) and
        not (x == 1 and y == 9) and not (x == 2 and y == 9) and not (x == 1 and y == 8) then
        return false;
    else
        return true;
    end
end

function Local.Init()
    for x = 0, 12, 1 do
        Object.Terrain[x + 1] = {};
        Object.TerrainElements[x + 1] = {};
        for y = 0, 10, 1 do
            local terrainType;
            if x == 0 or y == 0 or x == 12 or y == 10 then
                if y == 10 or (y == 0 and x ~= 0 and x ~= 12) then
                    terrainType = "Bloc";
                else
                    terrainType = "SideBloc";
                end
            elseif x % 2 == 0 and y % 2 == 0 then
                terrainType = "Bloc";
            else
                terrainType = "Grass";
            end
            local newTerrainElement = Engine.Scene:createGameObject(
                "Tile", tostring(x) .. "-" .. tostring(y)
            )({tileType = terrainType, solid = true});
            local elementPosition = obe.Transform.UnitVector(
                x * newTerrainElement.Sprite:getSize().x, y * newTerrainElement.Sprite:getSize().y
            );
            newTerrainElement.Sprite:setPosition(elementPosition, obe.Transform.Referential.TopLeft);
            if terrainType == "Grass" then
                if (y % 2 == 0 and x % 2 ~= 0) and not inASpawnZone(x, y) and math.random(6) ~= 1 then
                    local newBox = Engine.Scene:createGameObject(
                        "Box", tostring(x) .. "-" .. tostring(y) .. "-Box"
                    )();
                    newBox.Sprite:setPosition(elementPosition, obe.Transform.Referential.TopLeft);
                    Object.TerrainElements[x + 1][y + 1] = newBox;
                    terrainType = "Box";
                elseif not inASpawnZone(x, y) and math.random(6) ~= 1 then
                    local newBush = Engine.Scene:createGameObject(
                        "Bush", tostring(x) .. "-" .. tostring(y) .. "-Bush"
                    )();
                    newBush.Sprite:setPosition(elementPosition, obe.Transform.Referential.TopLeft);
                    Object.TerrainElements[x + 1][y + 1] = newBush;
                    terrainType = "Bush";
                end
                newTerrainElement.Sprite:setZDepth(3);
            end
            Object.Terrain[x + 1][y + 1] = terrainType;
        end
    end
    print("Generating Terrain OK");
end

function Object:get(x, y)
    if x >= 1 and x <= 12 and y >= 1 and y <= 10 then
        return self.Terrain[x][y];
    else
        return nil;
    end
end

function Object:removeElementAtPos(x, y)
    if x >= 1 and x <= 12 and y >= 1 and y <= 10 then
        if Object.TerrainElements[x][y] ~= nil then
            Object.TerrainElements[x][y]:delete();
            Object.TerrainElements[x][y] = nil;
            Object.Terrain[x][y] = "Grass";
        end
    end
end
