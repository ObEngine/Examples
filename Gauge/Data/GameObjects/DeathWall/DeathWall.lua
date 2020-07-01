local gameManager
local moveTimer
local growthSpeed

function Local.Init(gameManagerId)
    gameManager = Engine.Scene:getGameObject("gameManager")

    moveTimer = obe.Time.Chronometer()
    moveTimer:setLimit(config.death_wall.middle.time.max/1000)
    moveTimer:start()
    growthSpeed = 0
end

function Object:reset()
    local size = {  x = config.death_wall.middle.size.min,
                    y = This.Sprite:getSize():to(obe.Transform.Units.ViewPercentage).y
                }
    local sizeVector = obe.Transform.UnitVector(size.x, size.y, obe.Transform.Units.ViewPercentage)
    This.Sprite:setSize(sizeVector, obe.Transform.Referential.Center)
    growthSpeed = 0
    moveTimer:reset()
end

function Object:getPosition()
    return This.Sprite:getPosition(obe.Transform.Referential.Left)
end

function Object:getSize()
    return This.Sprite:getSize()
end

function Event.Game.Update(dt)
    if gameManager.gameOver then
        return
    end
    if moveTimer:over() then
        local shouldMove = obe.Utils.Math.randint(0, 2) - 1
        growthSpeed = obe.Utils.Math.randfloat() * (config.death_wall.middle.speed.max - config.death_wall.middle.speed.min) + config.death_wall.middle.speed.min
        growthSpeed = growthSpeed * shouldMove
        moveTimer:setLimit(obe.Utils.Math.randint(config.death_wall.middle.time.min, config.death_wall.middle.time.max)/1000)
        moveTimer:reset()
    end

    size = This.Sprite:getSize():to(obe.Transform.Units.ViewPercentage)
    if growthSpeed < 0 and size.x <= config.death_wall.middle.size.min or growthSpeed > 0 and size.x >= config.death_wall.middle.size.max then
        growthSpeed = -growthSpeed
    end
    local newSize = This.Sprite:getSize() + obe.Transform.UnitVector(dt*growthSpeed, 0, obe.Transform.Units.ViewPercentage);
    This.Sprite:setSize(newSize, obe.Transform.Referential.Center)
end