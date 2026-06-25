local TableUtils = {}

function TableUtils:ArrayFindIndexOfValue(table, value): number?
    local index: number?
    for i, v in ipairs(table) do
        if v == value then
            index = i
            break
        end
    end
    return index
end

function TableUtils:ArrayRemove(array, value)
    local index_to_remove = self:ArrayFindIndexOfValue(array, value)
    if index_to_remove then
        table.remove(array, index_to_remove)
    end
end

function TableUtils:CopyDictionary(table)
    local copied = {}
    for k, v in pairs(table) do
        copied[k] = v
    end
    return copied
end

function TableUtils:ArraysEqual(a: {any}, b: {any}): boolean
    if #a ~= #b then return false end
    for i, v in ipairs(a) do
        if b[i] ~= v then return false end
    end
    return true
end

return TableUtils