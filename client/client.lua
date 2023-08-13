local usingGizmo = false
local mode = "Translate"
local extraZ = 100.0
local spawnedProp, pedBoneId = 0, 0
local lastCoord = nil
local newCoord = nil
local position, rotation = vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0)
local promptGroup, prompt1, prompt2, prompt3
local newpos = {x=0,y=0,z=0}

local function toggleNuiFrame(bool)
    usingGizmo = bool
    SetNuiFocus(bool, bool)
end

function useGizmo(handle, boneid, dict, anim)
    spawnedProp = handle
    pedBoneId = boneid

    local playerPed = PlayerPedId()
    lastCoord = GetEntityCoords(playerPed)

    FreezeEntityPosition(playerPed, true)
    SetEntityCoords(playerPed, lastCoord.x, lastCoord.y, lastCoord.z+extraZ-1)
    newCoord = GetEntityCoords(playerPed)
    SetEntityHeading(playerPed, 0.0)
    SetEntityRotation(pedBoneId, 0.0, 0.0, 0.0)
    position, rotation = vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0)
    AttachEntityToEntity(spawnedProp, playerPed, pedBoneId, 0,0,0, 0, 0,0, true, true, false, true, 1, true)

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = spawnedProp,
            position = vector3(newCoord.x, newCoord.y, newCoord.z),
            rotation = vector3(0.0, 0.0, 0.0)
        }
    })
    toggleNuiFrame(true)

    if dict and anim then taskPlayAnim(playerPed, dict, anim) end

    promptGroup:setActive(true)
    while usingGizmo do
        SendNUIMessage({
            action = 'setCameraPosition',
            data = {
                position = GetFinalRenderedCamCoord(),
                rotation = GetFinalRenderedCamRot()
            }
        })
        -- if IsControlJustReleased(0, 0x4A903C11) then
        --     SetNuiFocus(true, true)
        -- end
        DisableIdleCamera(true)
        Wait(0)
    end

    finish()
    return {
        "AttachEntityToEntity(entity, PlayerPedId(), "..pedBoneId..", "..newpos.z..", "..newpos.y..", "..newpos.x..", "..rotation.x..", "..rotation.y..", "..rotation.z..", true, true, false, true, 1, true)",
        newpos.z..", "..newpos.y..", "..newpos.x..", "..rotation.x..", "..rotation.y..", "..rotation.z
    }
end

RegisterNUICallback('moveEntity', function(data, cb)
    local entity = data.handle
    position = data.position
    rotation = data.rotation
    newpos.x = newCoord.x - position.x
    newpos.y = newCoord.y - position.y
    newpos.z = newCoord.z - position.z
    AttachEntityToEntity(entity, PlayerPedId(), pedBoneId, newpos.z, newpos.y, newpos.x, rotation.x, rotation.y, rotation.z, true, true, false, true, 1, true) --Same attach settings as dp emote and rp emotes
    cb('ok')
end)

RegisterNUICallback('finishEdit', function(data, cb)
    toggleNuiFrame(false)
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    cb('ok')
end)

RegisterNUICallback('swapMode', function(data, cb)
    mode = data.mode
    cb('ok')
end)

RegisterNUICallback('cam', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

CreateThread(function()
	promptGroup = UipromptGroup:new("Mas AttachProp", false)

    prompt1 = Uiprompt:new(`INPUT_FRONTEND_CANCEL`, "Done Editing", promptGroup)
    prompt2 = Uiprompt:new(`INPUT_COVER`, "NUI Focus", promptGroup)
    prompt3 = Uiprompt:new(`INPUT_MOVE_UP_ONLY`, "Rotate Mode (Focus)", promptGroup)
    prompt4 = Uiprompt:new(`INPUT_RELOAD`, "Translate Mode (Focus)", promptGroup)

    prompt1:setOnControlJustReleased(function()
        toggleNuiFrame(false)
        SendNUIMessage({
            action = 'setGizmoEntity',
            data = {
                handle = nil,
            }
        })
    end)
    prompt2:setOnControlJustReleased(function()
        SetNuiFocus(true, true)
    end)
    prompt3:setOnControlJustReleased(function()
        if mode == "Translate" then
            SendNUIMessage({
                action = 'setEditorMode',
                data = "rotate"
            })
        else
            SendNUIMessage({
                action = 'setEditorMode',
                data = "Translate"
            })
        end
    end)
    UipromptManager:startEventThread()
end)

function finish()
    if DoesEntityExist(spawnedProp) then
        DeleteEntity(spawnedProp)
    end
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    promptGroup:setActive(false)
    if lastCoord then
        SetEntityCoords(playerPed, lastCoord)
        lastCoord = nil
    end
end

function taskPlayAnim(ped, dict, anim, flag)
    CreateThread(function()
        while usingGizmo do
            if not IsEntityPlayingAnim(ped, dict, anim, 1) then
                while not HasAnimDictLoaded(dict) do
                    RequestAnimDict(dict)
                    Wait(10)
                end
                TaskPlayAnim(ped, dict, anim, 5.0, 5.0, -1, (flag or 2), 0, false, false, false)
                RemoveAnimDict(dict)
            end
            Wait(1000)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        finish()
    end
end)
