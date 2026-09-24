-- Apply after normal positions reset; keep a clear row for rescue hold controls.
local Layout={}
function Layout.Apply(active,widgets)
    if not active then return end
    for _,item in pairs(widgets)do
        local position=item.Position
        item.Position=UDim2.new(position.X.Scale,position.X.Offset,position.Y.Scale,position.Y.Offset-60)
    end
end
return Layout
