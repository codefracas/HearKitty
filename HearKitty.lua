-- Hear Kitty  by Vger-Azjol-Nerub
-- www.vgermods.com
-- 
-- Version 1.3.2: Dark Transformation for unholy DKs
--
------------------------------------------------------------

HearKittyVersion = 1.0302

-- Hear Kitty requires this version of VgerCore:
local KittyVgerCoreVersionRequired = 1.02

-- Timer
local KittyTimerCountdown = 0

-- Other
local KittyEverHadBuffCharges = false
local KittyEverHadHolyPowerCharges = false
local KittyEverHadRollingThunderCharges = false
local KittyPetWasTransformed = false
local KittyThisResourceDecays = false -- Does this resource decay over time?  (For example, Holy Power.  Not counting expiring buffs.)
local KittyLastSoundPlayed = 0
local KittyQueueActive = false
local KittySoundOnTimer = nil
local KittyRequeuesOnTimer = 0

-- Sound packs (the default sound pack is actually registered later in the file)
local KittySoundPacks = { }
KittyDefaultSoundPackInternalName = "Default"

local KittyDefaultSoundPack =
{
	LocalizedName = KittyLocal.DefaultSoundPackName,
	Credits = KittyUIFrame_AboutHeaderLabel_Text,
	SoundDelay = 0.35,
	LongSoundDelay = 1, -- for transitioning from 0 to 1
	Combo5StackSound0 = "Interface\\AddOns\\HearKitty\\Symphony\\0.ogg",
	Combo5StackSound1 = "Interface\\AddOns\\HearKitty\\Symphony\\1.ogg",
	Combo5StackSound2 = "Interface\\AddOns\\HearKitty\\Symphony\\2.ogg",
	Combo5StackSound3 = "Interface\\AddOns\\HearKitty\\Symphony\\3.ogg",
	Combo5StackSound4 = "Interface\\AddOns\\HearKitty\\Symphony\\4.ogg",
	Combo5StackSound5 = "Interface\\AddOns\\HearKitty\\Symphony\\5.ogg",
	Combo3StackSound0 = "Interface\\AddOns\\HearKitty\\Symphony\\0.ogg",
	Combo3StackSound1 = "Interface\\AddOns\\HearKitty\\Symphony\\3.ogg",
	Combo3StackSound2 = "Interface\\AddOns\\HearKitty\\Symphony\\4.ogg",
	Combo3StackSound3 = "Interface\\AddOns\\HearKitty\\Symphony\\5.ogg",
}


------------------------------------------------------------
-- Hear Kitty events
------------------------------------------------------------

-- Called when an event that Hear Kitty cares about is fired.
function KittyOnEvent(self, Event, arg1, arg2)
	if Event == "UNIT_COMBO_POINTS" and (arg1 == "player" or arg1 == "vehicle") then
		KittyOnComboPointsChange(arg1)
	elseif Event == "UNIT_AURA" and (arg1 == "player" or arg1 == "pet") then
		KittyOnBuffsChange()
	elseif Event == "UNIT_POWER" and arg1 == "player" and arg2 == "HOLY_POWER" then
		KittyOnHolyPowerChange()
	elseif Event == "VARIABLES_LOADED" then 
		KittyInitialize()
	end 
end

-- Initializes Hear Kitty after all saved variables have been loaded.
function KittyInitialize()

	-- Check the current version of VgerCore.
	if (not VgerCore) or (not VgerCore.Version) or (VgerCore.Version < KittyVgerCoreVersionRequired) then
		if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cfffe8460" .. KittyLocal.NeedNewerVgerCoreMessage) end
		message(KittyLocal.NeedNewerVgerCoreMessage)
		return
	end

	SLASH_HEARKITTY1 = "/hearkitty"
	SlashCmdList["HEARKITTY"] = KittyCommand

	-- If they don't have any options set yet (no saved variable), reset them.  If they upgraded
	-- from a previous version and are missing one or more options, fill them in with defaults.
	KittyFillMissingOptions()
	
end

-- Called whenever the player's number of combo points changes.
function KittyOnComboPointsChange(Unit)
	KittyCurrentIgnoredStacks = 0
	KittyCurrentMaxStacks = 5
	KittyThisResourceDecays = false
	if (KittyOptions.Enabled == true) then KittyComboSound(GetComboPoints(Unit)) end
end

