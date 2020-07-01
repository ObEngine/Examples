local player
local deathWall
local bonus
local firstZoneLimit
local secondZoneLimit
local thirdZoneLimit
local newLifeCounter
local score
local canvas

function Local.Init()
    player = Engine.Scene:getGameObject("player")
    deathWall = Engine.Scene:getGameObject("deathWall")
    bonus = Engine.Scene:getGameObject("bonus")

    firstZoneLimit = Engine.Scene:getSprite("scoring_indicator_first_zone_left"):getPosition().x
    secondZoneLimit = Engine.Scene:getSprite("scoring_indicator_second_zone_left"):getPosition().x
    thirdZoneLimit = Engine.Scene:getSprite("death_wall_left"):getPosition(obe.Transform.Referential.Right).x

    newLifeCounter = 0
    score = 0

    Object.gameOver = false

    local size = This.Sprite:getSize():to(obe.Transform.Units.ScenePixels)
    canvas = obe.Canvas.Canvas(size.x, size.y);
    render()
end

function Event.Game.Update(dt)
    if Object.gameOver then
        return
    end

    local playerPos = player:getPosition().x
    local deathWallPos = deathWall:getPosition().x
    local bonusPos = bonus:getPositions()
    local scoreIncrement = 0

    if playerPos <= thirdZoneLimit or playerPos >= deathWallPos then
        player:die()
        deathWall:reset()
        bonus:reset()
    else
        if playerPos <= secondZoneLimit and playerPos > thirdZoneLimit then
            scoreIncrement = config.zone.score.third
        elseif playerPos <= firstZoneLimit and playerPos > secondZoneLimit then
            scoreIncrement = config.zone.score.second
        elseif playerPos > firstZoneLimit then
            scoreIncrement = config.zone.score.first
        end
        scoreIncrement = scoreIncrement * dt * player:getLives()
    end

    if bonus:isActive() and playerPos >= bonusPos.left.x and playerPos <= bonusPos.right.x then
        scoreIncrement = scoreIncrement + config.bonus.score
        bonus:reset()
    end

    score = score + scoreIncrement
    newLifeCounter = newLifeCounter + scoreIncrement

    if newLifeCounter >= config.player.lives.threshold and player:stillAlive() then
        newLifeCounter = 0
        player:getALife()
    end

    if not player:stillAlive() then
        if not Engine.Scene:doesSpriteExists("game_over") then
            sprite = Engine.Scene:createSprite("game_over")
            sprite:loadTexture("Sprites/end.png")
            sprite:setZDepth(0)
            sprite:useTextureSize()
            sprite:setPointPosition(obe.Transform.UnitVector(0.5, 0.5, obe.Transform.Units.ViewPercentage), obe.Transform.Referential.Center)
            Object.gameOver = true
        end
    end
    render()
end

function render()
    canvas:clear()
    canvas:Text("score")({
        text = "Score : "..(math.floor(score)), size = 72, font = "Data/Fonts/NotoSans.ttf",
        x = 0,
        y = 200,
        color = "4ca3dd"
    });
    canvas:Text("lives")({
        text = "Lives : "..(player:getLives() or 0), size = 72, font = "Data/Fonts/NotoSans.ttf",
        x = This.Sprite:getSize():to(obe.Transform.Units.ScenePixels).x / 2,
        y = 200,
        color = "4f983c"
    });
    canvas:render(This.Sprite)
end