function Local.Init(position)
    local pVec = obe.UnitVector(
        position.x * This:LevelSprite():getSize().x, 
        position.y * This:LevelSprite():getSize().y
    );
    This:LevelSprite():setPosition(pVec);
end

function Object:getType()
    return This:getType();
end

function Object:getSprSize()
    return This:LevelSprite():getSize();
end