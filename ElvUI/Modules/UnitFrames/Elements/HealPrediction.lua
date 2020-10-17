local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

local CreateFrame = CreateFrame
function UF.HealthClipFrame_HealComm(frame)
	if frame.HealthPrediction then
		UF:SetAlpha_HealComm(frame.HealthPrediction, 1)
		UF:SetVisibility_HealComm(frame.HealthPrediction)
	end
end

function UF:SetAlpha_HealComm(obj, alpha)
	obj.myBar:SetAlpha(alpha)
	obj.otherBar:SetAlpha(alpha)
	obj.absorbBar:SetAlpha(alpha)
	obj.healAbsorbBar:SetAlpha(alpha)
end

function UF:SetTexture_HealComm(obj, texture)
	obj.myBar:SetStatusBarTexture(texture)
	obj.otherBar:SetStatusBarTexture(texture)
	obj.absorbBar:SetStatusBarTexture(texture)
	obj.healAbsorbBar:SetStatusBarTexture(texture)
end

function UF:SetVisibility_HealComm(obj)
	-- the first update is from `HealthClipFrame_HealComm`
	-- we set this variable to allow `Configure_HealComm` to
	-- update the elements overflow lock later on by option
	if not obj.allowClippingUpdate then
		obj.allowClippingUpdate = true
	end

	if obj.maxOverflow > 1 then
		obj.myBar:SetParent(obj.health)
		obj.otherBar:SetParent(obj.health)
		obj.healAbsorbBar:SetParent(obj.health)
	else
		obj.myBar:SetParent(obj.parent)
		obj.otherBar:SetParent(obj.parent)
		obj.healAbsorbBar:SetParent(obj.parent)
	end
end

function UF:Construct_HealComm(frame)
	local health = frame.Health
	local parent = health.ClipFrame

	local myBar = CreateFrame('StatusBar', nil, parent)
	local otherBar = CreateFrame('StatusBar', nil, parent)
	local absorbBar = CreateFrame('StatusBar', nil, parent)
	local healAbsorbBar = CreateFrame('StatusBar', nil, parent)

	myBar:SetFrameLevel(11)
	otherBar:SetFrameLevel(11)
	absorbBar:SetFrameLevel(11)
	healAbsorbBar:SetFrameLevel(11)

	local prediction = {
		myBar = myBar,
		otherBar = otherBar,
		absorbBar = absorbBar,
		healAbsorbBar = healAbsorbBar,
		PostUpdate = UF.UpdateHealComm,
		maxOverflow = 1,
		health = health,
		parent = parent,
		frame = frame
	}

	UF:SetAlpha_HealComm(prediction, 0)
	UF:SetTexture_HealComm(prediction, E.media.blankTex)

	return prediction
end

