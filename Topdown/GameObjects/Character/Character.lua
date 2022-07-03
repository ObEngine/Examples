---@class Character : GameObjectCls
local Character = GameObject();


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

local function set_move(direction, state)
    return function() Character.active_movements[direction] = state; end
end

local function is_moving()
    for k, v in pairs(Character.active_movements) do
        if v == true then return true; end
    end
    return false;
end

local function get_moving_angle(active_movements)
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

function Character:init(x, y)
    ---@type obe.scene.SceneNode
    local scene_node = self.components.SceneNode;
    ---@type obe.collision.PolygonalCollider
    local collider = self.components.Collider;
    ---@type obe.graphics.Sprite
    local sprite = self.components.Sprite;

    scene_node:move_without_children(collider:get_centroid());
    collider:add_tag(obe.collision.ColliderTagType.Rejected, "Character");
    self.active_movements = {left = false, right = false, up = false, down = false};
    print("Sprite before", sprite:get_position());
    scene_node:set_position(obe.transform.UnitVector(x, y, obe.transform.Units.ScenePixels));
    print("Sprite after", sprite:get_position());
    self.trajectories = obe.collision.TrajectoryNode(scene_node);
    self.trajectories:set_probe(This.Collider);
    self.trajectory = self.trajectories:add_trajectory("direction"):set_speed(0):set_angle(-90):set_acceleration(0);

    -- Sliding against walls when more than one direction is active
    self.trajectory:add_check(function(_, offset)
        local collision = collider:get_distance_before_collision(offset);
        if #collision.colliders > 0 then
            if math.abs(offset.x) > OFFSET_EPSILON and math.abs(offset.y) > OFFSET_EPSILON then
                local nox_offset = obe.transform.UnitVector(0, offset.y, offset.unit);
                local noy_offset = obe.transform.UnitVector(offset.x, 0, offset.unit);
                local angle = self.trajectory:get_angle();
                if #collider:get_distance_before_collision(nox_offset).colliders == 0 then
                    angle = get_moving_angle({up=self.active_movements.up, down=self.active_movements.down});
                elseif #collider:get_distance_before_collision(noy_offset).colliders == 0 then
                    angle = get_moving_angle({left=self.active_movements.left, right=self.active_movements.right});
                end
                self.trajectory:set_angle(angle);
                self.trajectory:set_speed(character_speed / 2);
            end
        end
    end);
end

Event.Actions.Up = set_move("up", true);
Event.Actions.Down = set_move("down", true);
Event.Actions.Left = set_move("left", true);
Event.Actions.Right = set_move("right", true);
Event.Actions.RUp = set_move("up", false);
Event.Actions.RDown = set_move("down", false);
Event.Actions.RLeft = set_move("left", false);
Event.Actions.RRight = set_move("right", false);

function Event.Game.Update(event)
    ---@type obe.graphics.Sprite
    local sprite = Character.components.Sprite;
    ---@type obe.scene.SceneNode
    local scene_node = Character.components.SceneNode;
    ---@type obe.animation.Animator
    local animator = Character.components.Animator;
    sprite:set_sublayer(-math.floor(scene_node:get_position().y * 1000));
    if is_moving() then
        local angle = get_moving_angle(Character.active_movements);
        -- Discard nan results
        if angle == angle then
            for _, movement_name in pairs(DIRECTIONS) do
                if Character.active_movements[movement_name] then
                    animator:set_animation("MOVE_" .. movement_name:upper());
                    break;
                end
            end
            Character.trajectory:set_speed(character_speed);
            Character.trajectory:set_angle(angle);
        end
    else
        Character.trajectory:set_speed(0);
        animator:set_animation("IDLE_" .. animator:get_current_animation_name():gmatch("_([^%s]+)")())
    end
    Character.trajectories:update(event.dt);
end

function Character:get_current_position()
    ---@type obe.tiles.TileScene
    local tiles = Engine.Scene:get_tiles();
    ---@type obe.collision.PolygonalCollider
    local collider = self.components.Collider;
    local camera_scale = Engine.Scene:get_camera():get_size().y / 2;
    local tile_width = tiles:get_tile_width() / camera_scale;
    local tile_height = tiles:get_tile_height() / camera_scale;
    local px_position = collider:get_centroid():to(obe.transform.Units.ScenePixels);
    local x = math.floor(px_position.x / tile_width);
    local y = math.floor(px_position.y / tile_height);
    return {x=x, y=y};
end