function Local.Init(position)
    local pVec = obe.Transform.UnitVector(
        position.x * This.Sprite:getSize().x,
        position.y * This.Sprite:getSize().y
    );
    This.Sprite:setPosition(pVec);
end

function Object:getType()
    return This:getType();
end

function Object:getSprSize()
    return This.Sprite:getSize();
end