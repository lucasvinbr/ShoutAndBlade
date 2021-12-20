Scriptname SAB_CommanderScript extends ReferenceAlias  

; a map of "unit index - amount" ints describing the units currently controlled by this commander
int jOwnedUnitsMap

; a map of "unit index - amount" ints describing the living units currently spawned by this commander
int jSpawnedUnitsMap

; a simple counter for spawned living units, just to not have to iterate through the jMaps
int spawnedUnitsAmount = 0

; a cached reference to the SAB spawner script so that we don't have to make lots of fetching whenever we want to spawn someone
SAB_FactionScript factionScript

int Property CmderFollowFactionRank Auto
{ the rank in the "cmderFollowerFaction" referring to this commander. Units in this rank should follow this cmder }

string Property CmderDestinationType Auto
{ can be "A", "B" or "C". Defines which of the 3 faction destinations this cmder will always go to }


Function Setup(SAB_FactionScript factionScriptRef)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	factionScript = factionScriptRef
	TryRecruitUnits()
	RegisterForSingleUpdateGameTime(0.25)
EndFunction

Event OnCellAttach()
	RegisterForUpdate(0.5)
EndEvent

Event OnCellDetach()
	UnregisterForUpdate()
EndEvent

Event OnUpdateGameTime()
	Actor meActor = GetReference() as Actor

	if !meActor.IsInCombat() && !meActor.IsBleedingOut()
		debug.Trace("game time updating commander!")
		TryRecruitUnits()
	endif
EndEvent

Event OnUpdate()
	if spawnedUnitsAmount < 20 ; TODO make this configurable
		; spawn random unit from "storage"
	endif
EndEvent

; if we don't have too many units already, attempts to get some more basic recruits with the faction gold
Function TryRecruitUnits()
	debug.Trace("commander: try recruit units!")
	int maxUnitSlots = 60 ; TODO make this configurable via MCM
	int curUnitCount = 0

	int curKey = jIntMap.nextKey(jOwnedUnitsMap, previousKey=0, endKey=0)
	while curKey != ""
		int unitCount = jIntMap.getInt(jOwnedUnitsMap, curKey)
		curUnitCount += unitCount
		curKey = jIntMap.nextKey(jOwnedUnitsMap, curKey, endKey=0)
	endwhile

	if curUnitCount < maxUnitSlots
		int recruitedUnits = factionScript.PurchaseRecruits(maxUnitSlots - curUnitCount)

		int unitIndex = jMap.getInt(factionScript.jFactionData, "RecruitUnitIndex")
		int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
		jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount + 1)
	endif
	
EndFunction

Function SpawnUnit(int unitIndex)
	ObjectReference spawnLocation = GetReference()

	if (spawnLocation as Actor).IsInCombat()
		spawnLocation = factionScript.UnitSpawnPoint.GetReference()
	endif

	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForCmder(self, unitIndex, spawnLocation)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		spawnedUnitsAmount += 1
	endif
EndFunction

; removes the despawned unit from the spawnedUnits list, but not from the ownedUnits, so that it can spawn again later
Function OwnedUnitHasDespawned(int unitIndex)
	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount - 1)

	spawnedUnitsAmount -= 1
EndFunction

; removes the dead unit from the ownedUnits and spawnedUnits lists
Function OwnedUnitHasDied(int unitIndex)
	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount - 1)

	spawnedUnitsAmount -= 1

	int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
	jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount - 1)

	if currentStoredAmount - 1 <= 0
		jIntMap.removeKey(jOwnedUnitsMap, unitIndex)

		; if we just lost our last unit and we were in bleedout, die right away
		Actor meActor = GetReference() as Actor
		if jValue.empty(jOwnedUnitsMap) && meActor.IsBleedingOut()
			meActor.KillEssential()
		endif
	endif
EndFunction

Event OnPackageEnd(Package akOldPackage)
	; TODO check if this is a reliable way to check if the cmder has reached their destination
	factionScript.CmderReachedDestination(self)
EndEvent

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
		; if the current spawn is too far away,
		; update the faction's unit spawn point to where this cmder started combat
		ObjectReference unitSpawn = factionScript.UnitSpawnPoint.GetReference()
		ObjectReference cmderRef = GetReference()
		if unitSpawn.GetDistance(cmderRef) > 25.0
			unitSpawn.MoveTo(cmderRef)
		endif
	endif
EndEvent

event OnDeath(Actor akKiller)	
	Clear()
endEvent

Event OnEnterBleedout()
	; if we don't have any stored units, die!
	if jValue.empty(jOwnedUnitsMap)
		(GetReference() as Actor).KillEssential()
	endif
EndEvent