function UF:UpdatePositions_HealComm(frame)
	local health = frame.Health
	local pred = frame.HealthPrediction
	local myBar = pred.myBar
	local otherBar = pred.otherBar
	local absorbBar = pred.absorbBar
	local healAbsorbBar = pred.healAbsorbBar

	local db = frame.db.healPrediction
	local width, height = health:GetSize()
	local orientation = health:GetOrientation()
	local reverseFill = health:GetReverseFill()
	local myBarTexture = myBar:GetStatusBarTexture()
	local healthBarTexture = health:GetStatusBarTexture()
	local otherBarTexture = otherBar:GetStatusBarTexture()

	-- fallback just incase? this shouldnt be need anymore
	if not width or width <= 0 then width = health.WIDTH end
	if not height or height <= 0 then height = health.HEIGHT end

	if orientation == 'HORIZONTAL' then
		local p1 = reverseFill and 'RIGHT' or 'LEFT'
		local p2 = reverseFill and 'LEFT' or 'RIGHT'

		local anchor = db.anchorPoint
		pred.anchor, pred.anchor1, pred.anchor2 = anchor, p1, p2

		myBar:ClearAllPoints()
		myBar:Point(anchor, health)
		myBar:Point(p1, healthBarTexture, p2)

		otherBar:ClearAllPoints()
		otherBar:Point(anchor, health)
		otherBar:Point(p1, myBarTexture, p2)

		healAbsorbBar:ClearAllPoints()
		healAbsorbBar:Point(anchor, health)

		absorbBar:ClearAllPoints()
		absorbBar:Point(anchor, health)

		if db.absorbStyle == 'REVERSED' then
			absorbBar:Point(p2, health, p2)
		else
			absorbBar:Point(p1, otherBarTexture, p2)
		end

		local barHeight = db.height
		if barHeight == -1 or barHeight > height then barHeight = height end

		myBar:Size(width, barHeight)
		otherBar:Size(width, barHeight)
		healAbsorbBar:Size(width, barHeight)
		absorbBar:Size(width, barHeight)
	else
		local p1 = reverseFill and 'TOP' or 'BOTTOM'
		local p2 = reverseFill and 'BOTTOM' or 'TOP'

		local anchor = (db.anchorPoint == 'BOTTOM' and 'RIGHT') or (db.anchorPoint == 'TOP' and 'LEFT') or db.anchorPoint -- convert this for vertical too
		pred.anchor, pred.anchor1, pred.anchor2 = anchor, p1, p2

		myBar:ClearAllPoints()
		myBar:Point(anchor, health)
		myBar:Point(p1, healthBarTexture, p2)

		otherBar:ClearAllPoints()
		otherBar:Point(anchor, health)
		otherBar:Point(p1, myBarTexture, p2)

		healAbsorbBar:ClearAllPoints()
		healAbsorbBar:Point(anchor, health)

		absorbBar:ClearAllPoints()
		absorbBar:Point(anchor, health)

		if db.absorbStyle == 'REVERSED' then
			absorbBar:Point(p2, health, p2)
		else
			absorbBar:Point(p1, otherBarTexture, p2)
		end

		local barWidth = db.height -- this is really width now not height
		if barWidth == -1 or barWidth > width then barWidth = width end

		myBar:Size(barWidth, height)
		otherBar:Size(barWidth, height)
		healAbsorbBar:Size(barWidth, height)
		absorbBar:Size(barWidth, height)
	end
end

function UF:Configure_HealComm(frame)
	local db = frame.db.healPrediction
	if db and db.enable then
		frame.needsSizeUpdated = true

		local pred = frame.HealthPrediction
		local myBar = pred.myBar
		local otherBar = pred.otherBar
		local absorbBar = pred.absorbBar
		local healAbsorbBar = pred.healAbsorbBar

		local colors = self.db.colors.healPrediction
		pred.maxOverflow = 1 + (colors.maxOverflow or 0)

		if pred.allowClippingUpdate then
			UF:SetVisibility_HealComm(pred)
		end

		if not frame:IsElementEnabled('HealthPrediction') then
			frame:EnableElement('HealthPrediction')
		end

		local health = frame.Health
		local orientation = health:GetOrientation()
		local reverseFill = health:GetReverseFill()
		local healthBarTexture = health:GetStatusBarTexture()

		UF:SetTexture_HealComm(pred, UF.db.colors.transparentHealth and E.media.blankTex or healthBarTexture:GetTexture())

		myBar:SetReverseFill(reverseFill)
		otherBar:SetReverseFill(reverseFill)
		healAbsorbBar:SetReverseFill(not reverseFill)

		if db.absorbStyle == 'REVERSED' then
			absorbBar:SetReverseFill(not reverseFill)
		else
			absorbBar:SetReverseFill(reverseFill)
		end

		myBar:SetStatusBarColor(colors.personal.r, colors.personal.g, colors.personal.b, colors.personal.a)
		otherBar:SetStatusBarColor(colors.others.r, colors.others.g, colors.others.b, colors.others.a)
		absorbBar:SetStatusBarColor(colors.absorbs.r, colors.absorbs.g, colors.absorbs.b, colors.absorbs.a)
		healAbsorbBar:SetStatusBarColor(colors.healAbsorbs.r, colors.healAbsorbs.g, colors.healAbsorbs.b, colors.healAbsorbs.a)

		myBar:SetOrientation(orientation)
		otherBar:SetOrientation(orientation)
		absorbBar:SetOrientation(orientation)
		healAbsorbBar:SetOrientation(orientation)
	elseif frame:IsElementEnabled('HealthPrediction') then
		frame:DisableElement('HealthPrediction')
	end
end

