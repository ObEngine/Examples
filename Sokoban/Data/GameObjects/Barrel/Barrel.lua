local Directions = { 
    LEFT = { x = -1, y = 0, cmp = "_LESS", use = "x" },
    RIGHT = { x = 1, y = 0, cmp = "_MORE", use = "x" },
    DOWN = { x = 0, y = 1, cmp = "_MORE", use = "y" },
    UP = { x = 0, y = -1, cmp = "_LESS", use = "y" }
}
local CompOps = {
    _LESS = function(a, b) return a <= b; end,
    _MORE = function(a, b) return a >= b; end
}

StartWalking = 0;
Walking = 1;
EndWalking = 2;
NotWalking = 3;

function Local.Init(position)
    Terrain = Scene:getGameObject("Terrain");
    Object.pos = { x = position.x, y = position.y};
    Object.direction = "NONE";
    Object.walking = NotWalking;
    Object.sprSize = This:LevelSprite():getSize().x;
    Object.speed = 0.5;
    Object.activated = false;

    local pVec = obe.UnitVector(
        position.x * This:LevelSprite():getSize().x, 
        position.y * This:LevelSprite():getSize().y
    );
    This:LevelSprite():setPosition(pVec);
end

function Object:getType()
    return This:getType();
end

function Object:getSprSize()
    return This:LevelSprite():getSize();
end

function Object:move(direction)
    --if Object.walking == NotWalking then 
        Object.direction = direction;
        Object.bound = { 
            x = Directions[Object.direction].x,
            y = Directions[Object.direction].y,
            cmp = Directions[Object.direction].cmp,
            use = Directions[Object.direction].use
        }
        Object.walking = Walking;
        Object.pos = { 
            x = Object.pos.x + Directions[Object.direction].x,
            y = Object.pos.y + Directions[Object.direction].y;
        };
        Terrain.elements[Object.pos.y+1][Object.pos.x+1][2] = This:access();
    --end
end

function Global.Game.Update(dt)
    if Object.activated == false and Terrain.elements[Object.pos.y+1][Object.pos.x+1][1]:getType() == "Objective" then
        Object.activated = true;
        This:LevelSprite():loadTexture("Sprites/GameObjects/Barrel/Barrel_activated.png");
    elseif Object.activated ~= false and Terrain.elements[Object.pos.y+1][Object.pos.x+1][1]:getType() ~= "Objective" then
        Object.activated = false;
        This:LevelSprite():loadTexture("Sprites/GameObjects/Barrel/Barrel.png");
    end
    if Object.walking == Walking then
        local mx, my;
        if Object.bound.use == "x" then
            mx, my = Object.bound.x * dt * Object.speed, 0;
        else 
            mx, my = 0, Object.bound.y * dt * Object.speed;
        end
        local move = obe.UnitVector(mx, my);
        This:LevelSprite():move(move);
        local newpos = This:LevelSprite():getPosition();
        if CompOps[Object.bound.cmp](newpos[Object.bound.use], Object.pos[Object.bound.use] * Object.sprSize) then
            Object.walking = NotWalking;
        end
    else
        local spritePos = obe.UnitVector(
            Object.pos.x * This:LevelSprite():getSize().x, 
            Object.pos.y * This:LevelSprite():getSize().y
        );
        This:LevelSprite():setPosition(spritePos);
    end
end