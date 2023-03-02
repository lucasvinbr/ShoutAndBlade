Scriptname SAB_SpawnerScript extends Quest  

SAB_UnitDataHandler Property UnitDataHandler Auto

GlobalVariable Property SAB_UnitIndexBeingCustomized Auto

ActorBase Property CustomizationGuyBase Auto
{ The actor spawned for the player to customize the selected unit's gear }

ReferenceAlias Property OutfitGuyAlias Auto
{ The storage handling script of the outfit customization actor }

Faction Property SAB_CommanderRanksFaction Auto
{ Faction used for defining which commander the unit should follow }

Faction Property SAB_RangedUnitsFaction Auto
{ Faction all units considered "ranged" should belong to }

Actor spawnedCustomizationGuy

Function HideCustomizationGuy()
	if spawnedCustomizationGuy != None
		OutfitGuyAlias.Clear()
		spawnedCustomizationGuy.Delete()
	endif

	spawnedCustomizationGuy = None
EndFunction

Actor Function SpawnCustomizationGuy( int jUnitDataMap, int unitIndex )

	if spawnedCustomizationGuy != None
		OutfitGuyAlias.Clear()
		spawnedCustomizationGuy.Delete()
	endif

	spawnedCustomizationGuy = None

	Actor playr = Game.GetPlayer()
	; Debug.Trace("spawn customization guy for unit index " + unitIndex)
	; Debug.Trace("unit jMap: " + jUnitDataMap)
	spawnedCustomizationGuy = playr.PlaceActorAtMe(CustomizationGuyBase)
	; Debug.Trace("spawnedCustomizationGuy " + spawnedCustomizationGuy)
	CustomizeActorAccordingToDataWithNameSuffix(spawnedCustomizationGuy, jUnitDataMap, " (Outfitter)")
	SAB_UnitIndexBeingCustomized.SetValue(unitIndex as float)
	; teammates can wear stuff given by the player.
	; we need this to make the changes visible immediately instead of only when spawning the outfit guy again
	spawnedCustomizationGuy.SetPlayerTeammate(true, false)

	OutfitGuyAlias.ForceRefTo(spawnedCustomizationGuy)
	(OutfitGuyAlias as SAB_OutfitGuyStorage).SetupStorage \
		(UnitDataHandler.SAB_UnitGearSets.GetAt(unitIndex) as LeveledItem, \
		UnitDataHandler.SAB_UnitDuplicateItemSets.GetAt(unitIndex) as LeveledItem, \
		 jUnitDataMap)

	return spawnedCustomizationGuy
	
endFunction

; spawns a unit in the target location, customized according to the passed jMap (we fetch the map by unit index if it isn't passed) 
Actor Function SpawnUnit( ObjectReference LocationRef, Faction ownerFaction, int unitIndex, int jUnitDataMap = -1, int cmderFollowIndex = -1)
	
	; debug.StartStackProfiling()

	if LocationRef == None
		debug.Trace("spawn unit: location ref is null!")
		return None
	endif

	if unitIndex == -1
		debug.Trace("spawn unit: unit index is -1!")
		return None
	endif

	ActorBase unitActorBase = UnitDataHandler.SAB_UnitActorBases.GetAt(unitIndex) as ActorBase

	if unitActorBase == None
		debug.Trace("spawn unit: unit base at index "+ unitIndex +" is -1!")
		return None
	endif

	if jUnitDataMap == -1
		jUnitDataMap = jArray.getObj(UnitDataHandler.jSABUnitDatasArray, unitIndex)
	endif

	Actor createdActor = LocationRef.PlaceActorAtMe(unitActorBase)
	CustomizeActorAccordingToData(createdActor, jUnitDataMap)

	if ownerFaction
		createdActor.AddToFaction(ownerFaction)
		createdActor.SetCrimeFaction(ownerFaction)
	endif

	if cmderFollowIndex > -1
		createdActor.AddToFaction(SAB_CommanderRanksFaction)
		createdActor.SetFactionRank(SAB_CommanderRanksFaction, cmderFollowIndex)
	endif

	; debug.StopStackProfiling()

	return createdActor
	
endFunction


;Sets actor values and actor name of the target actor based on the passed jMap's values
Function CustomizeActorAccordingToData(Actor targetActor, int jUnitData)

	targetActor.SetDisplayName(JMap.getStr(jUnitData, "Name", "Recruit"))

	float healthMagickaMult = JDB.solveFlt(".ShoutAndBlade.generalOptions.healthMagickaMultiplier", 1.0)
	float skillMult = JDB.solveFlt(".ShoutAndBlade.generalOptions.skillsMultiplier", 1.0)

	targetActor.SetActorValue("Health", JMap.getFlt(jUnitData, "Health", 50.0) * healthMagickaMult)
	targetActor.SetActorValue("Magicka", JMap.getFlt(jUnitData, "Magicka", 50.0) * healthMagickaMult)
	targetActor.SetActorValue("Stamina", JMap.getFlt(jUnitData, "Stamina", 50.0) * healthMagickaMult)

	; Utility.Wait(0.01)

	targetActor.SetActorValue("LightArmor", JMap.getFlt(jUnitData, "SkillLightArmor", 15.0) * skillMult)
	targetActor.SetActorValue("HeavyArmor", JMap.getFlt(jUnitData, "SkillHeavyArmor", 15.0) * skillMult)
	targetActor.SetActorValue("Block", JMap.getFlt(jUnitData, "SkillBlock", 15.0) * skillMult)
	targetActor.SetActorValue("OneHanded", JMap.getFlt(jUnitData, "SkillOneHanded", 15.0) * skillMult)
	targetActor.SetActorValue("TwoHanded", JMap.getFlt(jUnitData, "SkillTwoHanded", 15.0) * skillMult)
	targetActor.SetActorValue("Marksman", JMap.getFlt(jUnitData, "SkillMarksman", 15.0) * skillMult)

	if jMap.getInt(jUnitData, "IsRanged", 0) != 0
		targetActor.AddToFaction(SAB_RangedUnitsFaction)
	endif

endFunction

;Sets actor values and actor name of the target actor based on the passed jMap's values
Function CustomizeActorAccordingToDataWithNameSuffix(Actor targetActor, int jUnitData, string nameSuffix)

	targetActor.SetDisplayName(JMap.getStr(jUnitData, "Name", "Recruit") + nameSuffix)

	float healthMagickaMult = JDB.solveFlt(".ShoutAndBlade.generalOptions.healthMagickaMultiplier", 1.0)
	float skillMult = JDB.solveFlt(".ShoutAndBlade.generalOptions.skillsMultiplier", 1.0)

	targetActor.SetActorValue("Health", JMap.getFlt(jUnitData, "Health", 50.0) * healthMagickaMult)
	targetActor.SetActorValue("Magicka", JMap.getFlt(jUnitData, "Magicka", 50.0) * healthMagickaMult)
	targetActor.SetActorValue("Stamina", JMap.getFlt(jUnitData, "Stamina", 50.0) * healthMagickaMult)

	targetActor.SetActorValue("LightArmor", JMap.getFlt(jUnitData, "SkillLightArmor", 15.0) * skillMult)
	targetActor.SetActorValue("HeavyArmor", JMap.getFlt(jUnitData, "SkillHeavyArmor", 15.0) * skillMult)
	targetActor.SetActorValue("Block", JMap.getFlt(jUnitData, "SkillBlock", 15.0) * skillMult)
	targetActor.SetActorValue("OneHanded", JMap.getFlt(jUnitData, "SkillOneHanded", 15.0) * skillMult)
	targetActor.SetActorValue("TwoHanded", JMap.getFlt(jUnitData, "SkillTwoHanded", 15.0) * skillMult)
	targetActor.SetActorValue("Marksman", JMap.getFlt(jUnitData, "SkillMarksman", 15.0) * skillMult)

	if jMap.getInt(jUnitData, "IsRanged", 0) != 0
		targetActor.AddToFaction(SAB_RangedUnitsFaction)
	endif

endFunction