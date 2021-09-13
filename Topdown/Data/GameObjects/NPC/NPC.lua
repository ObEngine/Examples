local path;
local path_index = 1;
local next_position;
local pcache;
local world;

local character_speed = 0.15;
local trajectory;
local OFFSET_EPSILON = 0.0000001;

local DIRECTIONS = {"left", "right", "up", "down"};
local MOVEMENTS = {
    up = {dx = 0, dy = 1},
    down = {dx = 0, dy = -1},
    left = {dx = -1, dy = 0},
    right = {dx = 1, dy = 0},
}

function SetMove(direction, state)
    return function() Object.active_movements[direction] = state; end
end

function IsMoving()
    for k, v in pairs(Object.active_movements) do
        if v == true then return true; end
    end
    return false;
end

function TranslationToAngle(dx, dy)
    if dx >= 0 then return math.deg(math.atan(dy/dx));
    else return math.deg(math.atan(dy/dx) + math.pi);
    end
end

function GetMovingAngle(active_movements)
    local dx = 0;
    local dy = 0;
    for movement_direction, movement_state in pairs(active_movements) do
        if movement_state then
            dx = dx + MOVEMENTS[movement_direction].dx;
            dy = dy + MOVEMENTS[movement_direction].dy;
        end
    end
    return TranslationToAngle(dx, dy);
end

function Local.Init(x, y)
    This.SceneNode:moveWithoutChildren(This.Collider:getCentroid());
    local render_options = obe.Scene.SceneRenderOptions();
    -- render_options.collisions = true;
    -- render_options.sceneNodes = true;
    Engine.Scene:setRenderOptions(render_options);

    world = BuildWorldMatrix();
    This.Collider:addTag(obe.Collision.ColliderTagType.Accepted, "NONE");
    -- local bbox_size = This.Collider:getBoundingBox():getSize();
    -- This.Collider:move(bbox_size/2);
    Object.active_movements = {left = false, right = false, up = false, down = false};
    TILE_SIZE = obe.Transform.UnitVector(0, Engine.Scene:getTiles():getTileHeight(), obe.Transform.Units.ScenePixels):to(obe.Transform.Units.SceneUnits).y;
    This.SceneNode:setPosition(obe.Transform.UnitVector(x, y, obe.Transform.Units.ScenePixels));
    Trajectories = obe.Collision.TrajectoryNode(This.SceneNode);
    Trajectories:setProbe(This.Collider);
    trajectory = Trajectories:addTrajectory("direction"):setSpeed(0):setAngle(-90):setAcceleration(0);

    trajectory:onCollide(function()
        path = nil;
        next_position = nil;
    end);
    -- Sliding against walls when more than one direction is active
    trajectory:addCheck(function(self, offset)
        local collision = This.Collider:getMaximumDistanceBeforeCollision(offset);
        if #collision.colliders > 0 then
            if math.abs(offset.x) > OFFSET_EPSILON and math.abs(offset.y) > OFFSET_EPSILON then
                local nox_offset = obe.Transform.UnitVector(0, offset.y, offset.unit);
                local noy_offset = obe.Transform.UnitVector(offset.x, 0, offset.unit);
                local angle = trajectory:getAngle();
                if #This.Collider:getMaximumDistanceBeforeCollision(nox_offset).colliders == 0 then
                    angle = GetMovingAngle({up=Object.active_movements.up, down=Object.active_movements.down});
                elseif #This.Collider:getMaximumDistanceBeforeCollision(noy_offset).colliders == 0 then
                    angle = GetMovingAngle({left=Object.active_movements.left, right=Object.active_movements.right});
                end
                trajectory:setAngle(angle);
                trajectory:setSpeed(character_speed / 2);
            end
        end
    end);
end

function ComputeNextMove()
    local position = GetCurrentPosition();
    if next_position ~= nil then
        if position.x == next_position.x and position.y == next_position.y then
            if path ~= nil and path_index < #path then
                path_index = path_index + 1;
                next_position = path[path_index];
            else
                path = nil;
                path_index = 1;
            end
        end
    elseif path ~= nil then
        path_index = 1;
        next_position = path[path_index];
    end
    Object.active_movements = {left=false, right=false, up=false, down=false};
    if next_position ~= nil then
        local dx = next_position.x - position.x;
        local dy = -(next_position.y - position.y);

        if dx < 0 then Object.active_movements.left = true end
        if dx > 0 then Object.active_movements.right = true end
        if dy < 0 then Object.active_movements.down = true end
        if dy > 0 then Object.active_movements.up = true end
    else
        trajectory:setSpeed(0);
    end
end

local old_position = {x=nil, y=nil};
function Event.Game.Update(event)
    ComputeNextMove();

    local cpos = GetCurrentPosition();
    if cpos.x ~= old_position.x or cpos.y ~= old_position.y then
        old_position = {x=cpos.x, y=cpos.y};
        local path_length = "?";
        if path ~= nil then
            path_length = #path;
        end
        print(path_index - 1, "/", path_length, "x=", old_position.x, "y=", old_position.y);
    end

    This.Sprite:setZDepth(-math.floor(This.Collider:getCentroid().y * 1000));
    if IsMoving() then
        local angle = GetMovingAngle(Object.active_movements);
        -- Discard nan results
        if angle == angle then
            for _, movement_name in pairs(DIRECTIONS) do
                if Object.active_movements[movement_name] then
                    This.Animator:setKey("MOVE_" .. movement_name:upper());
                    break;
                end
            end
            trajectory:setSpeed(character_speed);
            trajectory:setAngle(angle);
        end
    else
        trajectory:setSpeed(0);
        This.Animator:setKey("IDLE_" .. This.Animator:getKey():gmatch("_([^%s]+)")())
    end
    Trajectories:update(event.dt);
