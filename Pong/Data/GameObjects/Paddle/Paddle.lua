function setpos(x, y)
    This:getSceneNode():setPosition(obe.UnitVector(x, y, obe.Units.ViewPercentage));
    This:Collider():setPositionFromCentroid(obe.UnitVector(x, y, obe.Units.ViewPercentage));
    This:LevelSprite():setPosition(obe.UnitVector(x, y, obe.Units.ViewPercentage), obe.Referential.Center);
end

function Local.Init(pos)
    Object.pos = pos;
    Object.speed = 1;
    if pos == "Left" then
        Object.posX = 0.01;
        Global.Actions.LPaddleUp = function()
            Object.trajectory:setSpeed(-Object.speed);
            Global.Game.Update = PlayerUpdate
        end
        Global.Actions.LPaddleDown = function()
            Object.trajectory:setSpeed(Object.speed);
            Global.Game.Update = PlayerUpdate
        end
        Global.Actions.LRelease = function()
            Object.trajectory:setSpeed(0);
        end
        Global.Game.Update = function(dt)
            setpos(Object.posX, Scene:getGameObject("ball").y + Scene:getGameObject("ball").rpo);
        end
    elseif pos == "Right" then
        Object.posX = 1 - 0.01;
        Global.Actions.RPaddleUp = function()
            Object.trajectory:setSpeed(-Object.speed);
            Global.Game.Update = PlayerUpdate
        end
        Global.Actions.RPaddleDown = function()
            Object.trajectory:setSpeed(Object.speed);
            Global.Game.Update = PlayerUpdate
        end
        Global.Actions.RRelease = function()
            Object.trajectory:setSpeed(0);
        end
        Global.Game.Update = function(dt)
            setpos(Object.posX, Scene:getGameObject("ball").y + Scene:getGameObject("ball").rpo);
        end
    end
    setpos(Object.posX, 0.5);

    Object.tNode = obe.TrajectoryNode(This:getSceneNode());
    Object.tNode:addTrajectory("Linear")
        :setAngle(270)
        :setSpeed(0)
        :setAcceleration(0);
    Object.trajectory = Object.tNode:getTrajectory("Linear");
    Object.collider = This:Collider();
end

function PlayerUpdate(dt)
    Object.tNode:update(dt); 
    if This:Collider():get(0):to(obe.Units.ViewPercentage).y <= 0 then
        setpos(Object.posX, 0 + This:LevelSprite():getSize():to(obe.Units.ViewPercentage).y / 2);
    elseif This:Collider():get(2):to(obe.Units.ViewPercentage).y >= 1 then
        setpos(Object.posX, 1 - This:LevelSprite():getSize():to(obe.Units.ViewPercentage).y / 2);
    end
end