-- Shared compact rectangles in safe-canvas pixels; presentation only.
local Layout={}
local function box(x,y,w,h)return {x=x,y=y,w=w,h=h}end
function Layout.Compute(width,height,mode,rescue,chooseHero)
    local touch=mode=="Touch"
    local compact=height<450 or width<650
    if not compact then return nil end
    local header=math.min(200,(width-124)/2)
    local reserve=rescue and 60 or 0
    local cell=touch and 52 or math.min(73,(width-46)/6)
    local cols=touch and 3 or 6
    local rowHeight=touch and 44 or 48
    local gap=4
    local aw=cols*cell+(cols-1)*gap
    local ah=touch and rowHeight*2+gap or rowHeight
    local showHeroes=chooseHero==true
    local layout={touch=touch,reserve=reserve,showHeroes=showHeroes,
        top=box(8,8,header,44),encounter=box(width-8-header,8,header,44),settings=box(width/2-46,8,44,44),progress=box(width/2+2,8,44,44),
        boss=showHeroes and box(160,56,width-168,44)or box(8,56,width-16,34),
        health=box(8,showHeroes and 104 or 94,144,28),
        style=box(160,showHeroes and 104 or 94,width-168,28),
        warning=box(8,showHeroes and 134 or 126,width-16,26),
        toast=box(8,showHeroes and 134 or 126,width-16,26),
        abilities=box(width-8-aw,height-8-reserve-ah,aw,ah),
        pad=box(8,height-8-reserve-80,80,80),jump=box(96,height-8-reserve-44,44,44),cells={}}
    for i=1,6 do layout.cells[i]=box((i-1)%cols*(cell+gap),math.floor((i-1)/cols)*(rowHeight+gap),cell,rowHeight)end
    return layout
end
function Layout.ToastVisibility(compact,critical,progressActive)
    if not compact then return true,progressActive==true end
    return critical~=true and progressActive~=true,critical~=true and progressActive==true
end
function Layout.Place(item,bounds)
    item.AnchorPoint=Vector2.zero
    item.Position=UDim2.fromOffset(bounds.x,bounds.y)
    item.Size=UDim2.fromOffset(bounds.w,bounds.h)
end
function Layout.Main(layout,widgets)
    if not layout then return end
    for key,bounds in pairs(layout)do
        if widgets[key]and type(bounds)=="table"and bounds.x then Layout.Place(widgets[key],bounds)end
    end
    for i,button in ipairs(widgets.buttons)do Layout.Place(button,layout.cells[i])end
end
return Layout
