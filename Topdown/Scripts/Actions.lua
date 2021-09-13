function Action(action)
    return action;
end

function Sequence(f)
end

--[[local npc_goto = Action {
    init = function(self, npc, position)
        self.npc = npc,
    end,
    update = function(self, dt)

    end
}]]

local function npc_goto(npc, position)

end

return {
    npc_goto = npc_goto
}