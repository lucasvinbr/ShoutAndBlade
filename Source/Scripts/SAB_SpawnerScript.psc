Scriptname SAB_SpawnerScript extends Quest  

SAB_UnitDataHandler Property UnitDataHandler Auto

GlobalVariable Property SAB_UnitIndexBeingCustomized Auto

ActorBase Property CustomizationGuyBase Auto
{ The actor spawned for the player to customize the selected unit's gear }

Actor spawnedCustomizationGuy

Actor Function SpawnCustomizationGuy( int jUnitDataMap, int unitIndex )

	if spawnedCustomizationGuy != None
		spawnedCustomizationGuy.Disable()
		spawnedCustomizationGuy.Delete()
	endif

	spawnedCustomizationGuy = None

	Actor playr = Game.GetPlayer()
	spawnedCustomizationGuy = playr.PlaceActorAtMe(CustomizationGuyBase)
	;Debug.Notification("spawnedCustomizationGuy " + spawnedCustomizationGuy)
	CustomizeActorAccordingToData(spawnedCustomizationGuy, jUnitDataMap)
	SAB_UnitIndexBeingCustomized.SetValue(unitIndex as float)

	return spawnedCustomizationGuy
	
endFunction

;spawns a unit in the target location, customized according to the passed jMap 
Actor Function SpawnUnit( ObjectReference LocationRef, int jUnitDataMap, int unitIndex)
	
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