end

function BuildWorldNodes()
    local collider_models = Engine.Scene:getTiles():getColliderModels();
    local collider_table = {};
    for _, collider in pairs(collider_models) do
        collider_table[collider:getId()] = collider;
    end
    print("Collider table", inspect(collider_table));
    local layers = Engine.Scene:getTiles():getAllLayers();
    local world_width = Engine.Scene:getTiles():getWidth();
    local world_height = Engine.Scene:getTiles():getHeight();
    local nodes = {};
    for y = 0, world_height - 1, 1 do
        for x = 0, world_width - 1, 1 do
            local nocollision = true;
            for _, layer in pairs(layers) do
                local tile = layer:getTile(x, y);
                if tile ~= 0 then
                    if collider_table[tostring(tile)] ~= nil then
                        nocollision = false;
                    end
                end
            end
            if nocollision then
                table.insert(nodes, {x=x, y=y});
            end
        end
    end
    return nodes;
end

function BuildWorldMatrix()
    local collider_models = Engine.Scene:getTiles():getColliderModels();
    local collider_table = {};
    for _, collider in pairs(collider_models) do
        collider_table[collider:getId()] = collider;
    end
    local layers = Engine.Scene:getTiles():getAllLayers();
    local world_width = Engine.Scene:getTiles():getWidth();
    local world_height = Engine.Scene:getTiles():getHeight();
    local world = {};
    for x = 1, world_width, 1 do
        world[x] = {};
        for y = 1, world_height, 1 do
            local nocollision = true;
            for _, layer in pairs(layers) do
                local tile = layer:getTile(x - 1, y - 1);
                if tile ~= 0 then
                    if collider_table[tostring(tile)] ~= nil then
                        nocollision = false;
                    end
                end
            end
            world[x][y] = nocollision;
        end
    end
    for y = 1, world_height, 1 do
        for x = 1, world_width, 1 do
            if world[x][y] then io.write(" ") else io.write("X") end
        end
        io.write("\n");
    end
    return world;
end

function FixPosition()
    local position = GetCurrentPosition();
    local scene_node_offset = This.SceneNode:getPosition() - This.Collider:getPosition();
    local camera_scale = Engine.Scene:getCamera():getSize().y / 2;
    local tile_width = Engine.Scene:getTiles():getTileWidth() / camera_scale;
    local tile_height = Engine.Scene:getTiles():getTileHeight() / camera_scale;
    local px_position = obe.Transform.UnitVector(tile_width * position.x, tile_height * position.y, obe.Transform.Units.ScenePixels);
    This.SceneNode:setPosition(px_position + scene_node_offset);
end

function GetCurrentPosition()
    local camera_scale = Engine.Scene:getCamera():getSize().y / 2;
    local tile_width = Engine.Scene:getTiles():getTileWidth() / camera_scale;
    local tile_height = Engine.Scene:getTiles():getTileHeight() / camera_scale;
    local px_position = This.Collider:getCentroid():to(obe.Transform.Units.ScenePixels);
    local x = math.floor(px_position.x / tile_width);
    local y = math.floor(px_position.y / tile_height);
    return {x=x+1, y=y+1};
end

function GetCursorPosition()
    local camera_scale = Engine.Scene:getCamera():getSize().y / 2;
    local tile_width = Engine.Scene:getTiles():getTileWidth() / camera_scale;
    local tile_height = Engine.Scene:getTiles():getTileHeight() / camera_scale;
    local px_position = Engine.Cursor:getScenePosition();
    px_position = px_position + Engine.Scene:getCamera():getPosition();
    local x = math.floor(px_position.x / tile_width);
    local y = math.floor(px_position.y / tile_height);
    return {x=x+1, y=y+1};
end

local astar = require "scripts://LuaFinding";
function ValidNodeFunc(node, neighbor)
    local distance = astar.distance(node.x, node.y, neighbor.x, neighbor.y);
    return distance <= 1;
end

function FollowMe()
    local position = GetCurrentPosition();
    local destination = Engine.Scene:getGameObject("character"):GetCurrentPosition();
    if pcache ~= nil and pcache.x == destination.x and pcache.y == destination.y then
        return;
    end
    pcache = destination;

    path = astar.FindPath(astar.Vector(position.x, position.y), astar.Vector(destination.x, destination.y), world);
end

function Event.Actions.Goto()
    local position = GetCurrentPosition();
    local destination = GetCursorPosition();

    print("From", position.x, position.y, "To", destination.x, destination.y);
    path = astar.FindPath(astar.Vector(position.x, position.y), astar.Vector(destination.x, destination.y), world);

    local world_width = Engine.Scene:getTiles():getWidth();
    local world_height = Engine.Scene:getTiles():getHeight();

    for y = 1, world_height, 1 do
        for x = 1, world_width, 1 do
            local fpath = false;
            if path ~= nil then
                for i, path_part in pairs(path) do
                    if path_part.x == x and path_part.y == y then
                        if i == 1 then
                            fpath = "S";
                        elseif i == #path then
                            fpath = "E";
                        elseif world[x][y] then
                            fpath = ".";
                        else
                            fpath = "X";
                        end
                    end
                end
            end
            if fpath ~= false then
                io.write(fpath);
            elseif world[x][y] then
                io.write(" ");
            else
                io.write("#");
            end
        end
        io.write("\n");
    end
end