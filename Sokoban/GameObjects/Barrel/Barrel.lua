---@class Barrel : GameObjectCls
local Barrel = GameObject();

-- Constants
local DIRECTIONS = {
    LEFT = { x = -1, y = 0, cmp = "_LESS", use = "x" },
    RIGHT = { x = 1, y = 0, cmp = "_MORE", use = "x" },
    DOWN = { x = 0, y = 1, cmp = "_MORE", use = "y" },
    UP = { x = 0, y = -1, cmp = "_LESS", use = "y" }
};
local COMP_OPERATORS = {
    _LESS = function(a, b) return a <= b; end,
    _MORE = function(a, b) return a >= b; end
};
local WALKING_STATE = {
    StartWalking = 1,
    Walking = 2,
    EndWalking = 3,
    NotWalking = 4
};
local SPEED = 0.5;

-- Private attributes
local _terrain;

-- Public methods
function Barrel:init(position)
    _terrain = Engine.Scene:get_game_object("Terrain");
    self.position = { x = position.x, y = position.y };
    self.direction = "NONE";
    self.walking = WALKING_STATE.NotWalking;
    self.activated = false;

    local sprite_position = obe.transform.UnitVector(
        position.x * self.components.Sprite:get_size().x,
        position.y * self.components.Sprite:get_size().y
    );
    self.components.Sprite:set_position(sprite_position);
end

function Barrel:size()
    return self.components.Sprite:get_size();
end

function Barrel:move(direction)
    self.direction = direction;
    self.bound = {
        x = DIRECTIONS[self.direction].x,
        y = DIRECTIONS[self.direction].y,
        cmp = DIRECTIONS[self.direction].cmp,
        use = DIRECTIONS[self.direction].use
    }
    self.walking = WALKING_STATE.Walking;
    self.position = {
        x = self.position.x + DIRECTIONS[self.direction].x,
        y = self.position.y + DIRECTIONS[self.direction].y;
    };
    _terrain.elements[self.position.y + 1][self.position.x + 1][2] = self:get_storage();
end

-- Events
function Event.Game.Update(evt)
    local sprite = Barrel.components.Sprite;
    if Barrel.walking == WALKING_STATE.Walking then
        local target = _terrain.elements[Barrel.position.y + 1][Barrel.position.x + 1][1];
        if not Barrel.activated and target.type == "Objective" then
            print("ACTIVATING BARREL");
            Barrel.activated = true;
            sprite:load_texture("sprites://GameObjects/Barrel/Barrel_activated.png");
        elseif Barrel.activated ~= false and _terrain.elements[Barrel.position.y + 1][Barrel.position.x + 1][1].type ~= "Objective" then
            Barrel.activated = false;
            sprite:load_texture("sprites://GameObjects/Barrel/Barrel.png");
        end

        local mx, my;
        if Barrel.bound.use == "x" then
            mx, my = Barrel.bound.x * evt.dt * SPEED, 0;
        else
            mx, my = 0, Barrel.bound.y * evt.dt * SPEED;
        end
        local move = obe.transform.UnitVector(mx, my);
        sprite:move(move);
        local new_position = sprite:get_position();
        local sprite_size = sprite:get_size();
        if COMP_OPERATORS[Barrel.bound.cmp](new_position[Barrel.bound.use], Barrel.position[Barrel.bound.use] * sprite_size.x) then
            Barrel.walking = WALKING_STATE.NotWalking;
            local sprite_position = obe.transform.UnitVector(
                Barrel.position.x * sprite_size.x,
                Barrel.position.y * sprite_size.y
            );
            sprite:set_position(sprite_position);
        end
    end
end