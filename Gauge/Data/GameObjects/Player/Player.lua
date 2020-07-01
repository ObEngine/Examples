local gameManager
local repopTimer
local startingSize
local lives
local dead

function Local.Init(gameManagerId)
    gameManager = Engine.Scene:getGameObject(gameManagerId)

    repopTimer = obe.Time.Chronometer()
    repopTimer:setLimit(config.player.repop.time/1000)

    startingSize = This.Sprite:getSize()

    lives = config.player.lives.start
    dead = false
end

function Object:die()
    lives = lives - 1
    dead = true
    This.Sprite:setVisible(false)
    local size = {  x = config.player.repop.size,
                    y = This.Sprite:getSize():to(obe.Transform.Units.ViewPercentage).y
                }
    local sizeVector = obe.Transform.UnitVector(size.x, size.y, obe.Transform.Units.ViewPercentage)
    This.Sprite:setSize(sizeVector, obe.Transform.Referential.Center)
    repopTimer:start()
end

function Object:getALife()
    lives = lives + 1
end

function Object:stillAlive()
    if lives > 0 then
        return true
    end
    return false
end

function Object:getLives()
    return lives
end

function Object:getPosition()
    return This.Sprite:getPosition()
end

function Event.Game.Update(dt)
    if gameManager.gameOver then
        return
    end
    if dead then
        if not repopTimer:over() then
            return
        end
        repopTimer:stop()
        dead = false
        This.Sprite:setVisible(true)
    end

    local growthSpeed = Engine.Cursor:isPressed(0) and -config.player.speed or config.player.speed
    local newSize = This.Sprite:getSize() + obe.Transform.UnitVector(dt*growthSpeed, 0, obe.Transform.Units.ViewPercentage);
    This.Sprite:setSize(newSize, obe.Transform.Referential.Center)
end