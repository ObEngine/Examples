blocFunctions = {}

function function_binding(toBind)
    for k, v in pairs(toBind) do
        blocFunctions[k] = function(position)
            local newObjs = {};
            for i in string.gmatch(v, "%S+") do
                -- print("CREATING GAMEOBJECT", i)
                table.insert(newObjs, Engine.Scene:createGameObject(i)({position = position}));
            end
            return newObjs
        end
    end
end

function Object:uninit()
    Object.initialized = false;
end

function Object:init(path)
    local start_time = obe.Time.epoch();
    -- print("Init terrain", path)
    if not Object.initialized and file_exists(path) then
        This:initialize();
        -- print("Terrain initialized");
        local lines = lines_from(path)
        local maxY;
        local maxX;
        local sprSize;
        local load_table = {};
        -- print("Lines", inspect(lines));
        for i, str in pairs(lines) do
            if maxY == nil or i>maxY then
                maxY = i;
            end
            load_table[i] = {}
            for j = 1, #str do
                if maxX == nil or j>maxX then
                    maxX = j;
                end
                local char = str:sub(j,j);
                load_table[i][j] = char;
            end
        end
        -- print("Loadtable", inspect(load_table));
        local offset = {x = (maxX/2), y = (maxY/2)};
        for i, v in pairs(load_table) do
            Object.elements[i] = {}
            for j, v2 in pairs(v) do
                if v2 ~= " " then
                    local position = { x = j-1, y = i-1 };
                    -- print("Loading element", v2);
                    Object.elements[i][j] = blocFunctions[v2](position);
                    if sprSize == nil then
                        sprSize = Object.elements[i][j][1].getSprSize();
                    end
                end
            end
        end

        -- print("Setting camera");
        local pVec = obe.Transform.UnitVector(
            offset.x * sprSize.x,
            offset.y * sprSize.y
        );

        local ySize = maxY/Engine.Scene:getCamera():getSize().y;
        local xSize = maxX/Engine.Scene:getCamera():getSize().x;
        local pSize = sprSize.x * (ySize > xSize and ySize or xSize);

        local camera = Engine.Scene:getCamera();
        camera:setPosition(pVec, obe.Transform.Referential.Center);
        camera:scale(pSize, obe.Transform.Referential.Center);
        -- print("Terrain done :)");
        Object.initialized = true;
    end
    local total_time = obe.Time.epoch() - start_time;
        print("Scene loaded in", total_time, "seconds");
end

function Local.Init(toBind)
    function_binding(toBind);
    Object.elements = {};
end

function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() end
  return f ~= nil
end

function lines_from(path)
  lines = {}
  for line in io.lines(path) do
    lines[#lines + 1] = line
  end
  return lines
end