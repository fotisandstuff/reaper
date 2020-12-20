if reaper.CountSelectedMediaItems(0) == 0 then
    return reaper.MB("No items selected", "Error", 0)
end

reaper.Undo_BeginBlock()

local items = {}
local minimumStart = math.huge
local maximumStop = -math.huge
for itemIndex = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, itemIndex)
    local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local stop = start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    items[{start = start, stop = stop}] = true
    minimumStart = math.min(minimumStart, start)
    maximumStop = math.max(maximumStop, stop)
end

local gaps = {{start = minimumStart, stop = maximumStop}}
for item in pairs(items) do
    local newGaps = {}
    local function addGap(gap)
        if gap.start < gap.stop then table.insert(newGaps, gap) end
    end
    for _, gap in ipairs(gaps) do
        addGap({start = math.max(gap.start, item.stop), stop = gap.stop})
        addGap({start = gap.start, stop = math.min(gap.stop, item.start)})
    end
    gaps = newGaps
end

for _, gap in ipairs(gaps) do
    reaper.GetSet_LoopTimeRange(true, false, gap.start, gap.stop, false)
    reaper.Main_OnCommand(40201, 0) -- Time selection: Remove contents of time selection (moving later items)
end

reaper.Undo_EndBlock(
    "Remove gaps between selected items (Reposition selected items across tracks)",
    -1)
