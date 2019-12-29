Ball = {};

function Local.Init()
    score1, score2 = 0, 0;
    canvas = obe.Canvas.Canvas(obe.Screen.Width, obe.Screen.Height);
    canvas:setTarget(This:LevelSprite());

    canvas:Rectangle("background")({
        x = 0, y = 0,
        width = 1, height = 1, unit = obe.Units.ViewPercentage,
        color = { r = 50, g = 50, b = 50, a = 255 },
        layer = 1
    });--

    leftScore = canvas:Text("leftScore")({
        x = obe.Screen.Width / 10, y = 0,
        text = "0", size = 72,
        font = "Data/Fonts/arial.ttf",
        layer = 0
    });

    rightScore = canvas:Text("rightScore")({
        x = obe.Screen.Width - obe.Screen.Width / 10, y = 0,
        text = "0", size = 72,
        font = "Data/Fonts/arial.ttf",
        layer = 0, align = { horizontal = "Right" }
    });

    for i = 0, obe.Screen.Height / 2, obe.Screen.Height / 10 do
        local p1 = obe.UnitVector( obe.Screen.Width / 2, i * 2, obe.Units.ScenePixels):to(obe.Units.SceneUnits);
        local p2 = obe.UnitVector( obe.Screen.Width / 2, i * 2 + (obe.Screen.Height / 10), obe.Units.ScenePixels):to(obe.Units.SceneUnits);
        canvas:Line()({
            p1 = { x = p1.x, y = p1.y },
            p2 = { x = p2.x, y = p2.y },
            layer = 0,
            color = "#FFFFFF",
            thickness = 10, layer = 0
        });
    end

    canvas:render();
end

function Global.Game.Render()
    canvas:render();
end

function Object.LeftScored()
    score1 = score1 + 1;
    leftScore.text = score1;
    canvas:render();
end

function Object.RightScored()
    score2 = score2 + 1;
    rightScore.text = score2;
    canvas:render();
end