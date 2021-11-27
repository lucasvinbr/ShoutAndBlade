Scriptname SAB_SpawnerScript extends Quest  

SAB_UnitDataHandler Property UnitDataHandler Auto

GlobalVariable Property SAB_UnitIndexBeingCustomized Auto

ActorBase Property CustomizationGuyBase Auto
{ The actor spawned for the player to customize the selected unit's gear }

ReferenceAlias Property OutfitGuyAlias Auto
{ The storage handling script of the outfit customization actor }

Actor spawnedCustomizationGuy

Function HideCustomizationGuy()
	if spawnedCustomizationGuy != None
		OutfitGuyAlias.Clear()
		spawnedCustomizationGuy.Disable()
		spawnedCustomizationGuy.Delete()
	endif

	spawnedCustomizationGuy = None
EndFunction

Actor Function SpawnCustomizationGuy( int jUnitDataMap, int unitIndex )

	if spawnedCustomizationGuy != None
		OutfitGuyAlias.Clear()
		spawnedCustomizationGuy.Disable()
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
	(OutfitGuyAlias as SAB_OutfitGuyStorage).SetupStorage(UnitDataHandler.SAB_UnitGearSets.GetAt(unitIndex) as LeveledItem, jUnitDataMap)

	return spawnedCustomizationGuy
	
endFunction

;spawns a unit in the target location, customized according to the passed jMap 
Actor Function SpawnUnit( ObjectReference LocationRef, Faction ownerFaction, int jUnitDataMap, int unitIndex)
	
	if LocationRef == None
		return None
	endif

	if unitIndex == -1
		return None
	endif

	ActorBase unitActorBase = UnitDataHandler.SAB_UnitActorBases.GetAt(unitIndex) as ActorBase

	if unitActorBase == None
		return None
	endif

	Actor createdActor = LocationRef.PlaceActorAtMe(unitActorBase)
	CustomizeActorAccordingToData(createdActor, jUnitDataMap)
	createdActor.AddToFaction(ownerFaction)

	return createdActor
	
endFunction


;Sets actor values and actor name of the target actor based on the passed jMap's values
Function CustomizeActorAccordingToData(Actor targetActor, int jUnitData)

	targetActor.SetDisplayName(JMap.getStr(jUnitData, "Name", "Recruit"))

	targetActor.SetAV("Health", JMap.getFlt(jUnitData, "Health", 50.0))
	targetActor.SetAV("Magicka", JMap.getFlt(jUnitData, "Magicka", 50.0))
	targetActor.SetAV("Stamina", JMap.getFlt(jUnitData, "Stamina", 50.0))

	targetActor.SetAV("LightArmor", JMap.getFlt(jUnitData, "SkillLightArmor", 15.0))
	targetActor.SetAV("HeavyArmor", JMap.getFlt(jUnitData, "SkillHeavyArmor", 15.0))
	targetActor.SetAV("Block", JMap.getFlt(jUnitData, "SkillBlock", 15.0))
	targetActor.SetAV("OneHanded", JMap.getFlt(jUnitData, "SkillOneHanded", 15.0))
	targetActor.SetAV("TwoHanded", JMap.getFlt(jUnitData, "SkillTwoHanded", 15.0))
	targetActor.SetAV("Marksman", JMap.getFlt(jUnitData, "SkillMarksman", 15.0))

endFunction

;Sets actor values and actor name of the target actor based on the passed jMap's values
Function CustomizeActorAccordingToDataWithNameSuffix(Actor targetActor, int jUnitData, string nameSuffix)

	targetActor.SetDisplayName(JMap.getStr(jUnitData, "Name", "Recruit") + nameSuffix)

	targetActor.SetAV("Health", JMap.getFlt(jUnitData, "Health", 50.0))
	targetActor.SetAV("Magicka", JMap.getFlt(jUnitData, "Magicka", 50.0))
	targetActor.SetAV("Stamina", JMap.getFlt(jUnitData, "Stamina", 50.0))

	targetActor.SetAV("LightArmor", JMap.getFlt(jUnitData, "SkillLightArmor", 15.0))
	targetActor.SetAV("HeavyArmor", JMap.getFlt(jUnitData, "SkillHeavyArmor", 15.0))
	targetActor.SetAV("Block", JMap.getFlt(jUnitData, "SkillBlock", 15.0))
	targetActor.SetAV("OneHanded", JMap.getFlt(jUnitData, "SkillOneHanded", 15.0))
	targetActor.SetAV("TwoHanded", JMap.getFlt(jUnitData, "SkillTwoHanded", 15.0))
	targetActor.SetAV("Marksman", JMap.getFlt(jUnitData, "SkillMarksman", 15.0))

endFunction