-- Called whenever the player's buffs change.
function KittyOnBuffsChange()
	-- Look for stacks of the various buffs we care about.
	local BuffCharges
	
	-- Maelstrom Weapon (enhancement shaman)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("player", KittyMaelstromName, nil, "HELPFUL")
		if BuffCharges then
			KittyThisResourceDecays = false
			KittyCurrentMaxStacks = 5
			KittyCurrentIgnoredStacks = 0
		end
	end
	-- Dark Transformation (unholy DK)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("pet", KittyDarkTransformationName, nil, "HELPFUL")
		if BuffCharges then
			-- The ghoul has transformed.  Remember this for the future.
			KittyPetWasTransformed = true
		elseif KittyPetWasTransformed then
			-- The ghoul used to be transformed and now it's not.  Play the "zero" sound.
			KittyCurrentMaxStacks = 5
			KittyPlayOneSound(0)
			KittyPetWasTransformed = false
		end
	end
	-- Shadow Infusion (unholy DK)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("pet", KittyShadowInfusionName, nil, "HELPFUL")
		if BuffCharges then
			KittyThisResourceDecays = false
			KittyCurrentMaxStacks = 5
			KittyCurrentIgnoredStacks = 0
			KittyPetWasTransformed = false
		end
	end
	-- Evangelism (discipline priest)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("player", KittyEvangelismName, nil, "HELPFUL")
		if BuffCharges then
			KittyThisResourceDecays = false
			KittyCurrentMaxStacks = 5
			KittyCurrentIgnoredStacks = 0
		end
	end
	-- Shadow Orb (shadow priest)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("player", KittyShadowOrbName, nil, "HELPFUL")
		if BuffCharges then
			KittyThisResourceDecays = false
			KittyCurrentMaxStacks = 3
			KittyCurrentIgnoredStacks = 0
		end
	end
	-- Lightning Shield (elemental shaman Rolling Thunder talent)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("player", KittyLightningShieldName, nil, "HELPFUL")
		if BuffCharges then
			-- If we've never had more than 3 stacks of Lightning Shield due to the Rolling Thunder talent,
			-- we should ignore all stacks of Lightning Shield less than 5.
			if BuffCharges < 5 and not KittyEverHadRollingThunderCharges then
				BuffCharges = nil
			else
				KittyThisResourceDecays = true -- when hit!
				KittyCurrentMaxStacks = 5
				KittyCurrentIgnoredStacks = 4
				KittyEverHadRollingThunderCharges = true
			end
		end
	end
	-- Ready, Set, Aim and Fire! (marksman hunter Master Marksman talent)
	if BuffCharges == nil then
		_, _, _, BuffCharges = UnitAura("player", KittyMasterMarksmanBuff5Name, nil, "HELPFUL")
		if BuffCharges then
			BuffCharges = 5
		else
			_, _, _, BuffCharges = UnitAura("player", KittyMasterMarksmanBuff1To4Name, nil, "HELPFUL")
		end
		if BuffCharges then
			KittyThisResourceDecays = false
			KittyCurrentMaxStacks = 5
			KittyCurrentIgnoredStacks = 0
		end
	end
	
	-- If we didn't find any buffs, it's possible that we've already had a buff before and it's worn off.
	if BuffCharges == nil then BuffCharges = 0 end
	
	if (BuffCharges > 0 or KittyEverHadBuffCharges) and (BuffCharges ~= KittyLastSoundPlayed) then
		-- Buff charges may have changed.  Play the new sound effect.
		-- (No-op if the number actually hasn't changed.)
		KittyComboSound(BuffCharges)
		KittyEverHadBuffCharges = true
	end
end

function KittyOnHolyPowerChange(HolyPowerCharges)
	local HolyPowerCharges = UnitPower("player", SPELL_POWER_HOLY_POWER)
	if (HolyPowerCharges > 0 or KittyEverHadHolyPowerCharges) and (HolyPowerCharges ~= KittyLastSoundPlayed) then
		-- (No-op if the number actually hasn't changed.)
		KittyCurrentIgnoredStacks = 0
		KittyCurrentMaxStacks = 3
		KittyThisResourceDecays = true
		KittyComboSound(HolyPowerCharges)
		KittyEverHadHolyPowerCharges = true
	end
end

-- Handles timer updates.  Called once per video frame.
function KittyOnUpdate(self, Elapsed)
	KittyTimerCountdown = KittyTimerCountdown - Elapsed
	if KittyTimerCountdown <= 0 then
		-- Was there a sound on the timer?  If not, then the timer can now be shut off.
		if KittySoundOnTimer == nil then
			KittyStopTimer()
			return
		end
		-- Play this sound effect.
		KittyPlayOneSound(KittySoundOnTimer)
		-- Then, queue the next sound if there is one, or queue the "sounds are done" timer.
		KittyTimerCountdown = KittyTimerCountdown + KittyGetSoundDelay()
		if KittyRequeuesOnTimer > 0 then
			KittySoundOnTimer = KittySoundOnTimer + 1
			KittyRequeuesOnTimer = KittyRequeuesOnTimer - 1
		else
			KittySoundOnTimer = nil
		end
	end
end

------------------------------------------------------------
-- Hear Kitty methods
------------------------------------------------------------

-- Resets all Hear Kitty options.  Used to set the saved variable to a default state.
function KittyResetOptions()
	KittyOptions = nil
	KittyFillMissingOptions()
end

-- Adds default values for any Hear Kitty options that are missing.  This can happen after an upgrade.
function KittyFillMissingOptions()
	if not KittyOptions then KittyOptions = {} end
	
	if KittyOptions.Enabled == nil then KittyOptions.Enabled = true end
	if KittyOptions.SoundPack == nil then KittyOptions.SoundPack = KittyDefaultSoundPackInternalName end
	if KittyOptions.Channel == nil then KittyOptions.Channel = "Master" end
	if KittyOptions.DoubleCrits == nil then KittyOptions.DoubleCrits = true end
	if KittyOptions.OnlyPlay5 == nil then KittyOptions.OnlyPlay5 = false end
end

-- Starts the timer counting down from a specified duration.
function KittyStartTimer(Duration)
	KittyQueueActive = true
	KittyTimerCountdown = Duration
	KittyCoreFrame:SetScript("OnUpdate", KittyOnUpdate)
end

-- Immediately stops the timer from firing.  Does not clear any other state information.
function KittyStopTimer()
	KittyQueueActive = false
	KittyTimerCountdown = nil
	KittySoundOnTimer = nil
	KittyCoreFrame:SetScript("OnUpdate", nil)
end

-- Processes a Hear Kitty slash command.
function KittyCommand(Command)
	local Lower = strlower(Command)
	if Lower == "" or Lower == nil then
		KittyUI_Show()
	elseif Lower == KittyLocal.EnabledCommand then
		KittyEnable(true)
		KittySayIfOn()
	elseif Lower == KittyLocal.DisabledCommand then
		KittyEnable(false)
		KittySayIfOn()
	else
		KittyUsage()
	end
end

-- Enables or disables Hear Kitty sound effects.
function KittyEnable(Enabled)
	VgerCore.Assert(Enabled == true or Enabled == false, "New value should be true or false.")
	KittyOptions.Enabled = Enabled
	KittyStopTimer()
end

-- Sets the channel that Hear Kitty sound effects play through.
function KittySetSoundChannel(Channel)
	VgerCore.Assert(Channel ~= nil, "Usage: KittySetSoundChannel(\"Channel\"), where Channel can be Master, SFX, Music, or Ambience.")
	KittyOptions.Channel = Channel
end

-- Prints a message stating whether or not Hear Kitty is enabled.
function KittySayIfOn()
	if KittyOptions.Enabled then
		VgerCore.Message(VgerCore.Color.Blue .. KittyLocal.EnabledMessage)
	else
		VgerCore.Message(VgerCore.Color.Blue .. KittyLocal.DisabledMessage)
	end
end

-- Enables or disables double crit sounds.
function KittyEnableDoubleCrits(Double)
	VgerCore.Assert(Double == true or Double == false, "New value should be true or false.")
	KittyOptions.DoubleCrits = Double
end

-- Enables or disables "only play 5" mode.
function KittyEnableOnlyPlay5(OnlyPlay5)
	VgerCore.Assert(OnlyPlay5 == true or OnlyPlay5 == false, "New value should be true or false.")
	KittyOptions.OnlyPlay5 = OnlyPlay5
end

-- Plays the appropriate sound effect for when the number of combo points changes.
function KittyComboSound(ComboPoints)
	VgerCore.Assert(KittyCurrentMaxStacks, "KittyCurrentMaxStacks should be set.")
	ComboPoints = ComboPoints - KittyCurrentIgnoredStacks
	-- It's possible (but rare) that stack buffs can go over the normal "maximum."  For example, lightning shield for elemental shamans normally goes up to 9, but mages
	-- can spellsteal a version of the buff with the same name that goes up to 20 stacks.
	if ComboPoints < 0 then ComboPoints = 0 elseif ComboPoints > KittyCurrentMaxStacks then ComboPoints = KittyCurrentMaxStacks end
	
	-- If the current number of combo points is zero, but we just played that sound effect, don't play it
	-- again.  This happens in various situations, such as when deselecting a freshly-killed enemy.
	if ComboPoints == 0 and KittyLastSoundPlayed == ComboPoints then return end
	
	-- If they have the double crits option disabled, this is all very easy.  Never queue.
	-- (Enabling "only play 5" forces double crits off.)
	if KittyOptions.DoubleCrits == false or KittyOptions.OnlyPlay5 then
		if (not KittyOptions.OnlyPlay5) or ComboPoints == 0 or ComboPoints == KittyCurrentMaxStacks then
			KittyPlayOneSound(ComboPoints)
		end
		KittyLastSoundPlayed = ComboPoints
		return
	end
	
	-- What we do next depends on whether we've increased or decreased combo points.
	if ComboPoints < KittyLastSoundPlayed then
		-- If the number of combo points has decreased, then they must have spent some.  Play the zero
		-- sound effect.  Then, if they have more than zero, they must have also gained some, so queue
		-- additional sounds.
		KittyStopTimer()
		if KittyThisResourceDecays and ComboPoints > 0 then
			-- Special case for Holy Power: this resource decays over time, so as it decays, don't play the "2"
			-- and "1" sound effects, but do play the "0" sound effect.
		else
			KittyPlaySoundRange(0, ComboPoints, KittyGetSoundDelay(true))
			-- After excess Lightning Shield charges from Rolling Thunder are expended, forget that we ever had rolling
			-- thunder, or things will screw up if the player respecs to enhancement.
			if ComboPoints == 0 then KittyEverHadRollingThunderCharges = false end
		end
	elseif ComboPoints == KittyLastSoundPlayed then
		-- Trying to remove this hack for 1.3
		-- If the number of combo points stayed the same, just replay the sound if it's 1 -- this covers most
		-- cases of quickly changing targets and adding a combo point.  In other cases, we'll ignore the
		-- duplicated event.
		--if ComboPoints == 1 then
		--	KittyPlaySoundRange(ComboPoints, ComboPoints)
		--end
	else
		-- If the number of combo points increased, play the new range of sounds.  If one's already queued,
		-- we'll just queue more instead of playing anything immediately.
		KittyPlaySoundRange(KittyLastSoundPlayed + 1, ComboPoints)
	end
	
	-- Remember the last number played from this function so we can play the correct sounds next time.
	KittyLastSoundPlayed = ComboPoints
end

-- Plays a range of sounds, queueing as necessary.  Optionally specifies the duration for the first sound queue;
-- subsequent sounds will use the standard duration.
function KittyPlaySoundRange(Start, End, FirstDuration)
	VgerCore.Assert(Start <= End, "Start should be less than or equal to End.")
	if Start > End then return end
	
	-- If there are other sounds waiting in the queue, just add to the queue and don't play anything immediately.
	if KittyQueueActive then
		if KittySoundOnTimer then
			-- There are other actual sounds waiting in the queue.
			KittyRequeuesOnTimer = End - KittySoundOnTimer
		else
			-- There are no sounds waiting in the queue, but we just finished playing the last one.
			KittySoundOnTimer = Start
			KittyRequeuesOnTimer = End - Start - 1
		end
		return
	end
	
	-- Play the starting sound.
	KittyPlayOneSound(Start)
	
	-- Finally, queue other sounds as necessary.
	if Start == End then
		-- We don't need to queue other sounds, but we do need to put "nothing" on the queue so that the next sound
		-- played still has to wait its turn.
		KittySoundOnTimer = nil
		KittyRequeuesOnTimer = 0
	else
		KittySoundOnTimer = Start + 1
		KittyRequeuesOnTimer = End - Start - 1
	end
	if FirstDuration == nil then FirstDuration = KittyGetSoundDelay() end
	KittyStartTimer(FirstDuration)
end

-- Immediately plays one combo point sound effect.  (Contrast with KittyComboSound.)
function KittyPlayOneSound(ComboPoints)
	VgerCore.Assert(KittyCurrentMaxStacks, "KittyCurrentMaxStacks should be set.")
	
	-- Look in the current sound pack for the appropriate sound to play.  If it's not present, look it
	-- up in the default sound pack.
	local SoundKey = "Combo" .. KittyCurrentMaxStacks .. "StackSound" .. ComboPoints
	local Filename = KittyCurrentSoundPack()[SoundKey]
	if not Filename then Filename = KittyDefaultSoundPack[SoundKey] end
	PlaySoundFile(Filename, KittyOptions.Channel)
end

-- Returns the currently selected sound pack if available, or the default one if the selected one
-- isn't installed.
function KittyCurrentSoundPack()
	return KittySoundPacks[KittyOptions.SoundPack] or KittyDefaultSoundPack
end

-- Gets the length of the sounds in the current sound pack.  If Long is true, returns the special length
-- of the "0" sound effect.
function KittyGetSoundDelay(Long)
	local SoundPack = KittyCurrentSoundPack()
	if Long then
		return SoundPack.LongSoundDelay or KittyDefaultSoundPack.LongSoundDelay
	else
		return SoundPack.SoundDelay or KittyDefaultSoundPack.SoundDelay
	end
end

-- Displays Hear Kitty usage information.
function KittyUsage()
	VgerCore.Message(" ")
	VgerCore.MultilineMessage(KittyLocal.Usage, VgerCore.Color.Blue)
	VgerCore.Message(" ")
end

------------------------------------------------------------
-- Hear Kitty sound packs
------------------------------------------------------------

-- Registers a new Hear Kitty sound pack for use.
function KittyRegisterSoundPack(Name, Options)
	if not Name or not Options then
		VgerCore.Fail("Usage: KittyRegisterSoundPack(\"Name\", { LocalizedName = \"Localized name\", ... })")
		return
	end
	if KittySoundPacks[Name] then
		VgerCore.Fail("Couldn't install this Hear Kitty sound pack because another one with the name \"" .. Name .. "\" has already been registered.")
		return
	end
	
	Options.Name = Name
	KittySoundPacks[Name] = Options
end

-- Selects a new sound pack based on its internal name.  (Register it first with KittyRegisterSoundPack.)
function KittySelectSoundPack(Name)
	if not KittySoundPacks[Name] then
		VgerCore.Fail("Usage: KittySelectSoundPack(\"Name\").  Name is the internal name of the sound pack, not the localized name.")
		return
	end
	
	KittyOptions.SoundPack = Name
end

-- Returns the internal name of the currently selected sound pack.
function KittyGetSelectedSoundPackName()
	VgerCore.Assert(KittyOptions.SoundPack, "KittyGetSelectedSoundPackName shouldn't be called before Hear Kitty finishes initializing.")
	if KittySoundPacks[KittyOptions.SoundPack] then
		return KittyOptions.SoundPack
	else
		-- If the currently selected sound pack isn't actually installed anymore, return the name
		-- of the default sound pack instead.
		return KittyDefaultSoundPackInternalName
	end
end

-- Returns the credits information for the currently selected sound pack.
function KittyGetSelectedSoundPackCredits()
	local SoundPack = KittyCurrentSoundPack()
	return SoundPack.Credits
end

-- Returns the live table of sound pack information.  Don't change it or Hear Kitty will scratch your eyes out!
function KittyGetSoundPacks()
	local TableCopy = { }
	
	local Name, Options
	for Name, Options in pairs(KittySoundPacks) do
		tinsert(TableCopy, Options)
	end
	sort(TableCopy, KittyLocalizedNameComparer)
	
	return TableCopy
end

-- Function used to sort a table of tables alphabetically by the inner tables' LocalizedName property values.
function KittyLocalizedNameComparer(a, b)
	return strlower(a.LocalizedName) < strlower(b.LocalizedName)
end

------------------------------------------------------------

-- Core frame setup
if not KittyCoreFrame then
	KittyCoreFrame = CreateFrame("Frame", "KittyCoreFrame")
end

KittyCoreFrame:SetScript("OnEvent", KittyOnEvent)

KittyCoreFrame:RegisterEvent("VARIABLES_LOADED")
KittyCoreFrame:RegisterEvent("UNIT_COMBO_POINTS")
KittyCoreFrame:RegisterEvent("UNIT_AURA")
KittyCoreFrame:RegisterEvent("UNIT_POWER")

-- Register the default sound pack
KittyRegisterSoundPack(KittyDefaultSoundPackInternalName, KittyDefaultSoundPack)
