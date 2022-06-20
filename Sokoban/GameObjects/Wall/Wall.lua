---@class Wall
local Wall = GameObject();

function Wall:init(position)
    local sprite = self.components.Sprite;
    local sprite_size = sprite:get_size();
    local sprite_position = obe.transform.UnitVector(
        position.x * sprite_size.x,
        position.y * sprite_size.y
    );
    sprite:set_position(sprite_position);
end

function Wall:size()
    return self.components.Sprite:get_size();
end