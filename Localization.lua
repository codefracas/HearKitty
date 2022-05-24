-- Hear Kitty  by Vger-Azjol-Nerub
-- 
-- English resources

------------------------------------------------------------


------------------------------------------------------------
-- Buff name strings
------------------------------------------------------------

-- Names of buffs that work like combo points.
KittyEvangelismName = "Evangelism"
KittyLightningShieldName = "Lightning Shield"
KittyMasterMarksmanBuff1To4Name = "Ready, Set, Aim..."
KittyMasterMarksmanBuff5Name = "Fire!"
KittyMaelstromName = "Maelstrom Weapon"
KittyShadowInfusionName = "Shadow Infusion"
KittyShadowOrbName = "Shadow Orb"

-- Names of other buffs to watch for.
KittyDarkTransformationName = "Dark Transformation"

------------------------------------------------------------
-- Interface Options UI strings
------------------------------------------------------------

KittyUIFrame_AboutTab_Text = "About"
KittyUIFrame_AboutHeaderLabel_Text = "by Vger-Azjol-Nerub"
KittyUIFrame_AboutVersionLabel_Text = "Version %s"
KittyUIFrame_AboutTranslationLabel_Text = "Official English version" -- Translators: credit yourself here... "Klingon translation by Stovokor"
KittyUIFrame_OptionsHeaderLabel_Text = "Hear Kitty options"
KittyUIFrame_OptionsSubHeaderLabel_Text = "These options let you control the sounds that Hear Kitty makes."

KittyUIFrame_EnableSoundsCheck_Text = "Play sounds"
KittyUIFrame_EnableSoundsCheck_Tooltip = "With this option enabled, Hear Kitty will play sounds as you gain and spend combo points (and Maelstrom Weapon and Holy Power charges).  If this option is disabled, Hear Kitty will do nothing.\n\nShortcuts:\n/hearkitty on\n/hearkitty off"
KittyUIFrame_SoundPackDropDown_Label_Text = "Sound pack:"
KittyUIFrame_SoundPackDropDown_Tooltip = "If you install additional sound packs, you can pick a new set of sounds for Hear Kitty to use."
KittyUIFrame_UseEffectsChannelCheck_Text = "Control Hear Kitty sound volume the same as in-game sounds"
KittyUIFrame_UseEffectsChannelCheck_Tooltip = "Enable this option to allow the Sound volume slider and the Sound Effects option to also affect Hear Kitty sounds.\n\n|cffffffffOff:|r Only the Master volume setting affects Hear Kitty sounds.  Hear Kitty sounds will play even if in-game sound effects are disabled.  (default)\n|cffffffffOn:|r Both the Master and Sounds volume settings affect Hear Kitty sounds.  This will make the sounds quieter if the Sound volume slider is lower than 100%.  If in-game sound effects are muted, Hear Kitty sounds will be muted too."
KittyUIFrame_DisabledWarningLabel_Text = "All Hear Kitty sounds are disabled.  The following options will not take effect:"
KittyUIFrame_OnlyPlay5Check_Text = "Only play a tone when resource is maxed"
KittyUIFrame_OnlyPlay5Check_Tooltip = "With this option enabled, Hear Kitty will only play a tone when your resource is full (five combo points, three Holy Power, nine Lightning Shield charges) and when you spend your combo points.  If this option is disabled, tones are played for each resource gained."
KittyUIFrame_DoubleCritsCheck_Text = "Play multiple tones on a crit"
KittyUIFrame_DoubleCritsCheck_Tooltip = "With this option enabled, Hear Kitty will play two distinct tones when you gain two or more combo points simultaneously due to a critical hit (with the appropriate talents).  If this option is disabled, only one tone is played per attack."


------------------------------------------------------------
-- Console strings
------------------------------------------------------------

KittyLocal =
{

	-- General messages
	["NeedNewerVgerCoreMessage"] = "Hear Kitty needs a newer version of VgerCore.  Please use the version of VgerCore that came with Hear Kitty.",
	
	-- Default sound pack
	["DefaultSoundPackName"] = "Symphony",
	
	-- Slash commands
	["EnabledCommand"] = "on",
	["EnabledMessage"] = "Hear Kitty sounds are enabled.",
	["DisabledCommand"] = "off",
	["DisabledMessage"] = "Hear Kitty sounds are disabled.",
	
	["Usage"] = [[
Hear Kitty by Vger-Azjol-Nerub
www.vgermods.com
 
/hearkitty -- Show the Hear Kitty configuration UI.
/hearkitty [on | off] -- Turn Hear Kitty sound effects on (default) or off.
]],

}