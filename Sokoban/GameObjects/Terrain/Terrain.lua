---@class Terrain
local Terrain = GameObject();

local BLOCK_MAPPING = {
    W = "Wall",
    B = "Floor Barrel",
    O = "Objective",
    R = "Floor Robot",
    F = "Floor",
    D = "Objective Barrel",
    T = "Object Robot"
}

-- Private functions
---Read lines from file
---@param path string# path to text file
---@return string[]
local function readlines(path)
    local lines = {};
    for line in io.lines(path) do
        lines[#lines + 1] = line;
    end
    return lines;
end

local function file_exists(path)
    print("file exists", path);
    local f = io.open(path, "r")
    if f then
        f:close()
    end
    return f ~= nil
end

---Build GameObject from block string
---@param blocks string# space-separated block ids
---@param position obe.transform.UnitVector
---@return GameObjectCls[]
local function build_blocks(blocks, position)
    local new_blocks = {};
    for block_id in blocks:gmatch("%S+") do
        local new_block = Engine.Scene:create_game_object(block_id) {
            position = position
        };
        table.insert(new_blocks, new_block);
    end
    return new_blocks
end

function Terrain:init()
    self.elements = {};
end

---loads Terrain from text file
---@param path string# path to terrain file
function Terrain:load(path)
    if not self.initialized and file_exists(path) then
        self.initialized = true;
        -- print("Terrain initialized");
        local lines = readlines(path);
        local bounds = {
            x = #lines[1],
            y = #lines
        };
        local tile_size;
        local load_table = {};

        for line_number, line in pairs(lines) do
            load_table[line_number] = {}
            for character_index = 1, #line do
                local char = line:sub(character_index, character_index);
                load_table[line_number][character_index] = char;
            end
        end

        local offset = {
            x = (bounds.x / 2),
            y = (bounds.y / 2)
        };
        for y, row in pairs(load_table) do
            self.elements[y] = {}
            for x, blocks in pairs(row) do
                if blocks ~= " " then
                    local position = { x = x - 1, y = y - 1 };
                    local block_objects = BLOCK_MAPPING[blocks];
                    self.elements[y][x] = build_blocks(block_objects, position);
                    if tile_size == nil then
                        tile_size = self.elements[y][x][1]:size();
                    end
                end
            end
        end

        local pVec = obe.transform.UnitVector(
            offset.x * tile_size.x,
            offset.y * tile_size.y
        );

        local camera = Engine.Scene:get_camera();
        local camera_size = camera:get_size();

        local terrain_size = {
            width = bounds.x / camera_size.x,
            height = bounds.y / camera_size.y
        };
        local camera_zoom = tile_size.x * (terrain_size.height > terrain_size.width and terrain_size.height or terrain_size.width);

        camera:set_position(pVec, obe.transform.Referential.Center);
        camera:scale(camera_zoom, obe.transform.Referential.Center);

        self.initialized = true;
    end
end

function Terrain:unload()
    self.initialized = false;
end
