local default_scale = 1;

function getAllZones()
    local zoneObjects = Engine.Scene:getAllGameObjects("CameraZone");
    local zones = {};
    for _, zone in pairs(zoneObjects) do
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
    print(inspect(zones));
    return zones;
end

function detectZone()
    if Object.actor then
        for zoneName, zone in pairs(Object.zones) do
            if zone.rect:contains(Object.actor:getCentroid()) then
                -- print("Inside", zoneName);
                Object.current_zone = zone;
                return;
            end
        end
        Object.current_zone = nil;
    end
end

function scaleCamera()
    if Object.current_zone == nil then
        Object.target_scale = default_scale;
    else
        local window_size = Engine.Window:getSize();
        local window_ratio = window_size.x / window_size.y;
        local comp_func = math.min;
        if Object.current_zone.use_max then
            comp_func = math.max;
        end
        Object.target_scale = comp_func(Object.current_zone.rect.width / window_ratio, Object.current_zone.rect.height) / 2;
    end
end

function setClamps()
    if Object.current_zone == nil then
        Object.clamps = Object.base_clamps;
    else
        Object.clamps = Object.current_zone.clamp
    end
end

function Local.Init(actor, clamp_x_min, clamp_y_min, clamp_x_max, clamp_y_max, disable_clamping, scale)
    disable_clamping = disable_clamping or false;
    default_scale = scale or default_scale;
    Object.current_scale = default_scale;
    Object.target_scale = default_scale;
    if actor ~= nil then
        Object.actor = Engine.Scene:getCollider(actor);
    end
    if not disable_clamping then
        if clamp_x_min == nil then
            clamp_x_min = 0;
        end
        if clamp_y_min == nil then
            clamp_y_min = 0;
        end
        if Engine.Scene:hasTiles() then
            local scene_px_width = Engine.Scene:getTiles():getWidth() * Engine.Scene:getTiles():getTileWidth();
            local scene_px_height = Engine.Scene:getTiles():getHeight() * Engine.Scene:getTiles():getTileHeight();
            local scene_size = obe.Transform.UnitVector(scene_px_width, scene_px_height, obe.Transform.Units.ScenePixels):to(obe.Transform.Units.SceneUnits);
            if clamp_x_max == nil then
                clamp_x_max = scene_size.x;
            end
            if clamp_y_max == nil then
                clamp_y_max = scene_size.y;
            end
        end
    end
    Object.base_clamps = {
        x_min = clamp_x_min,
        y_min = clamp_y_min,
        x_max = clamp_x_max,
        y_max = clamp_y_max
    };
    Object.clamps = Object.base_clamps;
    if Object.actor then
        Engine.Scene:getCamera():setPosition(Object.actor:getCentroid(), obe.Transform.Referential.Center);
    end
    Object.zones = getAllZones();
end

local CAMERA_SPEED = 4;
local CAMERA_SMOOTH = true;

function Event.Game.Update(event)
    if Object.actor then
        if CAMERA_SMOOTH then
            local current_camera_position = Engine.Scene:getCamera():getPosition(obe.Transform.Referential.Center);
            local actor_position = Object.actor:getCentroid();
            local new_position = (actor_position - current_camera_position) * CAMERA_SPEED * event.dt;
            Engine.Scene:getCamera():move(new_position);
        else
            Engine.Scene:getCamera():setPosition(Object.actor:getCentroid(), obe.Transform.Referential.Center);
        end
        local current_camera_position = Engine.Scene:getCamera():getPosition(obe.Transform.Referential.Center);
        local camera_center = Engine.Scene:getCamera():getPosition(obe.Transform.Referential.Center);
        local camera_topleft = Engine.Scene:getCamera():getPosition(obe.Transform.Referential.TopLeft);
        local camera_bottomright = Engine.Scene:getCamera():getPosition(obe.Transform.Referential.BottomRight);
        if Object.clamps.x_min ~= nil and camera_topleft.x < Object.clamps.x_min then
            current_camera_position.x = Object.clamps.x_min + (camera_center.x - camera_topleft.x);
        elseif Object.clamps.x_max ~= nil and camera_bottomright.x > Object.clamps.x_max then
            current_camera_position.x = Object.clamps.x_max + (camera_center.x - camera_bottomright.x);
        end
        if Object.clamps.y_min ~= nil and camera_topleft.y < Object.clamps.y_min then
            current_camera_position.y = Object.clamps.y_min + (camera_center.y - camera_topleft.y);
        elseif Object.clamps.y_max ~= nil and camera_bottomright.y > Object.clamps.y_max then
            current_camera_position.y = Object.clamps.y_max + (camera_center.y - camera_bottomright.y);
        end
        Engine.Scene:getCamera():setPosition(current_camera_position, obe.Transform.Referential.Center);

        detectZone();
        scaleCamera();
        setClamps();
        Object.current_scale = Object.current_scale + (Object.target_scale - Object.current_scale) * CAMERA_SPEED * event.dt
        -- Engine.Scene:getCamera():setSize(Object.target_scale, obe.Transform.Referential.Center);
        Engine.Scene:getCamera():setSize(Object.current_scale, obe.Transform.Referential.Center);
    end
end

function Event.Actions.ToggleCameraSmoothing()
    CAMERA_SMOOTH = not CAMERA_SMOOTH;
end

function Event.Actions.CameraLeft(event)
    local dt = Engine.Framerate:getGameSpeed();
    local movement = obe.Transform.UnitVector(dt * -CAMERA_SPEED, 0);
    Engine.Scene:getCamera():move(movement);
end

function Event.Actions.CameraRight(event)
    local dt = Engine.Framerate:getGameSpeed();
    local movement = obe.Transform.UnitVector(dt * CAMERA_SPEED, 0);
    Engine.Scene:getCamera():move(movement);
end

function Event.Actions.CameraUp(event)
    local dt = Engine.Framerate:getGameSpeed();
    local movement = obe.Transform.UnitVector(0, dt * -CAMERA_SPEED);
    Engine.Scene:getCamera():move(movement);
end

function Event.Actions.CameraDown(event)
    local dt = Engine.Framerate:getGameSpeed();
    local movement = obe.Transform.UnitVector(0, dt * CAMERA_SPEED);
    Engine.Scene:getCamera():move(movement);
end

function Event.Actions.CameraZoom(event)
    Engine.Scene:getCamera():scale(0.95, obe.Transform.Referential.Center);

    print("Zoom Camera Position (from center)", Engine.Scene:getCamera():getPosition(obe.Transform.Referential.Center):to(obe.Transform.Units.SceneUnits));
end

function Event.Actions.CameraUnzoom(event)
    Engine.Scene:getCamera():scale(1.05, obe.Transform.Referential.Center);
    print("Unzoom Camera Position (from center)", Engine.Scene:getCamera():getPosition(obe.Transform.Referential.Center):to(obe.Transform.Units.SceneUnits));
end