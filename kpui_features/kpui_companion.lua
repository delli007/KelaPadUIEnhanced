-- KelaPadUI companion information and rapport notifications.
-- Extracted from KelaPadUI.lua during the refactor; behavior is unchanged.

local function Set_Companion_Notifications()
	local maxRapport = GetMaximumRapport()
	local stopNotifyRapportLevel = 4000 -- After this amount, don't notify, since 
	
	EVENT_MANAGER:RegisterForEvent("KelaPadUI", EVENT_COMPANION_RAPPORT_UPDATE, function( eventCode, companionId, previousRapport, currentRapport )
		if currentRapport < stopNotifyRapportLevel or previousRapport < stopNotifyRapportLevel then
			CHAT_ROUTER:AddSystemMessage(zo_strformat(
				"<<1>> <<2>>: <<3>> <<4>>",
				os.date("[%H:%M:%S]", GetTimeStamp()),
				GetString(SI_COMPANION_OVERVIEW_RAPPORT),
				GetCompanionName(companionId),
				string.format("%+d (%d/%d)", currentRapport - previousRapport, currentRapport, maxRapport)
			))
		end
	end)
end
local function Stop_Companion_Notifications()
	EVENT_MANAGER:UnregisterForEvent("KelaPadUI", EVENT_COMPANION_RAPPORT_UPDATE)
end

