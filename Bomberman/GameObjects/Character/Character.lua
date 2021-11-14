local Directions = {
    Left = {x = -1, y = 0, cmp = "_LESS", use = "x"},
    Right = {x = 1, y = 0, cmp = "_MORE", use = "x"},
    Down = {x = 0, y = 1, cmp = "_MORE", use = "y"},
    Up = {x = 0, y = -1, cmp = "_LESS", use = "y"}
}
local CompOps = {
    _LESS = function(a, b)
        return a <= b;
    end,
    _MORE = function(a, b)
        return a >= b;
    end
}

StartWalking = 0;
Walking = 1;
EndWalking = 2;
NotWalking = 3;

function Local.Init(characterId, terrainId, pos)
    Terrain = Engine.Scene:getGameObject(terrainId);
    Object.cid = characterId;
    Object.pos = {x = pos.x, y = pos.y};
    Object.direction = "None";
    Object.walking = NotWalking;
    Object.sprSize = This.Sprite:getSize().x;
    Object.speed = 0.5;
    Object.bombIndex = 0;
    This.Animator:load(
        obe.System.Path("root://Sprites/GameObjects/Character/" .. characterId), Engine.Resources
    );
    This.Animator:setKey("Idle_Right");
    This.Animator:setTarget(This.Sprite);
    InitializeBindings();
    Object.dead = false;
end

function InitializeBindings()
    for k, v in pairs(Directions) do
        Event.Actions[Object.cid .. "_" .. k] = function()
            if Object.walking == NotWalking then
                Object.direction = k;
                Object.walking = StartWalking;
            end
        end
    end
    Event.Actions[Object.cid .. "_Bomb"] = function()
        if not Object.dead then
            Object.bombIndex = Object.bombIndex + 1;
            Engine.Scene:createGameObject(
                "Bomb", Object.cid .. "_bomb_" .. tostring(Object.bombIndex)
            )({position = Object.pos, terrain = Terrain, power = 6});
        end
    end
end

function Event.Game.Update(evt)
    if Object.walking == StartWalking then
        if not Object.dead then
            This.Animator:setKey("Walk_" .. Object.direction);
        end
        Object.bound = {
            x = Directions[Object.direction].x,
            y = Directions[Object.direction].y,
            cmp = Directions[Object.direction].cmp,
            use = Directions[Object.direction].use
        }
        Object.walking = Walking;
        local xProj = Object.pos.x + Directions[Object.direction].x;
        local yProj = Object.pos.y + Directions[Object.direction].y;
        local tileOnFuturePosition = Terrain:get(xProj + 1, yProj + 1);
        if tileOnFuturePosition ~= "Grass" then
            Object.walking = NotWalking;
            if not Object.dead then
                This.Animator:setKey("Idle_" .. Object.direction);
            end
        else
            Object.pos = {
                x = Object.pos.x + Directions[Object.direction].x,
                y = Object.pos.y + Directions[Object.direction].y
            };
        end
    elseif Object.walking == Walking then
        local mx, my;
        if Object.bound.use == "x" then
            mx, my = Object.bound.x * evt.dt * Object.speed, 0;
        else
            mx, my = 0, Object.bound.y * evt.dt * Object.speed;
        end
        local move = obe.Transform.UnitVector(mx, my);
        This.Sprite:move(move);
        local newpos = This.Sprite:getPosition(obe.Transform.Referential.TopLeft);
        if CompOps[Object.bound.cmp](
            newpos[Object.bound.use], Object.pos[Object.bound.use] * Object.sprSize
        ) then
            Object.walking = EndWalking;
        end
    elseif Object.walking == EndWalking then
        if not Engine.Input:getAction(Object.cid .. "_" .. Object.direction):check() then
            if not Object.dead then
                This.Animator:setKey("Idle_" .. Object.direction);
            end
            Object.walking = NotWalking;
        else
            Object.walking = StartWalking;
        end
    else
        local spritePos = obe.Transform.UnitVector(
            Object.pos.x * This.Sprite:getSize().x, Object.pos.y * This.Sprite:getSize().y
        );
        This.Sprite:setPosition(spritePos, obe.Transform.Referential.TopLeft);
    end
end

function Object:kill()
    Object.dead = true;
    This.Animator:setKey("Dead");
end
