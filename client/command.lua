--Example: /prop ch_prop_ch_heist_drill 57005 anim@heists@fleeca_bank@drilling drill_straight_start
RegisterCommand('prop', function(source, args, rawCommand)
    local model = joaat(args[1] or "p_bread05x")
    if not HasModelLoaded(model) then RequestModel(model) while not HasModelLoaded(model) do Wait(1) end end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local object = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    local boneArg = args[2]
    local boneToNumber = tonumber(boneArg)
    local bone = (boneArg and boneToNumber) and GetPedBoneIndex(playerPed, boneToNumber) or boneArg and GetEntityBoneIndexByName(playerPed, boneArg) or 34606
    local objectPositionData = useGizmo(object, bone, args[3], args[4])
    print(objectPositionData[1])
    print(objectPositionData[2])
end, false)

TriggerEvent('chat:addSuggestion', '/prop', 'Attach prop with animations', {
    { name="model", help="prop name" },
    { name="boneindex", help="bone index" },
    { name="animdict", help="animation dictionary" },
    { name="animname", help="animation name" }
})