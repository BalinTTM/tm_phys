local crouch = true -- Disable/Enable crouch script (true = enable)
local crouchcommand = 'crouch' -- Command used for crouch
local disable_croll = true -- This will disable combat roll (there some bugs in there but now Im currently working on it) (true = disable)
local pointing = true -- Disable/Enable pointing script (true = enable)
local bikekick = true -- Disable/Enable bike kick script (Disable kicking while on a bike) (true = disable)
local handsupenb = true -- Disable/Enable hands up script (true = enable)
local handsupcommand = 'handsup' -- Command used for hands up script
local legshoot = true -- Disable/Enable legshooting script (Player ragdoll if get shot in the leg) (true = enable)
local shuffing = true -- Disable/Enable shuff script (If enabled, players wont shuff to the driver seat automatically, only if they use the command) (true = enable)
local shuffcommand = 'shuff' -- Command used for shuff

-- CONFIG UP HERE UNDER THIS DONT TOUCH ANYTHING


-- CROUCH
if crouch then
	Crouched = false
	CrouchedForce = false
	Aimed = false
	Cooldown = false
	PlayerInfo = {
		playerPed = PlayerPedId(),
		playerID = GetPlayerIndex(),
		nextCheck = GetGameTimer() + 1500
	}
	CoolDownTime = 500 -- in ms

	NormalWalk = function()
		SetPedMaxMoveBlendRatio(PlayerInfo.playerPed, 1.0)
		ResetPedMovementClipset(PlayerInfo.playerPed, 0.55)
		ResetPedStrafeClipset(PlayerInfo.playerPed)
		SetPedCanPlayAmbientAnims(PlayerInfo.playerPed, true)
		SetPedCanPlayAmbientBaseAnims(PlayerInfo.playerPed, true)
		ResetPedWeaponMovementClipset(PlayerInfo.playerPed)
		Crouched = false
	end

	SetupCrouch = function()
		while not HasAnimSetLoaded('move_ped_crouched') do
			Citizen.Wait(5)
			RequestAnimSet('move_ped_crouched')
		end
	end

	RemoveCrouchAnim = function()
		RemoveAnimDict('move_ped_crouched')
	end

	CanCrouch = function()
		if IsPedOnFoot(PlayerInfo.playerPed) and not IsPedInAnyVehicle(PlayerInfo.playerPed, false) and not IsPedJumping(PlayerInfo.playerPed) and not IsPedFalling(PlayerInfo.playerPed) and not IsPedDeadOrDying(PlayerInfo.playerPed) then
			return true
		else
			return false
		end
	end

	CrouchPlayer = function()
		SetPedUsingActionMode(PlayerInfo.playerPed, false, -1, "DEFAULT_ACTION")
		SetPedMovementClipset(PlayerInfo.playerPed, 'move_ped_crouched', 0.55)
		SetPedStrafeClipset(PlayerInfo.playerPed, 'move_ped_crouched_strafing') -- it force be on third person if not player will freeze but this func make player can shoot with good anim on crouch if someone know how to fix this make request :D
		SetWeaponAnimationOverride(PlayerInfo.playerPed, "Ballistic")
		Crouched = true
		Aimed = false
	end

	SetPlayerAimSpeed = function()
		SetPedMaxMoveBlendRatio(PlayerInfo.playerPed, 0.2)
		Aimed = true
	end

	IsPlayerFreeAimed = function()
		if IsPlayerFreeAiming(PlayerInfo.playerID) or IsAimCamActive() or IsAimCamThirdPersonActive() then
			return true
		else
			return false
		end
	end

	CrouchLoop = function()
		SetupCrouch()
		while CrouchedForce do
			DisableFirstPersonCamThisFrame()

			local now = GetGameTimer()
			if now >= PlayerInfo.nextCheck then
				PlayerInfo.playerPed = PlayerPedId()
				PlayerInfo.playerID = GetPlayerIndex()
				PlayerInfo.nextCheck = now + 1500
			end

			local CanDo = CanCrouch()
			if CanDo and Crouched and IsPlayerFreeAimed() then
				SetPlayerAimSpeed()
			elseif CanDo and (not Crouched or Aimed) then
				CrouchPlayer()
			elseif not CanDo and Crouched then
				CrouchedForce = false
				NormalWalk()
			end

			Citizen.Wait(5)
		end
		NormalWalk()
		RemoveCrouchAnim()
	end

	RegisterCommand(crouchcommand, function()
		DisableControlAction(0, 36, true) -- magic
		if not Cooldown then
			CrouchedForce = not CrouchedForce

			if CrouchedForce then
				CreateThread(CrouchLoop) -- Magic Part 2 lamo
			end

			Cooldown = true
			SetTimeout(CoolDownTime, function()
				Cooldown = false
			end)
		end
	end, false)

	RegisterKeyMapping('crouch', 'Crouch', 'keyboard', 'LCONTROL') -- now its better player can change to any bottom they want


	-- Exports --
	IsCrouched = function()
		return Crouched
	end

	exports("IsCrouched", IsCrouched)
