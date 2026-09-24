--!strict
-- Presentation guard only. The server independently enforces boon restrictions.
local Capabilities = {}
function Capabilities.new(releaseBlock: () -> ()): any
    local api = {canBlock=true,canDash=true}
    function api:Update(state: any, heldBlock: boolean?)
        local blockAllowed = state.canBlock ~= false
        -- A revoked hold is released once; subsequent false snapshots cannot flood releases.
        if self.canBlock and not blockAllowed and (heldBlock or state.blocking) then releaseBlock() end
        self.canBlock = blockAllowed
        self.canDash = state.canDash ~= false
    end
    function api:Allows(action: string, held: boolean?): boolean
        if action == "Block" then return held == false or self.canBlock end
        if action == "Dash" or action == "Burst" then return self.canDash end
        return true
    end
    function api:RenderButton(button: TextButton, label: TextLabel, action: string, remaining: number, colors: any)
        local allowed = self:Allows(action, true)
        button.Active = allowed; button.Selectable = allowed; button.AutoButtonColor = allowed
        if not allowed then
            label.Text = action == "Block" and "NO GUARD" or "NO DASH"
            label.TextColor3 = colors.muted
        else
            label.Text = remaining > 0 and string.format("%.1fs", remaining) or string.upper(action)
            label.TextColor3 = remaining > 0 and colors.muted or colors.text
        end
    end
    return api
end
return Capabilities
