Directions = {
    Left = {
        propagate = true,
        x = -1,
        y = 0,
        cmp = "_LESS",
        use = "x",
        part = "exp_hori",
        endpart = "exp_left_end"
    },
    Right = {
        propagate = true,
        x = 1,
        y = 0,
        cmp = "_MORE",
        use = "x",
        part = "exp_hori",
        endpart = "exp_right_end"
    },
    Up = {
        propagate = true,
        x = 0,
        y = -1,
        cmp = "_LESS",
        use = "y",
        part = "exp_vert",
        endpart = "exp_up_end"
    },
    Down = {
        propagate = true,
        x = 0,
        y = 1,
        cmp = "_MORE",
        use = "y",
        part = "exp_vert",
        endpart = "exp_down_end"
    }
}

local CompOps = {
    _LESS = function(a, b)
        return a <= b;
    end,
    _MORE = function(a, b)
        return a >= b;
    end
}

ExpSprites = {};

function Local.Init(position, terrain, power)
    local pVec = obe.Transform.UnitVector(
        position.x * This.Sprite:getSize().x, position.y * This.Sprite:getSize().y
    );
    This.Sprite:setPosition(pVec, obe.Transform.Referential.TopLeft)
    This.Animator:setKey("Bomb");
    Object.exploded = false;
    Object.terrain = terrain;
    Object.position = position;
    Object.power = power;
end

CAN_PROPAGATE = 0;
STOP_PROPAGATE = 1;
CANT_PROPAGATE = 2;
function Object:canPropagate(x, y)
    local bType = self.terrain:get(x, y);
    if bType == "Grass" or bType == "Bush" then
        return CAN_PROPAGATE;
    elseif bType == "Box" then
        return STOP_PROPAGATE;
    else
        return CANT_PROPAGATE;
    end
end

function Object:propagate()
    checkForKills(Object.position.x, Object.position.y);
    for i = 1, Object.power do
        for direction, info in pairs(Directions) do
            if info.propagate then
                local useImg;
                local propagationStatus = self:canPropagate(
                    Object.position.x + info.x * i + 1, Object.position.y + info.y * i + 1
                );
                if i ~= Object.power and propagationStatus == CAN_PROPAGATE then
                    local futurePropagation = self:canPropagate(
                        Object.position.x + info.x * (i + 1) + 1,
                            Object.position.y + info.y * (i + 1) + 1
                    );
                    if futurePropagation == CAN_PROPAGATE or futurePropagation == STOP_PROPAGATE then
                        useImg = info.part;
                    else
                        useImg = info.endpart;
                    end
                else
                    useImg = info.endpart;
                end
                if propagationStatus == CAN_PROPAGATE or propagationStatus == STOP_PROPAGATE then
                    local sprId = This:getId() .. "_bpart_" .. direction .. "_" .. i;
                    local newSprite = Engine.Scene:createSprite(sprId);
                    table.insert(ExpSprites, sprId);
                    newSprite:loadTexture("Sprites/GameObjects/Bomb/" .. useImg .. ".png");
                    local spriteSize = obe.Transform.UnitVector(
                        This.Sprite:getSize().x, This.Sprite:getSize().y
                    );
                    newSprite:setSize(spriteSize, obe.Transform.Referential.TopLeft);
                    local spritePos = obe.Transform.UnitVector(
                        (Object.position.x + info.x * i) * newSprite:getSize().x,
                            (Object.position.y + info.y * i) * newSprite:getSize().y
                    );
                    newSprite:setPosition(spritePos, obe.Transform.Referential.TopLeft);
                    self.terrain:removeElementAtPos(
                        Object.position.x + info.x * i + 1, Object.position.y + info.y * i + 1
                    );

                    checkForKills(Object.position.x + info.x * i, Object.position.y + info.y * i);
                end
                if propagationStatus == STOP_PROPAGATE or propagationStatus == CANT_PROPAGATE then
                    info.propagate = false;
                end
            end
        end
    end
    Schedule():after(0.4):run(
        function()
            This:delete();
        end
    );
end

function Event.Game.Update(evt)
    if This.Animator:getKey() == "Propagate" and not Object.exploded then
        Object:propagate();
        Object.exploded = true;
    end
end

function Local.Delete()
    for k, v in pairs(ExpSprites) do
        Engine.Scene:removeSprite(v);
    end
end

function checkForKills(x, y)
    local character1 = Engine.Scene:getGameObject("character1");
    local character2 = Engine.Scene:getGameObject("character2");
    if character1.pos.x == x and character1.pos.y == y then
        character1:kill();
    end
    if character2.pos.x == x and character2.pos.y == y then
        character2:kill();
    end
end
