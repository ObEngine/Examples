Luafinding = {}

Heap = {}
Heap.__index = Heap

local function findLowest( a, b )
    return a < b
end

local function newHeap( template, compare )
    return setmetatable( {
        Data = {},
        Compare = compare or findLowest,
        Size = 0
    }, template )
end

local function sortUp( heap, index )
    if index <= 1 then return end
    local pIndex

    if index % 2 == 0 then pIndex = index / 2
    else pIndex = ( index - 1 ) / 2 end

    if not heap.Compare( heap.Data[pIndex], heap.Data[index] ) then
        heap.Data[pIndex], heap.Data[index] = heap.Data[index], heap.Data[pIndex]
        sortUp( heap, pIndex )
    end
end

local function sortDown( heap, index )
    local leftIndex, rightIndex, minIndex
    leftIndex = index * 2
    rightIndex = leftIndex + 1
    if rightIndex > heap.Size then
        if leftIndex > heap.Size then return
        else minIndex = leftIndex end
    else
        if heap.Compare( heap.Data[leftIndex], heap.Data[rightIndex] ) then minIndex = leftIndex
        else minIndex = rightIndex end
    end

    if not heap.Compare( heap.Data[index], heap.Data[minIndex] ) then
        heap.Data[index], heap.Data[minIndex] = heap.Data[minIndex], heap.Data[index]
        sortDown( heap, minIndex ) 
    end
end

function Heap:Empty()
    return self.Size == 0
end

function Heap:Clear()
    self.Data, self.Size, self.Compare = {}, 0, self.Compare or findLowest
    return self
end

function Heap:Push( item )
    if item then
        self.Size = self.Size + 1
        self.Data[self.Size] = item
        sortUp( self, self.Size )
    end
    return self
end

function Heap:Pop()
    local root
    if self.Size > 0 then
        root = self.Data[1]
        self.Data[1] = self.Data[self.Size]
        self.Data[self.Size] = nil
        self.Size = self.Size - 1
        if self.Size > 1 then
            sortDown( self, 1 )
        end
    end
    return root
end

setmetatable( Heap, { __call = function( self, ... ) return newHeap( self, ... ) end } )

Vector = {}
Vector.__index = Vector

local function newVector( x, y )
    return setmetatable( { x = x or 0, y = y or 0 }, Vector )
end

function isvector( vTbl )
    return getmetatable( vTbl ) == Vector
end

function Vector.__unm( vTbl )
    return newVector( -vTbl.x, -vTbl.y )
end

function Vector.__add( a, b )
    return newVector( a.x + b.x, a.y + b.y )
end

function Vector.__sub( a, b )
    return newVector( a.x - b.x, a.y - b.y )
end

function Vector.__mul( a, b )
    if type( a ) == "number" then
        return newVector( a * b.x, a * b.y )
    elseif type( b ) == "number" then
        return newVector( a.x * b, a.y * b )
    else
        return newVector( a.x * b.x, a.y * b.y )
    end
end

function Vector.__div( a, b )
    return newVector( a.x / b, a.y / b )
end

function Vector.__eq( a, b )
    return a.x == b.x and a.y == b.y
end

function Vector:__tostring()
    return "(" .. self.x .. ", " .. self.y .. ")"
end

function Vector:ID()
    if self._ID == nil then
        local x, y = self.x, self.y
        self._ID = 0.5 * ( ( x + y ) * ( x + y + 1 ) + y )
    end

    return self._ID
end

setmetatable( Vector, { __call = function( _, ... ) return newVector( ... ) end } )


local function distance( start, finish )
    local dx = start.x - finish.x
    local dy = start.y - finish.y
    return dx * dx + dy * dy
end

--[[
This could maybe be used in the future for shorter distances for more precise measurements, although the above function seems to work much faster and mostly fine.
local short_axis_cost = math.sqrt( 2 ) - 1
local function distance( start, finish )
    local x = math.abs( start.x - finish.x )
    local y = math.abs( start.y - finish.y )
    return short_axis_cost * math.min( x, y ) + math.max( x, y )
end
]]--

local positionIsOpen
local function positionIsOpenTable( pos, check ) return check[pos.x] and check[pos.x][pos.y] end
local function positionIsOpenCustom( pos, check ) return check( pos ) or true end

local adjacentPositions = {
    Vector( 0, -1 ),
    Vector( -1, 0 ),
    Vector( 0, 1 ),
    Vector( 1, 0 ),
    Vector( -1, -1 ),
    Vector( 1, -1 ),
    Vector( -1, 1 ),
    Vector( 1, 1 )
}

local function fetchOpenAdjacentNodes( pos, positionOpenCheck )
    local result = {}

    for i = 1, #adjacentPositions do
    	local adjacent = adjacentPositions[i]
        local adjacentPos = pos + adjacent
        if positionIsOpen( adjacentPos, positionOpenCheck ) then
            table.insert( result, adjacentPos )
        end
    end

    return result
end

-- positionOpenCheck can be a function or a table.
-- If it's a function it must have a return value of true or false depending on whether or not the position is open.
-- If it's a table it should simply be a table of values such as "pos[x][y] = true".
function Luafinding.FindPath( start, finish, positionOpenCheck )
    if not positionOpenCheck then return end
    positionIsOpen = type( positionOpenCheck ) == "table" and positionIsOpenTable or positionIsOpenCustom
    if not positionIsOpen( finish, positionOpenCheck ) then return end
    local open, closed = Heap(), {}

    start.gScore = 0
    start.hScore = distance( start, finish )
    start.fScore = start.hScore

    open.Compare = function( a, b )
        return a.fScore < b.fScore
    end

    open:Push( start )

    while not open:Empty() do
        local current = open:Pop()
        local currentId = current:ID()
        if not closed[currentId] then
            if current == finish then
                local path = {}
                while true do
                    if current.previous then
                        table.insert( path, 1, current )
                        current = current.previous
                    else
                        table.insert( path, 1, start )
                        return path
                    end
                end
            end

            closed[currentId] = true

            local adjacents = fetchOpenAdjacentNodes( current, positionOpenCheck )
            for i = 1, #adjacents do
                local adjacent = adjacents[i]
                if not closed[adjacent:ID()] then
                    local added_gScore = current.gScore + distance( current, adjacent )

                    if not adjacent.gScore or added_gScore < adjacent.gScore then
                        adjacent.gScore = added_gScore
                        if not adjacent.hScore then
                            adjacent.hScore = distance( adjacent, finish )
                        end
                        adjacent.fScore = added_gScore + adjacent.hScore

                        open:Push( adjacent )
                        adjacent.previous = current
                    end
                end
            end
        end
    end
end

Luafinding["Vector"] = Vector;

return Luafinding;