function resetpos()
    setpos(0.5, 0.5);
end

function setpos(x, y)
    This:getSceneNode():setPosition(obe.UnitVector(x, y, obe.Units.ViewPercentage));
    This:Collider():setPositionFromCentroid(obe.UnitVector(x, y, obe.Units.ViewPercentage));
    This:LevelSprite():setPosition(obe.UnitVector(x, y, obe.Units.ViewPercentage), obe.Referential.Center);
end

function Local.Init(posX, posY)
    Object.y = 0;
    Object.rpo = 0;
    bumpSound = obe.Sound("Sounds/bump.ogg");

    This:Collider():setPosition(obe.UnitVector.new(posX, posY, obe.Units.ScenePixels));
    Object.tNode = obe.TrajectoryNode(This:getSceneNode());
    Object.tNode:addTrajectory("Linear")
        :setAngle(180)
        :setSpeed(1)
        :setAcceleration(0)
        :onCollide(Object.collide);
    Object.tNode:setProbe(This:Collider());
    This:getSceneNode():setPosition(obe.UnitVector(0.5, 0.5, obe.Units.ViewPercentage));
    This:Collider():setPositionFromCentroid(obe.UnitVector(0.5, 0.5, obe.Units.ViewPercentage));
    This:LevelSprite():setPosition(obe.UnitVector(0.5, 0.5, obe.Units.ViewPercentage), obe.Referential.Center);
    Object.trajectory = Object.tNode:getTrajectory("Linear");
    Object.cycle = 0;
    Object.currentPos = obe.UnitVector(0.5, 0.5, obe.Units.ViewPercentage):to(obe.Units.SceneUnits);
    Object.oldPos = obe.UnitVector(0.5, 0.5, obe.Units.ViewPercentage):to(obe.Units.SceneUnits);
    Object.index = 0;
    Object:initCanvas();
    Object.trail = Object:newLine();
    Object.trailcolor = {r = 255, g = 0, b = 0};
    Object.pos = This:Collider():getCentroid();
end

function Object:initCanvas()
    self.canvas = obe.Canvas.Canvas(obe.Screen.Width, obe.Screen.Height);
    self.canvasls = Scene:createLevelSprite("ball_canvas");
    self.canvasls:setSize(obe.UnitVector(1, 1, obe.Units.ViewPercentage));
    self.canvasls:setLayer(1);
    self.canvas:setTarget(self.canvasls);
    self.canvasBlur = obe.Shader(obe.Path("Shaders/blur.frag"):find());
    self.canvasBlur:setUniform("blur_radius", 0.001);
    self.canvasBlur:setUniform("intensity", 3);
    self.canvasBlur:setUniform("spread", 1);
    self.canvasls:setShader(self.canvasBlur);
end

function Object.collide()
    Object.rpo = math.random() * 0.1 - 0.05;
    local selfPoint = This:Collider():getCentroid():to(obe.Units.ScenePixels);
    local bx, by = selfPoint.x, selfPoint.y;
    local currentPaddle;
    local orientAngle;
    if bx < 960 then
        currentPaddle = Scene:getGameObject("leftPaddle");
        orientAngle = 0;
    else
        currentPaddle = Scene:getGameObject("rightPaddle");
        orientAngle = 180;
    end

    bumpSound:play();
    if bumpSound:getPitch() < 9 then
        bumpSound:setPitch(bumpSound:getPitch() + 0.1);
    end

    local currentPaddlePoint = currentPaddle.collider:getCentroid():to(obe.Units.ScenePixels);
    local px, py = currentPaddlePoint.x, currentPaddlePoint.y;
    local adj, opo = math.abs(px - bx), math.abs(py - by);
    local orientTraj;
    if orientAngle == 90 then orientTraj = by < py and -1 or 1;
    else orientTraj = by < py and 1 or -1;
    end
    Object.trajectory:setAngle(360 - math.deg(math.atan(opo / adj)) * orientTraj + orientAngle);
    Object.trajectory:setSpeed(Object.trajectory:getSpeed() + 0.1);
    Object.trail = Object:newLine();
end

function Object:newLine()
    if self.index > 0 then
        self.oldPos = self.currentPos;
        self.currentPos = self.pos;
    end
    if self.index > 0 then
        self.canvas:remove(tostring(self.index));
    end
    self.index = self.index + 1;
    self.t = self.canvas:Line(tostring(self.index))({
        p1 = { x = self.oldPos.x, y = self.oldPos.y, color = self.trailcolor },
        p2 = { x = self.currentPos.x, y = self.currentPos.y, color = { a = 0 } },
        thickness = 2,
        layer = 0
    });
    return self.t;
end

function Global.Game.Update(dt)
    Object.x = This:Collider():getCentroid():to(obe.Units.ViewPercentage).x;
    Object.y = This:Collider():getCentroid():to(obe.Units.ViewPercentage).y;
    Object.pos = This:Collider():getCentroid();
    if Object.trail then
        Object:variateColor();
        Object.trail.p1 = { x = Object.pos.x, y = Object.pos.y, color = Object.trailcolor };
    end

    -- Trajectory
    Object.tNode:update(dt);

    -- Position
    local selfPoint = This:Collider():getCentroid():to(obe.Units.ViewPercentage);
    local bx, by = selfPoint.x, selfPoint.y;

    -- World Bounds (Top and bottom)
    if by < 0.03 or by > 0.97 then
        if by < 0.03 then
            setpos(bx, 0.03);
        elseif by > 0.97 then
            setpos(bx, 0.97);
        end
        Object.trajectory:setAngle(360 - Object.trajectory:getAngle());
        Object.trail = Object:newLine();
    end

    -- Out of bounds
    if by <= 0 or by >= 1 then
        resetpos();
    end

    -- Win / Loss
    if bx < 0.025 then
        Scene:getGameObject("score"):RightScored();
        resetpos();
        Object.trajectory:setSpeed(1);
    elseif bx > 0.975 then
        Scene:getGameObject("score"):LeftScored();
        resetpos();
        Object.trajectory:setSpeed(1);
    end
end

function Global.Game.Render()
    Object.canvas:render();
end

function Object:variateColor()
    if self.cycle == 0 then
        self.trailcolor.g = self.trailcolor.g + 1;
        if self.trailcolor.g == 255 then self.cycle = 1 end
    elseif self.cycle == 1 then
        self.trailcolor.r = self.trailcolor.r - 1;
        if self.trailcolor.r == 0 then self.cycle = 2; end
    elseif self.cycle == 2 then
        self.trailcolor.b = self.trailcolor.b + 1;
        if self.trailcolor.b == 255 then self.cycle = 3; end
    elseif self.cycle == 3 then
        self.trailcolor.g = self.trailcolor.g - 1;
        if self.trailcolor.g == 0 then self.cycle = 4; end
    elseif self.cycle == 4 then
        self.trailcolor.r = self.trailcolor.r + 1;
        if self.trailcolor.r == 255 then self.cycle = 5; end
    elseif self.cycle == 5 then
        self.trailcolor.b = self.trailcolor.b - 1;
        if self.trailcolor.b == 0 then self.cycle = 0; end
    end
end