Scriptname SAB_SpawnerScript extends Quest  

FormList Property SAB_UnitActorBases Auto
FormList Property SAB_UnitGearSets Auto
FormList Property SAB_UnitAllowedRacesGenders Auto

Actor Property CustomizationGuy Auto
{ The actor spawned for the player to customize the selected unit's gear }

Actor Function SpawnCustomizationGuy( int jUnitDataMap )
	
	Actor playr = Game.GetPlayer()
	CustomizationGuy.Reset(playr)
	CustomizationGuy.Enable(true)
	CustomizeActorAccordingToData(CustomizationGuy, jUnitDataMap)

	return CustomizationGuy
	
endFunction

;spawns a unit in the target location, customized according to the passed jMap 
Actor Function SpawnUnit( ObjectReference LocationRef, int jUnitDataMap )
	
	if LocationRef == None
		return None
	endif

	int unitIndex = JMap.getInt(jUnitDataMap, "UnitIndex", -1)

	if unitIndex == -1
		return None
	endif

	ActorBase unitActorBase = SAB_UnitActorBases.GetAt(unitIndex) as ActorBase

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