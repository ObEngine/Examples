---@class Camera : GameObjectCls
local Camera = GameObject();

local default_scale = 1;

local function get_all_zones()
    local zone_objects = Engine.Scene:get_all_game_objects("CameraZone");
    local zones = {};
    for _, zone in pairs(zone_objects) do
        local clamp = zone.Clamp;
        for k, v in pairs({"x_min", "y_min", "x_max", "y_max"}) do
            if clamp[v] == nil then
                clamp[v] = Object.base_clamps[v];
            end
        end
        zones[zone.id] = {
            rect = zone.Zone,
            clamp = clamp,
            use_max = zone.use_max
        };
    end
    return zones;
end

local function detect_zone()
    if Camera.actor then
        for zoneName, zone in pairs(Camera.zones) do
            if zone.rect:contains(Camera.actor:get_centroid()) then
                -- print("Inside", zoneName);
                Camera.current_zone = zone;
                return;
            end
        end
        Camera.current_zone = nil;
    end
end


local function scale_camera()
    if Camera.current_zone == nil then
        Camera.target_scale = default_scale;
    else
        local window_size = Engine.Window:get_size();
        local window_ratio = window_size.x / window_size.y;
        local comp_func = math.min;
        if Camera.current_zone.use_max then
            comp_func = math.max;
        end
        Camera.target_scale = comp_func(Camera.current_zone.rect.width / window_ratio, Camera.current_zone.rect.height) / 2;
    end
end

local function set_clamps()
    if Camera.current_zone == nil then
        Camera.clamps = Camera.base_clamps;
    else
        Camera.clamps = Camera.current_zone.clamp
    end
end

function Camera:init(actor, clamp_x_min, clamp_y_min, clamp_x_max, clamp_y_max, disable_clamping, scale)
    disable_clamping = disable_clamping or false;
    default_scale = scale or default_scale;
    self.current_scale = default_scale;
    self.target_scale = default_scale;
    if actor ~= nil then
        self.actor = Engine.Scene:get_collider(actor);
    end
    if not disable_clamping then
        if clamp_x_min == nil then
            clamp_x_min = 0;
        end
        if clamp_y_min == nil then
            clamp_y_min = 0;
        end
        if Engine.Scene:has_tiles() then
            local tile_scene = Engine.Scene:get_tiles();
            local scene_px_width = tile_scene:get_width() * tile_scene:get_tile_width();
            local scene_px_height = tile_scene:get_height() * tile_scene:get_tile_height();
            local scene_size = obe.transform.UnitVector(scene_px_width, scene_px_height, obe.transform.Units.ScenePixels):to(obe.transform.Units.SceneUnits);
            if clamp_x_max == nil then
                clamp_x_max = scene_size.x;
            end
            if clamp_y_max == nil then
                clamp_y_max = scene_size.y;
            end
        end
    end
    self.base_clamps = {
        x_min = clamp_x_min,
        y_min = clamp_y_min,
        x_max = clamp_x_max,
        y_max = clamp_y_max
    };
    self.clamps = self.base_clamps;
    if self.actor then
        Engine.Scene:get_camera():set_position(self.actor:get_centroid(), obe.transform.Referential.Center);
    end
    self.zones = get_all_zones();
end

local CAMERA_SPEED = 4;
local CAMERA_SMOOTH = true;

function Event.Game.Update(event)
    local camera = Engine.Scene:get_camera();
    if Camera.actor then
        if CAMERA_SMOOTH then
            local current_camera_position = camera:get_position(obe.transform.Referential.Center);
            local actor_position = Camera.actor:get_centroid();
            ---@type obe.transform.UnitVector
            local new_position = (actor_position - current_camera_position) * CAMERA_SPEED * event.dt;
            camera:move(new_position);
        else
            camera:set_point_position(Camera.actor:get_centroid(), obe.transform.Referential.Center);
        end
        local current_camera_position = camera:get_position(obe.transform.Referential.Center);
        local camera_center = camera:get_position(obe.transform.Referential.Center);
        local camera_topleft = camera:get_position(obe.transform.Referential.TopLeft);
        local camera_bottomright = camera:get_position(obe.transform.Referential.BottomRight);
        if Camera.clamps.x_min ~= nil and camera_topleft.x < Camera.clamps.x_min then
            current_camera_position.x = Camera.clamps.x_min + (camera_center.x - camera_topleft.x);
        elseif Camera.clamps.x_max ~= nil and camera_bottomright.x > Camera.clamps.x_max then
            current_camera_position.x = Camera.clamps.x_max + (camera_center.x - camera_bottomright.x);
        end
        if Camera.clamps.y_min ~= nil and camera_topleft.y < Camera.clamps.y_min then
            current_camera_position.y = Camera.clamps.y_min + (camera_center.y - camera_topleft.y);
        elseif Camera.clamps.y_max ~= nil and camera_bottomright.y > Camera.clamps.y_max then
            current_camera_position.y = Camera.clamps.y_max + (camera_center.y - camera_bottomright.y);
        end
        camera:set_position(current_camera_position, obe.transform.Referential.Center);

        detect_zone();
        scale_camera();
        set_clamps();
        Camera.current_scale = Camera.current_scale + (Camera.target_scale - Camera.current_scale) * CAMERA_SPEED * event.dt
        -- Engine.Scene:getCamera():setSize(Object.target_scale, obe.transform.Referential.Center);
        camera:set_size(Camera.current_scale, obe.transform.Referential.Center);
    end
end

function Event.Actions.ToggleCameraSmoothing()
    CAMERA_SMOOTH = not CAMERA_SMOOTH;
end

function Event.Actions.CameraLeft(event)
    local dt = Engine.Framerate:get_game_speed();
    local movement = obe.transform.UnitVector(dt * -CAMERA_SPEED, 0);
    Engine.Scene:get_camera():move(movement);
end

function Event.Actions.CameraRight(event)
    local dt = Engine.Framerate:get_game_speed();
    local movement = obe.transform.UnitVector(dt * CAMERA_SPEED, 0);
    Engine.Scene:get_camera():move(movement);
end

function Event.Actions.CameraUp(event)
    local dt = Engine.Framerate:getGameSpeed();
    local movement = obe.transform.UnitVector(0, dt * -CAMERA_SPEED);
    Engine.Scene:get_camera():move(movement);
end

function Event.Actions.CameraDown(event)
    local dt = Engine.Framerate:get_game_speed();
    local movement = obe.transform.UnitVector(0, dt * CAMERA_SPEED);
    Engine.Scene:get_camera():move(movement);
end

function Event.Actions.CameraZoom(event)
    Engine.Scene:get_camera():scale(0.95, obe.transform.Referential.Center);

    print("Zoom Camera Position (from center)", Engine.Scene:get_camera():get_position(obe.transform.Referential.Center):to(obe.transform.Units.SceneUnits));
end

function Event.Actions.CameraUnzoom(event)
    Engine.Scene:get_camera():scale(1.05, obe.transform.Referential.Center);
    print("Unzoom Camera Position (from center)", Engine.Scene:get_camera():get_position(obe.transform.Referential.Center):to(obe.transform.Units.SceneUnits));
end