end

-- DISABLE ROLL
if disable_croll then
	Citizen.CreateThread(function()
		while true do
			local sleep = 50
			if IsPedArmed(PlayerPedId(), 4) and IsControlPressed(0, 25) then
				sleep = 5
				DisableControlAction(0, 22, true)
			end
			Citizen.Wait(sleep)
		end
	end)
end

-- POINTING
if pointing then
	local mp_pointing = false
	local keyPressed = false

	local function startPointing()
		local ped = PlayerPedId()
		RequestAnimDict("anim@mp_point")
		while not HasAnimDictLoaded("anim@mp_point") do
			Wait(0)
		end
		SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
		SetPedConfigFlag(ped, 36, 1)
		Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
		RemoveAnimDict("anim@mp_point")
	end

	local function stopPointing()
		local ped = GetPlayerPed(-1)
		Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
		if not IsPedInjured(ped) then
			ClearPedSecondaryTask(ped)
		end
		if not IsPedInAnyVehicle(ped, 1) then
			SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
		end
		SetPedConfigFlag(ped, 36, 0)
		ClearPedSecondaryTask(PlayerPedId())
	end

	local once = true
	local oldval = false
	local oldvalped = false

	Citizen.CreateThread(function()
		while true do

			if once then
				once = false
			end

			if not keyPressed then
				if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
					Citizen.Wait(125)
					if not IsControlPressed(0, 29) then
						if not IsPedArmed(PlayerPedId(), 4) then
							keyPressed = true
							startPointing()
							mp_pointing = true
						end
					else
						keyPressed = true
						while IsControlPressed(0, 29) do
							Citizen.Wait(50)
						end
					end
				elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
					keyPressed = true
					mp_pointing = false
					stopPointing()
				end
			end

			if keyPressed then
				if not IsControlPressed(0, 29) then
					keyPressed = false
				end
			end
			if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
				stopPointing()
			end
			if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
				if not IsPedOnFoot(PlayerPedId()) then
					stopPointing()
				else
					local ped = PlayerPedId()
					local camPitch = GetGameplayCamRelativePitch()
					if camPitch < -70.0 then
						camPitch = -70.0
					elseif camPitch > 42.0 then
						camPitch = 42.0
					end
					camPitch = (camPitch + 70.0) / 112.0

					local camHeading = GetGameplayCamRelativeHeading()
					local cosCamHeading = Cos(camHeading)
					local sinCamHeading = Sin(camHeading)
					if camHeading < -180.0 then
						camHeading = -180.0
					elseif camHeading > 180.0 then
						camHeading = 180.0
					end
					camHeading = (camHeading + 180.0) / 360.0

					local blocked = 0
					local nn = 0

					local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
					local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
					nn,blocked,coords,coords = GetRaycastResult(ray)

					Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
					Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
					Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
					Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

				end
			end
			Citizen.Wait(10)
		end
	end)
end

-- DISABLE BIKE KICK
if bikekick then
	CreateThread(function()
		while true do
			local playerPed = PlayerPedId() -- Get the player's ped
			local isOnBike = IsPedOnAnyBike(playerPed) -- Check if the player is on a bike
			local sleep = 500

			if isOnBike then
				sleep = 5
				DisableControlAction(0, 345, true)
			end
			
			Citizen.Wait(sleep) -- Always include a wait to avoid crashing the game
		end
	end)
end

-- HANDSUP
if handsupenb then
	raised = false

	function RaiseHands()
		TaskPlayAnim(PlayerPedId(), "missminuteman_1ig_2", "handsup_enter", 2.0, 2.0, -1, 50, 0, false, false, false)
		raised = true
	end

	function LowerHands()
		ClearPedTasks(PlayerPedId())
		raised = false
	end

	function CheckVehicleEnablement()
		if IsPedInAnyVehicle(PlayerPedId(), false) or IsPedTryingToEnterALockedVehicle(PlayerPedId()) or IsPedGettingIntoAVehicle(PlayerPedId()) then
			return false
		else
			return true
		end
	end

	function BlockActions(bool)
		DisablePlayerFiring(PlayerPedId(), bool) -- Shooting
		DisableControlAction(0, 25, bool) -- Aiming
		DisableControlAction(0, 140, bool) -- Melee Attack 1
		DisableControlAction(0, 141, bool) -- Melee Attack 2
		DisableControlAction(0, 142, bool) -- Melee Attack 3
		DisableControlAction(0, 37, bool) -- Weapon Wheel
		DisableControlAction(0, 45, bool) -- Reloading
		DisableControlAction(0, 23, false) --Entering Vehicle (controlled by config)
		--ADD HERE OTHER ACTIONS YOU WANT TO BLOCK--
	end

	RegisterKeyMapping('handsup', 'Hands Up', 'keyboard', 'X')

	RegisterCommand(handsupcommand, function()
		if CheckVehicleEnablement() then
			if not IsPedReloading(PlayerPedId()) then
				if not raised then
					RaiseHands()
				else
					LowerHands()
				end
			end
		end
	end)


	-- Main Loop --
	Citizen.CreateThread(function()
		RequestAnimDict("missminuteman_1ig_2")
		while not HasAnimDictLoaded("missminuteman_1ig_2") do
			Citizen.Wait(100)
		end

		while true do
			Citizen.Wait(5)

			-- Disable Actions --
			if raised then
				BlockActions(true)
			end

			-- Ragdoll Fixing --
			if IsPedRagdoll(PlayerPedId()) and raised then
				raised = false
			end

			-- Vehicle Auto Lowering if inside (controlled by config) -- 
			if ((IsPedInAnyVehicle(PlayerPedId(), false))) and raised then
				Citizen.Wait(2500)
				LowerHands()
			end
		end
	end)

	-- Exports for other scripts --
	exports('raiseHands', function()
		RaiseHands()
	end)

	exports('lowerHands', function()
		LowerHands()
	end)

	exports('checkHands', function()
		return raised
	end)
