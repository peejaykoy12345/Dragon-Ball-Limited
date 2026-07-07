local RaceData = {
    Saiyan = {
        HasTail = true,
        PowerLevel = {500, 800},
    }
}

function RaceData.GetRaceData(raceName: string)
    return RaceData[raceName]
end

return RaceData