---@class Game
local Game = GameObject();

-- Private attributes
local _victory_sprite;

-- Private functions
local function on_scene_loaded()
    ---@type Terrain
    local terrain = Engine.Scene:get_game_object("Terrain");
    local level_file = obe.system.Path("scenes://level" .. Game.level .. ".txt"):find():path();
    print("Level file", level_file);
    terrain:load(level_file);
end

-- Public methods
function Game:init()
    self.level = 1;
    self.victory = false;

    _victory_sprite = Engine.Scene:create_sprite("_victory_sprite");
    _victory_sprite:set_parent_id(self.id);
    _victory_sprite:set_visible(false);
    _victory_sprite:load_texture("sprites://Scenes/victory.png");
    _victory_sprite:set_sublayer(0);
    _victory_sprite:use_texture_size();

    print("Loading Scene Sokoban")
    Engine.Scene:load_from_file("scenes://Sokoban.map.vili", on_scene_loaded);
end

-- Events
function Event.Actions.Reset()
    if Engine.Scene:get_level_name() == "Sokoban" then
        Game.victory = false;
        Engine.Scene:get_game_object("Terrain"):unload();
        Engine.Scene:reload(on_scene_loaded);
    end
end

function Event.Actions.Next()
    if Engine.Scene:get_level_name() == "Sokoban" and Game.victory then
        Game.level = Game.level + 1;
        Game.victory = false;
        Engine.Scene:get_game_object("Terrain"):unload();
        Engine.Scene:reload(on_scene_loaded);
    end
end

function Event.Game.Update(evt)
    if not Engine.Scene:does_game_object_exists("Terrain") then
        return;
    end
    local terrain = Engine.Scene:get_game_object("Terrain");
    if terrain.initialized then
        print("Terrain initialized...");
        if not Game.victory then
            print("Checking for victory...");
            _victory_sprite:set_visible(false);
            Game.victory = true
            for _, row in pairs(terrain.elements) do
                for _, tile in pairs(row) do
                    if tile ~= nil and tile[2] ~= nil and tile[2].type == "Barrel" then
                        if not tile[2].activated then
                            Game.victory = false;
                            break;
                        end
                    end
                end
                if not Game.victory then
                    break;
                end
            end
            if Game.victory then
                print("VICTORYYYYYYYYYYY");
                local camera_center = Engine.Scene:get_camera():get_position(obe.transform.Referential.Center);
                _victory_sprite:set_position(camera_center, obe.transform.Referential.Center);
                _victory_sprite:set_visible(true);
            end
        end
    end
end
