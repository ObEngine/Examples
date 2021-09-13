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

function GetMovingAngle(active_movements)
    local dx = 0;
    local dy = 0;
    for movement_direction, movement_state in pairs(active_movements) do
        if movement_state then
            dx = dx + MOVEMENTS[movement_direction].dx;
            dy = dy + MOVEMENTS[movement_direction].dy;
        end
    end
    if dx >= 0 then return math.deg(math.atan(dy/dx));
    else return math.deg(math.atan(dy/dx) + math.pi);
    end
end

function Local.Init(x, y)
    This.SceneNode:moveWithoutChildren(This.Collider:getCentroid());
    This.Collider:addTag(obe.Collision.ColliderTagType.Rejected, "Character");
    Object.active_movements = {left = false, right = false, up = false, down = false};
    TILE_SIZE = obe.Transform.UnitVector(0, Engine.Scene:getTiles():getTileHeight(), obe.Transform.Units.ScenePixels):to(obe.Transform.Units.SceneUnits).y;
    print("Sprite before", This.Sprite:getPosition());
    This.SceneNode:setPosition(obe.Transform.UnitVector(x, y, obe.Transform.Units.ScenePixels));
    print("Sprite after", This.Sprite:getPosition());
    Trajectories = obe.Collision.TrajectoryNode(This.SceneNode);
    Trajectories:setProbe(This.Collider);
    trajectory = Trajectories:addTrajectory("direction"):setSpeed(0):setAngle(-90):setAcceleration(0);

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

Event.Actions.Up = SetMove("up", true);
Event.Actions.Down = SetMove("down", true);
Event.Actions.Left = SetMove("left", true);
Event.Actions.Right = SetMove("right", true);
Event.Actions.RUp = SetMove("up", false);
Event.Actions.RDown = SetMove("down", false);
Event.Actions.RLeft = SetMove("left", false);
Event.Actions.RRight = SetMove("right", false);

function Event.Game.Update(event)
    This.Sprite:setZDepth(-math.floor(This.SceneNode:getPosition().y * 1000));
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

function Object:GetCurrentPosition()
    local camera_scale = Engine.Scene:getCamera():getSize().y / 2;
    local tile_width = Engine.Scene:getTiles():getTileWidth() / camera_scale;
    local tile_height = Engine.Scene:getTiles():getTileHeight() / camera_scale;
    local px_position = This.Collider:getCentroid():to(obe.Transform.Units.ScenePixels);
    local x = math.floor(px_position.x / tile_width);
    local y = math.floor(px_position.y / tile_height);
    return {x=x, y=y};
end