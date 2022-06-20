---@class Robot
local Robot = GameObject();

-- Constants
local DIRECTIONS = {
    LEFT = { x = -1, y = 0, cmp = "_LESS", use = "x" },
    RIGHT = { x = 1, y = 0, cmp = "_MORE", use = "x" },
    DOWN = { x = 0, y = 1, cmp = "_MORE", use = "y" },
    UP = { x = 0, y = -1, cmp = "_LESS", use = "y" }
}
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
---@type Terrain
local _terrain;
---@type Game;
local _game;

-- Private functions
function Robot:_initialize_bindings()
    -- print("=============== Initializing Robot Bindings");
    for direction, _ in pairs(DIRECTIONS) do
        Event.Actions[direction] = function()
            if self.walking == WALKING_STATE.NotWalking and not _game.victory then
                self.direction = direction;
                self.walking = WALKING_STATE.StartWalking;
                self.components.Sprite:load_texture("sprites://GameObjects/Robot/Robot_".. direction ..".png");
            end
        end
    end
end

-- Public methods
function Robot:init(position)
    _terrain = Engine.Scene:get_game_object("Terrain");
    _game = Engine.Scene:get_game_object("Game");
    self.position = { x = position.x, y = position.y};
    self.direction = "NONE";
    self.walking = WALKING_STATE.NotWalking;
    self:_initialize_bindings();

    local sprite = self.components.Sprite;
    local sprite_size = sprite:get_size();
    local sprite_position = obe.transform.UnitVector(
        position.x * sprite_size.x,
        position.y * sprite_size.y
    );
    sprite:set_position(sprite_position);
end

function Robot:size()
    return self.components.Sprite:get_size();
end

-- Events
function Event.Game.Update(evt)
    if Robot.walking == WALKING_STATE.StartWalking then
        Robot.bound = {
            x = DIRECTIONS[Robot.direction].x,
            y = DIRECTIONS[Robot.direction].y,
            cmp = DIRECTIONS[Robot.direction].cmp,
            use = DIRECTIONS[Robot.direction].use
        }
        Robot.walking = WALKING_STATE.Walking;

        local offset = {
            x = Robot.position.x + DIRECTIONS[Robot.direction].x,
            y = Robot.position.y + DIRECTIONS[Robot.direction].y
        };
        local tile_on_future_position = _terrain.elements[offset.y + 1][offset.x + 1][1].type;
        local barrel_to_move = _terrain.elements[offset.y + 1][offset.x + 1][2];

        if tile_on_future_position == "Wall" then
            Robot.walking = WALKING_STATE.NotWalking;
        else
            if barrel_to_move ~= nil then
                offset = {
                    x = Robot.position.x + 2 * DIRECTIONS[Robot.direction].x,
                    y = Robot.position.y + 2 * DIRECTIONS[Robot.direction].y
                }
                tile_on_future_position = _terrain.elements[offset.y +1][offset.x + 1][1].type;
                local barrel_on_future_position = _terrain.elements[offset.y + 1][offset.x + 1][2];
                if tile_on_future_position == "Wall" or barrel_on_future_position ~= nil then
                    Robot.walking = WALKING_STATE.NotWalking;
                else
                    barrel_to_move:move(Robot.direction);
                    _terrain.elements[Robot.position.y + 1][Robot.position.y + 1][2] = nil;
                    Robot.position.x = Robot.position.x + DIRECTIONS[Robot.direction].x;
                    Robot.position.y = Robot.position.y + DIRECTIONS[Robot.direction].y
                    _terrain.elements[Robot.position.y + 1][Robot.position.x + 1][2] = Robot:get_storage();
                end
            else
                _terrain.elements[Robot.position.y + 1][Robot.position.x + 1][2] = nil;
                Robot.position.x = Robot.position.x + DIRECTIONS[Robot.direction].x;
                Robot.position.y = Robot.position.y + DIRECTIONS[Robot.direction].y;
                _terrain.elements[Robot.position.y + 1][Robot.position.x + 1][2] = Robot:get_storage();
            end
        end
    elseif Robot.walking == WALKING_STATE.Walking then
        local mx, my;
        if Robot.bound.use == "x" then
            mx, my = Robot.bound.x * evt.dt * SPEED, 0;
        else
            mx, my = 0, Robot.bound.y * evt.dt * SPEED;
        end
        local offset = obe.transform.UnitVector(mx, my);
        local sprite = Robot.components.Sprite
        sprite:move(offset);
        local new_position = sprite:get_position();
        if COMP_OPERATORS[Robot.bound.cmp](new_position[Robot.bound.use], Robot.position[Robot.bound.use] * Robot:size().x) then
            Robot.walking = WALKING_STATE.NotWalking;
        end
    else
        local sprite = Robot.components.Sprite;
        local sprite_size = sprite:get_size();
        local tile_position = {
            x = Robot.position.x * sprite_size.x,
            y = Robot.position.y * sprite_size.y
        };
        sprite:set_position(obe.transform.UnitVector(tile_position.x, tile_position.y));
    end
end