function UF:UpdateHealComm(_, _, _, absorb, _, hasOverAbsorb, hasOverHealAbsorb, health, maxHealth)
	local frame = self.frame
	local db = frame and frame.db and frame.db.healPrediction
	if not db or not db.absorbStyle then return end

	local pred = frame.HealthPrediction
	local otherBar = pred.otherBar
	local absorbBar = pred.absorbBar
	local healAbsorbBar = pred.healAbsorbBar

	-- absorbs is set to none so hide both and kill code execution
	if db.absorbStyle == 'NONE' then
		healAbsorbBar:Hide()
		absorbBar:Hide()
		return
	end

	-- this will delay setting things until its ready
	if frame.needsSizeUpdated then
		UF:UpdatePositions_HealComm(frame)
		frame.needsSizeUpdated = nil
	end

	local frameHealth = frame.Health
	local colors = UF.db.colors.healPrediction
	local maxOverflow = colors.maxOverflow or 0
	local reverseFill = frameHealth:GetReverseFill()
	local healthBarTexture = frameHealth:GetStatusBarTexture()
	local otherBarTexture = otherBar:GetStatusBarTexture()

	-- handle over heal absorbs
	healAbsorbBar:ClearAllPoints()
	healAbsorbBar:Point(pred.anchor, frameHealth)

	if hasOverHealAbsorb then -- forward fill it when its greater than health so that you can still see this is being stolen
		healAbsorbBar:SetReverseFill(reverseFill)
		healAbsorbBar:Point(pred.anchor1, healthBarTexture, pred.anchor2)
		healAbsorbBar:SetStatusBarColor(colors.overhealabsorbs.r, colors.overhealabsorbs.g, colors.overhealabsorbs.b, colors.overhealabsorbs.a)
	else -- otherwise just let it backfill so that we know how much is being stolen
		healAbsorbBar:SetReverseFill(not reverseFill)
		healAbsorbBar:Point(pred.anchor2, healthBarTexture, pred.anchor2)
		healAbsorbBar:SetStatusBarColor(colors.healAbsorbs.r, colors.healAbsorbs.g, colors.healAbsorbs.b, colors.healAbsorbs.a)
	end

	-- color absorb bar if in over state
	if hasOverAbsorb then
		absorbBar:SetStatusBarColor(colors.overabsorbs.r, colors.overabsorbs.g, colors.overabsorbs.b, colors.overabsorbs.a)
	else
		absorbBar:SetStatusBarColor(colors.absorbs.r, colors.absorbs.g, colors.absorbs.b, colors.absorbs.a)
	end

	-- if we are in normal mode and overflowing happens we should let a bit show, like blizzard does
	if db.absorbStyle == 'NORMAL' then
		if hasOverAbsorb and health == maxHealth then
			absorbBar:SetValue(1.5)
			absorbBar:SetMinMaxValues(0, 100)
			absorbBar:SetParent(pred.health) -- lets overflow happen
		else
			absorbBar:SetParent(pred.parent) -- prevents overflow
		end
	else
		if maxOverflow > 0 then
			absorbBar:SetParent(pred.health)
		else
			absorbBar:SetParent(pred.parent)
		end

		if hasOverAbsorb then -- non normal mode overflowing
			if db.absorbStyle == 'WRAPPED' then -- engage backfilling
				absorbBar:SetReverseFill(not reverseFill)

				absorbBar:ClearAllPoints()
				absorbBar:Point(pred.anchor, pred.health)
				absorbBar:Point(pred.anchor2, pred.health, pred.anchor2)
			elseif db.absorbStyle == 'OVERFLOW' then -- we need to display the overflow but adjusting the values
				local overflowAbsorb = absorb * maxOverflow
				if health == maxHealth then
					absorbBar:SetValue(overflowAbsorb)
				else -- fill the inner part along with the overflow amount so it smoothly transitions
					absorbBar:SetValue((maxHealth - health) + overflowAbsorb)
				end
			end
		elseif db.absorbStyle == 'WRAPPED' then -- restore wrapped to its forward filling state
			absorbBar:SetReverseFill(pred.reverseFill)

			absorbBar:ClearAllPoints()
			absorbBar:Point(pred.anchor, pred.health)
			absorbBar:Point(pred.anchor1, otherBarTexture, pred.anchor2)
		end
	end
end