-- Adds companion rapport numbers to the companion information UI
local function Add_Enhanced_Companion_Information()
	local companionInfo = {
		-- Bastion Hallix
		[1] = {
			"+125:  Complete a Mages Guild daily offered by Alvur Baren",
			"+10:  Visit or pass by a Mages Guild guildhall within Alliance zones [20 hours]",
			"+10:  Visit Artaeum via portal in Keep of the Eleven Forces, the Grand Psijic Villa, quest specific zone, by stepping one meter away from the wayshrine, or Eyevea (cooldown shared across both) [20 hours]",
			"+10:  Completing random Encounters that help people such as rescuing merchants from bandits, summoners from Daedra, and travelers during Ambushes. not sure about other encounters",
			"+5:  Scry an Antiquity [5 minutes]",
			"+5:  Loot a Psijic portal",
			"+1:  Kill a Worm Cultist at the start of a Dark Anchor [5-10 minutes(?)]",
			"+1:  Kill any Cultist [1 minute]",
			"+1:  Killing bandits anywhere [1 minute]",
			"+1:  Read a book [15 minutes]",
			"-1:  Cooking food with cheese",
			"-1:  Attempting to flee from guards",
			"-5:  Killing passive animals",
			"-5:  Stealing",
			"-5:  Pickpocketing",
			"-10:  Getting caught stealing or pickpocketing",
			"-10:  Attacking innocents",
			"-25:  Murder"
		},
		-- Mirri Elendis
		[2] = {
			"+125:  Returning Dark Anchor contract offered by Cardea Gallus in Fighters Guild",
			"+125:  Returning Numani-Rasi relics daily in Vvardenfell while unmounted",
			"+10:  Mirri commenting Clockwork City while visiting it.",
			"+10:  Enter certain daedric delves and public dungeons, such as Ashalmawia, Broken Tusk, Mehrunes' Spite, Sanguine's Demesne, The Cave of Trophies and The Grotto of Depravity [30 minutes]",
			"+10:  Talking to Sotha Sil",
			"+5:  Excavate an Antiquity [5 minutes]",
			"+75/+5:  View a completed Khajiit of the Moons [20 hours]",
			"+75/+5:  View a completed Library of Vivec [20 hours]",
			"+75/+5:  View a completed Kari's Hit List [20 hours]",
			"+75/+5:  View a completed House of Orsimer Glories [20 hours]",
			"+75/+5:  View a completed Vault of Moawita [20 hours]",
			"+75/+5:  View a completed Rithana-di-Renada [20 hours]",
			"+1:  Kill a goblin [5 minutes]",
			"+1:  Kill a riekling [5 minutes]",
			"+1:  Kill a snake. Includes passive snakes, giant snakes and others (cooldown shared across all snake types) [150 seconds]",
			"+1:  Craft an alcoholic beverage [5 minutes]",
			"+1:  Reading a book from a shelf [> 30 minutes]",
			"+1:  Summoning a Daedric pet",
			"-1:  Harvest a torchbug or butterfly",
			"-10:  Enter the Dark Brotherhood Sanctuary",
			"-25/-5:  Use the Blade of Woe, including against enemies"
		},
		-- Ember
		[5] = {
			"+125:  Returning Thieves Guild heist with or without the time bonus [Daily]",
			"+125:  Returning relic retrieving quest offered by Alvur Baren in Mages Guild [Daily]",
			"+125:  Returning delve quest offered by Wayllod at High Isle [Daily]",
			"+25/+5:  Fence a purple-quality stolen item [24 hours]",
			"+10/+1:  Win a game of Tales of Tribute [1 hour]",
			"+10/+1:  Pickpocket a guard [1 hour]",
			"+10:  Using clemency [24 hours]",
			"+5/+1:  Loot a thieves trove or safebox [1 hour]",
			"+5:  Using a Counterfeit Pardon Edict",
			"+5:  Returning a Thieves Guild job from a Tip Board [1 hour]",
			"+1:  Visit outlaws refuges or Thieves Guild [1 hour]",
			"+1:  Harvest a runestone [5 minutes]",
			"+1:  Kill a werewolf [5 minutes]",
			"+1:  Kill a wolf [5 minutes]",
			"+1:  Summon the Big-Eared Ginger Kitten or Witch's Infernal Familiar pet [24 hours]",
			"+1:  Sell a purple-quality item to a vendor",
			"+1:  Successfully flee from the guard",
			"+1:  Trespass a restricted area",
			"-5/-1:  Start fishing [5 minutes]",
			"-5:  Pay a bounty to a guard after being caught while the other bounty rapport cooldown is active",
			"-10:  Get caught committing a crime",
			"-10:  Get spotted while trespassing in a restricted area",
			"-10:  Entering The Halls of Colossus",
			"-25/-5:  Pay a bounty to a guard after being caught [1 hour]"
		},
		-- Isobel Veloise
		[6] = {
			"+125:  Return a Undaunted daily challenge offered by Bolgrul [Daily]",
			"+125:  Return High Isle group boss daily offered by Parisse Plouff [Daily]",
			"+25/+5:  Visit an Undaunted Enclave [20 hours]",
			"+10/+5/+1:  Talk to an alliance leader (Emeric / Ayrenn / Jorunn) [1 hour]",
			"+10:  Talk to Lyris Titanborn [1 hour]",
			"+10:  Complete a volcanic vent",
			"+5:  Craft sweet delicacies or fruit dishes [1 hour]",
			"+5:  Craft an item at a blacksmithing station [1 hour]",
			"+5:  Kill a world boss [1 hour]",
			"+5:  Kill a delve boss or group dungeon boss",
			"+5:  Kill a daedric boss [1 hour]",
			"+1:  Kill a daedra [210 seconds]",
			"+1:  Use a repair kit [Daily]",
			"+1:  Accept a duel",
			"+1:  Summoning a dog non-combat pet [1 hour]",
			"-1:  Steal from container or loot a thieves trove",
			"-1:  Enter an Outlaw's Refuge",
			"-5:  Enter the Dark Brotherhood Sanctuary [20 hours]",
			"-10/-1:  Murder"
		},
		-- Azandar Al-Cybiades
		[9] = {
			"+500:  Completing each part of his companion quest",
			"+125:  Doing the Daily Enchanting crafting writ",
			"+125:  Returning Daily Delve quest offered by Ordinator Tilena in Necrom",
			"+10:  Visiting mundus stones",
			"+10:  Destroying end mechanism in Blackwood portals",
			"+10:  Going to Coldharbour / Fargrave / Brass Fortress",
			"+5:  Master enchanting writ",
			"+5:  Harvesting psijic portal",
			"+5:  Scrying an antiquity",
			"+5:  Finding a lead",
			"+5:  Activating ayleid wells",
			"+5:  Doing a regular (non-daily) enchanting writ",
			"+5:  Stealing a ritual object / oddity / magical curiosity",
			"+5:  Finding a new lorebook",
			"+1:  Killing mudcrabs/dreughs/chaurus/ogres/trolls/harpies/nix-oxen/dunerippers",
			"+1:  Crafting tea",
			"+?:  Skills Respec at the respec shrine",
			"-1:  Playing a ToT match",
			"-1:  Crafting coffee",
			"-1:  Harvesting mushrooms",
			"-10:  Going to Artaeum or Eyevea"
		},
		-- Sharp-As-Night
		[8] = {
			"+500:  Returning companion quests",
			"+125:  Returning Daily Boss quest offered by Ordinator Nelyn in Necrom [Daily]",
			"+125:  Completing an Ashlander daily quest offered by Huntmaster Sorim-Nakar or Numani-Rasi in Vvardenfell [Daily]",
			"+10:  Obtain monster trophy",
			"+10:  Visiting a Hist tree",
			"+10:  Talking to M'aiq the Liar",
			"+5:  Eat a meal [1 hour]",
			"+5:  Craft a poison",
			"+1/+5:  Find Treasure Map Chest",
			"+1/+5:  Find Heavy Sack",
			"+1/+5:  Catch a rare fish (green or better)",
			"+1:  Kill a Ghost [5 minutes]",
			"+1:  Kill a Fabricant or Dwarven Construct [5 minutes]",
			"+1:  Repair Gear (Can be done at a merchant as well as repair kit) [Daily]",
			"+1:  Recharge Weapon with Soul Gem",
			"+1:  Travel via Wayshrine",
			"+1:  Using soul gem to resurrect Sharp-as-Night",
			"+1:  Go fishing",
			"+1:  Harvest a material [1 hour]",
			"-?:  Let your gear break",
			"-1:  Change your outfit at an outfitting station",
			"-5:  Destroy Item in Inventory",
			"-5:  Pickpocket a beggar, laborer, or fisher",
			"-10:  Pay a Bounty to a guard"
		},
		-- Tanlorin
		[12] = {
			"+500:  Returning companion quests",
			"+125 Complete a Fighters Guild Daily Quest",
			"+125 Complete an Alchemy Crafting Writ Daily Quest",
			"+5 Craft any Furnishing item",
			"+5 Drink wine",
			"+5 Successfully lockpick any container",
			"+5 Use an Ayleid Well",
			"+5 Visit Alinor",
			"+5/+1 Harvest a flower",
			"+5 Use the Antiquarian’s Eye Tool at a dig site",
			"+5 Absorb a Skyshard",
			"+1 Learn a Furnishing Recipe",
			"+1 Craft a wine at a Provisioning Station",
			"+1 Mount an Indrik",
			"+1 Kill Daedra",
			"+1 Kill Maormer",
			"+1 Obtain a Verse in the Infinite Archive",
			"+1 Obtain a Scribing Script (+5?)",
			"-1 Enter a Mages Guildhall",
			"-1 Read a Mages Guild Lorebook",
			"-1 Harvest Nirnroot or Crimson Nirnroot",
			"-1 Kill an Indrik (including World Bosses?)",
			"-1 Kill a Gryphon (including World Bosses?)",
			"-5 Visit Eyevea",
			"-5 Visit Artaeum",
			"-10/-1 Murder civilians"
		},
		-- Zerith-var
		[13] = {
			"+500:  Returning companion quests",
			"+125 Complete a Northern Elsweyr Defence Force Daily Quest (Elsweyr Prologue in Grahtwood)",
			"+125 Complete a Tales of Tribute Daily Quest",
			"+10 Complete a Tales of Tribute match (doesn’t matter if you win or lose)",
			"+10 Consume a Purifying Bloody Mara",
			"+10 Heal yourself while in a critical state",
			"+10 Acquire the Werewolf Skill Line",
			"+10 Destroy a Dark Anchor",
			"+5 Defeat Tho’at Replicanum in the Infinite Archive",
			"+5 Visit the Baandari Trading Post in Malabal Tor",
			"+5 Harvest from a Water node",
			"+5 Loot a Heavy Sack",
			"+1 Kill a Vampire",
			"+1 Defeat a Cycle Boss in the Infinite Archive",
			"+1 Kill a Skeleton",
			"+1 Kill a dro-m’Athra",
			"-1 Fill a Soul Gem with Soul Trap or with the Oblivion’s Edge set",
			"-1 Murder civilians",
			"-1 Use the Blade of Woe on civilians",
			"-5 Sell or Launder stolen items",
			"-5 Get a bounty from using Necromancer ‘s Criminal Act skills",
			"-5 Consume a Corrupting Bloody Mara"
		}
		
		
		
		
	}
	local maxRapport = GetMaximumRapport()

	-- Modify companion information UI: Gamepad UI
	SecurePostHook(ZO_Tooltip, "LayoutCompanionOverview", function( self, companionData )
		-- What companion is active
		local activeCompanionID = GetActiveCompanionDefId()
		--local activeCompanionName = GetCompanionName(activeCompanionID)
		local activeCompanionName = zo_strformat(SI_COMPANION_NAME_FORMATTER, GetCompanionName(activeCompanionID))
		--activeCompanionName = string.gsub(activeCompanionName, "^f", "") --Remove Female/Male denominator
		--activeCompanionName = string.gsub(activeCompanionName, "^m", "")
		--activeCompanionName = string.sub(activeCompanionName, 0, string.len(activeCompanionName) - 2)
		
		-- Get companion rapport information
		local rapportLevel = GetActiveCompanionRapportLevel()
		local currentRapport = GetActiveCompanionRapport()
		local percentageRapport = zo_floor(currentRapport / maxRapport * 100)
		local rapportDescription2 = string.format("%d: %d / %d (%d%%)", rapportLevel, currentRapport, maxRapport, percentageRapport)

		-- Add New Section containing the companion rapport numbers
		local rapportStatusSection = self:AcquireSection(self:GetStyle("companionOverviewStatValueSection"))
		local rapportStatusPair = rapportStatusSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
		rapportStatusPair:SetStat("Rapport Level", self:GetStyle("statValuePairStat")) --GetString(SI_COMPANION_RAPPORT_STATUS)
		rapportStatusPair:SetValue(rapportDescription2, self:GetStyle("statValuePairValue"))
		rapportStatusSection:AddStatValuePair(rapportStatusPair)
		self:AddSection(rapportStatusSection)
		
		-- Add Additional Rapport Information
		local rapportBodySection2 = self:AcquireSection(self:GetStyle("companionOverviewBodySection"))
		--rapportBodySection2:AddLine(rapportDescription2, self:GetStyle("companionOverviewDescription"))
		rapportBodySection2:AddLine("Notable Rapport Stages", self:GetStyle("statValuePairStat"))
		--rapportBodySection2:AddLine("<= -4000: Disdainful", self:GetStyle("companionOverviewDescription"))
		--rapportBodySection2:AddLine("<= -2500: Irritated", self:GetStyle("companionOverviewDescription"))
		--rapportBodySection2:AddLine("<= 749: Wary", self:GetStyle("companionOverviewDescription"))
		--rapportBodySection2:AddLine(" 750: Cordial", self:GetStyle("companionOverviewDescription"))
		rapportBodySection2:AddLine("1000: Friendly (1st Personal Quest)", self:GetStyle("statValuePairValue"))
		rapportBodySection2:AddLine("2000: Close (2nd Personal Quest, Final quest for Mirri and Bastion)", self:GetStyle("statValuePairValue"))
		rapportBodySection2:AddLine("3000: Allied (3rd Personal Quest)", self:GetStyle("statValuePairValue"))
		rapportBodySection2:AddLine("4000: Companion", self:GetStyle("statValuePairValue"))

		-- Add Companion Specific Sources of Rapport
		rapportBodySection2:AddLine(zo_strformat("Sources of Rapport for "..activeCompanionName.." ["..activeCompanionID.."]"), self:GetStyle("statValuePairStat"))
		if companionInfo[activeCompanionID] then
			for idx, val in ipairs(companionInfo[activeCompanionID]) do
				if string.sub(val, 1, 1) == "-" then
					rapportBodySection2:AddLine(zo_strformat("|cFF6666"..val.."|r"), self:GetStyle("statValuePairValue"))
				else
					rapportBodySection2:AddLine(zo_strformat(val), self:GetStyle("statValuePairValue"))
				end
			end
		end
		self:AddSection(rapportBodySection2)
		
		-- Companion Rapport Levels
		-- -5000 to -4000: Disdainful - Companion feels nothing but contempt for you.
		-- -3999 to -2500: Irritated - Companion strongly dislikes you.
		-- -2499 to 749:   Wary - Companion tolerates you.
		--   750 to 999:   Cordial - Companion counts you as a friendly acquaintance.
		--  1000 to 1999:  Friendly - Companion respects you as an ally. (5% companion experience bonus) [1st quest]
		--  2000 to 2999:  Close - Companion greatly admires you (10% companion experience bonus) [2nd quest, last for Bastion & Mirri]
		--  3000 to 3999:  Allied - Companion holds you in high esteem. (15% companion experience bonus) [3rd quest, final]
		--  4000 to 5500:  Companion - Companion regards you as their greatest ally and dearest friend. (20% companion experience bonus)

	end)

	Set_Companion_Notifications()

end


-- UNDAUNTED PLEDGES


function KelaSetupCompanionInfo()
    Add_Enhanced_Companion_Information()
end