end

-- LEGSHOOT
if legshoot then
	local BONES = {
		--[[Pelvis]][11816] = true,
		--[[SKEL_L_Thigh]][58271] = true,
		--[[SKEL_L_Calf]][63931] = true,
		--[[SKEL_L_Foot]][14201] = true,
		--[[SKEL_L_Toe0]][2108] = true,
		--[[IK_L_Foot]][65245] = true,
		--[[PH_L_Foot]][57717] = true,
		--[[MH_L_Knee]][46078] = true,
		--[[SKEL_R_Thigh]][51826] = true,
		--[[SKEL_R_Calf]][36864] = true,
		--[[SKEL_R_Foot]][52301] = true,
		--[[SKEL_R_Toe0]][20781] = true,
		--[[IK_R_Foot]][35502] = true,
		--[[PH_R_Foot]][24806] = true,
		--[[MH_R_Knee]][16335] = true,
		--[[RB_L_ThighRoll]][23639] = true,
		--[[RB_R_ThighRoll]][6442] = true,
	}


	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(10)
			local ped = PlayerPedId()
				--if IsShockingEventInSphere(102, 235.497,2894.511,43.339,999999.0) then
				if HasEntityBeenDamagedByAnyPed(ped) then
				--if GetPedLastDamageBone(ped) = 
						Disarm(ped)
				end
				ClearEntityLastDamageEntity(ped)
		end
	end)



	function Bool (num) return num == 1 or num == true end

	-- WEAPON DROP OFFSETS
	local function GetDisarmOffsetsForPed (ped)
		local v

		if IsPedWalking(ped) then v = { 0.6, 4.7, -0.1 }
		elseif IsPedSprinting(ped) then v = { 0.6, 5.7, -0.1 }
		elseif IsPedRunning(ped) then v = { 0.6, 4.7, -0.1 }
		else v = { 0.4, 4.7, -0.1 } end

		return v
	end

	function Disarm (ped)
		if IsEntityDead(ped) then return false end

		local boneCoords
		local hit, bone = GetPedLastDamageBone(ped)

		hit = Bool(hit)

		if hit then
			if BONES[bone] then

				boneCoords = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, bone))
				SetPedToRagdoll(PlayerPedId(), 5000, 5000, 0, 0, 0, 0)

				return true
			end
		end

		return false
	end
end

-- SHUFF

if shuffing then
	local allowshuffle = false
	local playerped=nil
	local currentvehicle=nil

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(200)
			playerped=PlayerPedId()
			currentvehicle=GetVehiclePedIsIn(playerped, false)
		end
	end)


	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(100)
			if IsPedInAnyVehicle(playerped, false) and allowshuffle == false then
				SetPedConfigFlag(playerped, 184, true)
				if GetIsTaskActive(playerped, 165) then
					seat=0
					if GetPedInVehicleSeat(currentvehicle, -1) == playerped then
						seat=-1
					end
					SetPedIntoVehicle(playerped, currentvehicle, seat)
				end
			elseif IsPedInAnyVehicle(playerped, false) and allowshuffle == true then
				SetPedConfigFlag(playerped, 184, false)
			end
		end
	end)


	RegisterNetEvent("SeatShuffle")
	AddEventHandler("SeatShuffle", function()
		if IsPedInAnyVehicle(playerped, false) then
			seat=0
			if GetPedInVehicleSeat(currentvehicle, -1) == playerped then
				seat=-1
			end
			if GetPedInVehicleSeat(currentvehicle,-1) == playerped then
				TaskShuffleToNextVehicleSeat(playerped,currentvehicle)
			end
			allowshuffle=true
			while GetPedInVehicleSeat(currentvehicle,seat) == playerped do
				Citizen.Wait(0)
			end
			allowshuffle=false
		else
			allowshuffle=false
			CancelEvent('SeatShuffle')
		end
	end)

	RegisterCommand(shuffcommand, function(source, args, raw)
		TriggerEvent("SeatShuffle")
	end, false)
end