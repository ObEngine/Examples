---@class Runner : GameObjectCls
local Runner = GameObject();

local _canvas;

function Runner:init()
    local flip = obe.transform.UnitVector(-1, 1);
    ---@type obe.graphics.Sprite
    local sprite = self.components.Sprite;
    sprite:scale(flip);
    _canvas = obe.canvas.Canvas();
end

---@param evt obe.events.Cursor.Move
function Event.Cursor.Move(evt)
    local cursor_position = obe.transform.UnitVector(evt.x, evt.y, obe.transform.Units.ScenePixels);
    ---@type obe.graphics.Sprite
    local sprite = Runner.components.Sprite;
    sprite:set_position(cursor_position);
end

function draw_text()
    _canvas:Text "hello" {
        text = "Hello, world!",
        size = 128,
        color = obe.Graphics.Color.White,
        x = 0.5,
        y = 0.5,
        unit = obe.Transform.Units.ViewPercentage,
        align = {
            horizontal = "Center",
            vertical = "Center"
        }
    };
end