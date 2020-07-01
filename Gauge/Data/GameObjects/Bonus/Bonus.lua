local gameManager
local deathWall
local leftSprite
local rightSprite
local spawnTimer

function Local.Init(gameManagerId, deathWallId)
    gameManager = Engine.Scene:getGameObject(gameManagerId)
    deathWall = Engine.Scene:getGameObject(deathWallId)

    leftSprite = Engine.Scene:getSprite("bonus_left")
    rightSprite = Engine.Scene:getSprite("bonus_right")
    spawnTimer = obe.Time.Chronometer()
    Object:reset()
end

function Object:reset()
    leftSprite:setVisible(false)
    rightSprite:setVisible(false)
    local randomTimeLimit = obe.Utils.Math.randint(config.bonus.time.min, config.bonus.time.max)/1000
    spawnTimer:setLimit(randomTimeLimit)
    spawnTimer:start()
end

function Object:isActive()
    return leftSprite:isVisible()
end

function Object:getPositions()
    local leftPosition = leftSprite:getPosition(obe.Transform.Referential.Left)
    local rightPosition = leftSprite:getPosition(obe.Transform.Referential.Right)
    return {left = leftPosition , right = rightPosition}
end

function Event.Game.Update(dt)
    if gameManager.gameOver then
        return
    end
    if spawnTimer:over() then
        leftSprite:setVisible(true)
        rightSprite:setVisible(true)
        spawnTimer:stop()
    end
    if not leftSprite:isVisible() then
        return
    end

    local deathWallPosition = deathWall:getPosition()
    local deathWallSize = deathWall:getSize():to(obe.Transform.Units.ViewPercentage).x
    local newPosition = deathWallPosition - obe.Transform.UnitVector(config.bonus.distance, 0, obe.Transform.Units.ViewPercentage)
    leftSprite:setPosition(newPosition, obe.Transform.Referential.Center)
    newPosition = deathWallPosition + obe.Transform.UnitVector(deathWallSize + config.bonus.distance, 0, obe.Transform.Units.ViewPercentage)
    rightSprite:setPosition(newPosition, obe.Transform.Referential.Center)
end