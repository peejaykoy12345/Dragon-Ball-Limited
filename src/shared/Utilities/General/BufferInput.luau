local BufferService = {}
BufferService.__index = BufferService

local BUFFER_TIME = 0.25
local InputBuffer: {[Player]: {input: string, executeFunc: () -> (), time: number, isHeld: (() -> boolean)?}} = {}
local EndBuffer: {[Player]: {input: string, executeFunc: () -> ()}} = {}

function BufferService:Press(plr: Player, input: string, executeFunc: () -> (), isHeld: (() -> boolean)?)
	if EndBuffer[plr] and EndBuffer[plr].input == input then
		EndBuffer[plr] = nil
	end

	InputBuffer[plr] = {
		input = input,
		executeFunc = executeFunc,
		time = os.clock(),
		isHeld = isHeld,
	}
end

function BufferService:PressEnd(plr: Player, input: string, executeFunc: () -> ())
	EndBuffer[plr] = {
		input = input,
		executeFunc = executeFunc,
	}
end

function BufferService.TryConsumeBuffer(plr: Player)
	local buffered = InputBuffer[plr]
	local endBuffered = EndBuffer[plr]

	if buffered then
		local timePassed = os.clock() - buffered.time

		InputBuffer[plr] = nil

		if buffered.isHeld then
			local stillHeld = buffered.isHeld()

			if not stillHeld then
				EndBuffer[plr] = nil
				return
			end

			EndBuffer[plr] = nil
			local func = buffered.executeFunc
			if func then func() end
			return
		else
			if endBuffered and timePassed > BUFFER_TIME then
				EndBuffer[plr] = nil
				return
			end

			local func = buffered.executeFunc
			if func then func() end
			EndBuffer[plr] = nil
			return
		end
	end

	if endBuffered then
		EndBuffer[plr] = nil
		local func = endBuffered.executeFunc
		if func then func() end
	end
end

return BufferService