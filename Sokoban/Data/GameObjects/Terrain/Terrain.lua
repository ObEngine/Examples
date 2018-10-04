blocFunctions = {}

function function_binding(toBind)
    for k, v in pairs(toBind) do
        blocFunctions[k] = function(position)
            local newObjs = {};
            for i in string.gmatch(v, "%S+") do
                table.insert(newObjs, Scene:createGameObject(i)({position = position}));
            end
            return newObjs
        end
    end
end

function Object:uninit()
    Object.initialized = false;
end

function Object:init(path)
    if not Object.initialized and file_exists(path) then
        This:initialize();
        local lines = lines_from(path)
        local maxY;
        local maxX;
        local sprSize;
        local load_table = {};
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
        local offset = {x = (maxX/2), y = (maxY/2)};
        for i, v in pairs(load_table) do
            Object.elements[i] = {}
            for j, v2 in pairs(v) do
                if v2 ~= " " then
                    local position = { x = j-1, y = i-1 };
                    Object.elements[i][j] = blocFunctions[v2](position);
                    if sprSize == nil then
                        sprSize = Object.elements[i][j][1].getSprSize();
                    end
                end
            end
        end

        local pVec = obe.UnitVector(
            offset.x * sprSize.x, 
            offset.y * sprSize.y
        );

        local ySize = maxY/Scene:getCamera():getSize().y;
        local xSize = maxX/Scene:getCamera():getSize().x;
        local pSize = sprSize.x * (ySize > xSize and ySize or xSize);

        Scene:getCamera():setPosition(pVec, obe.Referencial.Center);
        Scene:getCamera():scale(pSize, obe.Referencial.Center);
        Object.initialized = true;
    end
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