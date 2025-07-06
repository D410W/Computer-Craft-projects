local vault = peripheral.wrap("back")
local chest = peripheral.wrap("top")
local monitor = peripheral.find("monitor")

local sizex
local sizey

-- // monitor startup

if monitor then
 monitor.setTextScale(0.5)
 print("Redirecting UI to external monitor...")
 local oldTarget = term.redirect(monitor)
end

term.clear()
term.setCursorPos(1,1)
term.setBackgroundColor(colors.black)

-- // screen coordinates and positions

sizex, sizey = term.getSize()

local drawBox = function(x0, y0, x1, y1, newColor)
 for i = x0, x1 do
  for j = y0, y1 do
   term.setBackgroundColor(newColor)
   term.setCursorPos(i, j)
   term.write(" ")
   term.setBackgroundColor(colors.black)
  end
 end
end

local writeColor = function(text, x, y, backCol, fontCol)
 backCol = backCol or colors.black
 fontCol = fontCol or colors.white
 
 term.setBackgroundColor(backCol)
 term.setTextColor(fontCol)
 term.setCursorPos(x,y)
 
 term.write(text)
 
 term.setBackgroundColor(colors.black)
 term.setTextColor(colors.white)
end

local isInArea = function(area, cx, cy)
 if not cx or not cy then
  return false
 end
 
 if cx < area.x0 or cx > area.x1 then
  return false
 elseif cy < area.y0 or cy > area.y1 then
  return false
 end
 
 return true
end

-- // screen objects

local uiObjs = {}

local addObj = function(name, tbl)
 if not tbl.draw then
  tbl.draw = function(self)
   drawBox(self.area.x0, self.area.y0, self.area.x1, self.area.y1, self.area.color)
  end
 end
 
 uiObjs[name] = tbl
end

-- ui elements and logic

local cleanID = function(theID)
 local words = {}
 for w in string.gmatch(theID, "([^:]+)") do
  table.insert(words, w)
 end
 return words[2]
end

local slots = {}
local items = {}
local itemPage = 0

local addToItems = function(id, amount)
 for i,v in pairs(items) do
  if v.name == id then
   v.count = v.count + amount
   return
  end
 end
 
 table.insert(items, {name = id, count = amount})
end

local itemsRefresh = function()
 slots = vault.list()
 
 items = {}
 
 for i, t in pairs(slots) do
  addToItems(t.name, t.count)
 end
end

addObj("left", {
 area = {
  x0 = 7,
  y0 = sizey-2,
  x1 = 10,
  y1 = sizey,
  color = colors.red
 },
 click = function(self)
  if itemPage > 0 then
   itemPage = itemPage-1
  end
 end,
})
addObj("right", {
 area = {
  x0 = 13,
  y0 = sizey-2,
  x1 = 16,
  y1 = sizey,
  color = colors.red,
 },
 click = function(self)
  itemPage = itemPage+1
 end
})

addObj("chest", {
 area = {
  x0 = sizex-3,
  y0 = sizey-2,
  x1 = sizex,
  y1 = sizey,
  color = colors.green,
 },
 click = function(self)
  for i = 1, 27 do
   chest.pushItems("back", i)
  end
 end
})

for i = 1, 5 do
 addObj("item"..i, {
  area = {
   x0 = 2, 
   y0 = 2 + 2*(i-1), 
   x1 = 10, 
   y1 = 2 + 2*(i-1), 
   color = colors.orange
  },
  draw = function(self)
   local theSlot = items[i + itemPage*5]
   if theSlot then
    writeColor(cleanID(theSlot.name) .. " - " .. theSlot.count, self.area.x0, self.area.y0, colors.orange, colors.black)
   end
  end,
  click = function(self)
   theSlot = items[i + itemPage * 5]
   if theSlot then
    for i, v in pairs(slots) do
     if v.name == theSlot.name then
      vault.pushItems("top", i)
      return
     end
    end
   end
  end
 })
end

-- // rendering

local uiRender = function(cx, cy)
 term.clear()
 
 for name, obj in pairs(uiObjs) do
  if obj.click and isInArea(obj.area, cx, cy) then
   obj:click()
  end
 end
 
 itemsRefresh()
 
 for name, obj in pairs(uiObjs) do
  obj:draw()
 end
end

itemsRefresh()
uiRender()

-- // click interaction

local touchf = function(event)
 local cx = event[3]
 local cy = event[4]
 
 uiRender(cx, cy)
 
 term.setCursorPos(1, sizey)
 term.write(cx .. ", " .. cy)
 drawBox(cx,cy,cx,cy, colors.blue)
end

if not monitor then
 while true do
  local event = {os.pullEvent("mouse_click")}
  touchf(event)
 end
else
 while true do
  local event = {os.pullEvent("monitor_touch")}
  touchf(event)
 end
end
