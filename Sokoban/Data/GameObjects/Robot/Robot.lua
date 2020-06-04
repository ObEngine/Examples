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
    Terrain = Engine.Scene:getGameObject("Terrain");
    Object.pos = { x = position.x, y = position.y};
    Object.direction = "NONE";
    Object.walking = NotWalking;
    Object.sprSize = This.Sprite:getSize().x;
    Object.speed = 0.5;
    InitializeBindings();

    local pVec = obe.Transform.UnitVector(
        position.x * This.Sprite:getSize().x,
        position.y * This.Sprite:getSize().y
    );
    This.Sprite:setPosition(pVec);
end

function Object:getType()
    return This:getType();
end

function Object:getSprSize()
    return This.Sprite:getSize();
end

function InitializeBindings()
    for k, v in pairs(Directions) do
        Event.Actions[k] = function()
            if Object.walking == NotWalking and not Engine.Scene:getGameObject("Game").victory then
                Object.direction = k;
                Object.walking = StartWalking;
                This.Sprite:loadTexture("Sprites/GameObjects/Robot/Robot_".. k ..".png");
            end
        end
    end
end

function Event.Game.Update(dt)
    if Object.walking == StartWalking then
        Object.bound = {
            x = Directions[Object.direction].x,
            y = Directions[Object.direction].y,
            cmp = Directions[Object.direction].cmp,
            use = Directions[Object.direction].use
        }
        Object.walking = Walking;

        local xProj = Object.pos.x + Directions[Object.direction].x;
        local yProj = Object.pos.y + Directions[Object.direction].y;
        local tileOnFuturePosition = Terrain.elements[yProj+1][xProj+1][1]:getType();
        local barrelToMove = Terrain.elements[yProj+1][xProj+1][2];

        if tileOnFuturePosition == "Wall" then
            Object.walking = NotWalking;
        else
            if barrelToMove ~= nil then
                xProj = Object.pos.x + 2*Directions[Object.direction].x;
                yProj = Object.pos.y + 2*Directions[Object.direction].y;
                tileOnFuturePosition = Terrain.elements[yProj+1][xProj+1][1]:getType();
                local barrelOnFuturePosition = Terrain.elements[yProj+1][xProj+1][2];
                if tileOnFuturePosition == "Wall" or barrelOnFuturePosition ~= nil then
                    Object.walking = NotWalking;
                else
                    barrelToMove:move(Object.direction);
                    Terrain.elements[Object.pos.y+1][Object.pos.x+1][2] = nil;
                    Object.pos = {
                        x = Object.pos.x + Directions[Object.direction].x,
                        y = Object.pos.y + Directions[Object.direction].y
                    };
                    Terrain.elements[Object.pos.y+1][Object.pos.x+1][2] = This:access();
                end
            else
                Terrain.elements[Object.pos.y+1][Object.pos.x+1][2] = nil;
                Object.pos = {
                    x = Object.pos.x + Directions[Object.direction].x,
                    y = Object.pos.y + Directions[Object.direction].y
                };
                Terrain.elements[Object.pos.y+1][Object.pos.x+1][2] = This:access();
            end
        end
    elseif Object.walking == Walking then
        local mx, my;
        if Object.bound.use == "x" then
            mx, my = Object.bound.x * dt * Object.speed, 0;
        else
            mx, my = 0, Object.bound.y * dt * Object.speed;
        end
        local move = obe.Transform.UnitVector(mx, my);
        This.Sprite:move(move);
        local newpos = This.Sprite:getPosition();
        if CompOps[Object.bound.cmp](newpos[Object.bound.use], Object.pos[Object.bound.use] * Object.sprSize) then
            Object.walking = NotWalking;
        end
    --[[elseif Object.walking == EndWalking then
        if not Hook.InputManager:getAction(Object.direction):check() then
            Object.walking = NotWalking;
        else
            Object.walking = StartWalking;
        end]]
    else
        local ssx = Object.pos.x * This.Sprite:getSize().x;
        local ssy = Object.pos.y * This.Sprite:getSize().y;
        local spritePos = obe.Transform.UnitVector(ssx, ssy);
        This.Sprite:setPosition(spritePos);
    end
end