scriptname SAB_LocationDataHandler extends Quest
{script for setting up and getting data for locations used by the mod.}

SAB_LocationScript[] Property Locations Auto Hidden
{ all locations useable by the mod, enabled and disabled. }

SAB_LocationScript[] Property EnabledLocations Auto Hidden
{ locations that are currently being used by the mod. Factions will browse this list when thinking about where to go }

SAB_FactionDataHandler Property FactionDataHandler Auto

bool initialSetupDone = false
bool isBusyUpdatingLocationData = false
bool isBusyAddingNewLocsToBaseArray = false

bool shouldRecalculateDistances = false
bool shouldRebuildEnabledLocations = false

int Property NextLocationIndex = 0 Auto Hidden
int Property NextEnabledLocationIndex = 0 Auto Hidden

; a jMap, mapped by location name, containing jMaps with some configurable data on locations
int Property jLocationsConfigMap Auto Hidden

Function Initialize()
    Locations = new SAB_LocationScript[128]
    EnabledLocations = new SAB_LocationScript[128]

    jLocationsConfigMap = jMap.object()
    JValue.retain(jLocationsConfigMap, "ShoutAndBlade")

    initialSetupDone = true
EndFunction


bool Function IsDoneSettingUp()
    return initialSetupDone
EndFunction


event OnInit()
    CalculateLocationDistances()
endevent


Function AddNewLocationsFromAddon(SAB_LocationDataAddon addon)

    if NextLocationIndex >= 128
        Debug.Trace("AddNewLocationsFromAddon: SAB Locations array is full! Aborting")
        return
    endif

    while isBusyAddingNewLocsToBaseArray
        Debug.Trace("SAB queued new addon location registration is waiting")
        Utility.Wait(0.1)
    endwhile

    isBusyAddingNewLocsToBaseArray = true

    SAB_LocationScript[] newLocations = addon.NewLocations
    int i = 0

    ; set up locations
    while i != -1 && i < newLocations.Length
        if newLocations[i]
            Locations[NextLocationIndex] = newLocations[i]
            
            i += 1
            NextLocationIndex += 1

            if NextLocationIndex >= 128
                ; break! the locations array is full
                i = -1
            endif
        endif
    endwhile

    isBusyAddingNewLocsToBaseArray = false

    RebuildEnabledLocationsArray()
    CalculateLocationDistances()
    
EndFunction

; enables or disables the target location
Function SetLocationEnabled(SAB_LocationScript locScript, bool enable)

    while isBusyUpdatingLocationData
        Debug.Trace("SAB queued location enable is waiting")
        Utility.Wait(0.1)
    endwhile

    int jLocDataMap = jMap.getObj(jLocationsConfigMap, locScript.ThisLocation.GetFormID())
    int locationOwnerFacIndex = -1

    if jLocDataMap != 0
        locationOwnerFacIndex = jMap.getInt(jLocDataMap, "OwnerFactionIndex", -1)
    endif

    SAB_FactionScript ownerFactionScript = None

    if locationOwnerFacIndex > -1 && locationOwnerFacIndex < FactionDataHandler.SAB_FactionQuests.Length 
        ownerFactionScript = FactionDataHandler.SAB_FactionQuests[locationOwnerFacIndex]
    endif

    if enable
        if !locScript.isEnabled
            locScript.Setup(ownerFactionScript)
        endif
    else
        if locScript.isEnabled
            locScript.DisableLocation()
        endif
    endif

    RebuildEnabledLocationsArray()
    CalculateLocationDistances()
    
EndFunction


Function RebuildEnabledLocationsArray()

    if isBusyUpdatingLocationData
        if !shouldRebuildEnabledLocations
            Debug.Trace("SAB: rebuild enabled locations is  now scheduled")
        endif
        
        shouldRebuildEnabledLocations = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRebuildEnabledLocations = false

    Debug.Trace("SAB: rebuild enabled locations - start")

    int i = 0
    NextEnabledLocationIndex = 0

    while i != -1 && i < NextLocationIndex
        if Locations[i]
            if Locations[i].isEnabled
                EnabledLocations[NextEnabledLocationIndex] = Locations[i]
                NextEnabledLocationIndex += 1
            endif
        endif

        i += 1
    endwhile

    ; clear other enabled location entries
    i = 128 - NextEnabledLocationIndex

    while 128 - i < 128
        EnabledLocations[128 - i] = None
        i -= 1
    endwhile

    Debug.Trace("SAB: rebuild enabled locations - end")

    isBusyUpdatingLocationData = false
    OnDoneUpdatingLocationData()

EndFunction


; updates each enabled location's cached references to their closest enabled locations.
; should be run again whenever a location is added/removed, to make sure the faction AIs know where it's better to go
Function CalculateLocationDistances()

    if isBusyUpdatingLocationData
        ; schedule a recalculation once the current updates are done
        if !shouldRebuildEnabledLocations
            Debug.Trace("SAB: recalculate location distances is now scheduled")
        endif
        
        shouldRecalculateDistances = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRecalculateDistances = false

    Debug.Trace("SAB: recalculate location distances - start")

    int i = 0
    int j = 0
    int k = 0
    bool hasCreatedDistArrayEntry = false

    int jlocationDistancesMap = jIntMap.object()
    JValue.retain(jlocationDistancesMap, "ShoutAndBlade")

    ; fill the distances map with distances between each location
    while i < NextEnabledLocationIndex
        
        ; debug.Trace(EnabledLocations[i])
        
        ObjectReference baseRef = EnabledLocations[i].GetReference()
        ; debug.Trace(baseRef)

        while !baseRef
            Utility.Wait(0.15)
            baseRef = EnabledLocations[i].GetReference()
            ; debug.Trace(baseRef)
        endwhile
        
        baseRef = EnabledLocations[i].GetDistanceCheckReference()

        int jDistMapsFromI = jIntMap.object()
        JIntMap.setObj(jlocationDistancesMap, i, jDistMapsFromI)

        ; also prepare the "top 3 closest to cur loc" jArray
        int jDistancesArray = jArray.object()
        JValue.retain(jDistancesArray, "ShoutAndBlade")

        int jClosestIndexesArray = jArray.object()
        JValue.retain(jClosestIndexesArray, "ShoutAndBlade")
        
        j = 0
        while j < NextEnabledLocationIndex
            if i != j
                ; check if we haven't already checked the distance between j and i
                int jDistMapsFromJ = JIntMap.getObj(jlocationDistancesMap, j)
                float distance = 0.0

                if jDistMapsFromJ != 0
                    distance = JIntMap.getFlt(jDistMapsFromJ, i)
                endif

                if distance == 0.0
                    distance = baseRef.GetDistance(EnabledLocations[j].GetDistanceCheckReference())
                endif

                ; add distance and loc index to the sorted distances arrays
                hasCreatedDistArrayEntry = false
                k = jValue.count(jDistancesArray) - 1
                while k >= 0
                    ; keep going until we find a stored distance that is smaller.
                    ; if we find it, store the new distance right after it
                    if jArray.getFlt(jDistancesArray, k) < distance
                        JArray.addFlt(jDistancesArray, distance, k + 1)
                        JArray.addInt(jClosestIndexesArray, j, k + 1)
                        hasCreatedDistArrayEntry = true
                        ; break
                        k = -1
                    endif
                    k -= 1
                endwhile

                ; if we couldn't find a smaller distance than the new one, it's the new smallest one!
                if !hasCreatedDistArrayEntry
                    JArray.addFlt(jDistancesArray, distance, 0)
                    JArray.addInt(jClosestIndexesArray, j, 0)
                endif
                

                JIntMap.setFlt(jDistMapsFromI, j, distance)
            endif
            j += 1
            ;Utility.Wait(0.1)
        endwhile

        ; store the (limited to 3 elements) closest locations array in the location script
        int jTopClosestLocationsArray = jArray.subArray(jClosestIndexesArray, 0, 3)
        jValue.retain(jTopClosestLocationsArray, "ShoutAndBlade")
        EnabledLocations[i].jNearbyLocationsArray = jTopClosestLocationsArray

        jValue.release(jDistancesArray)
        jValue.zeroLifetime(jDistancesArray)

        jValue.release(jClosestIndexesArray)
        jValue.zeroLifetime(jClosestIndexesArray)

        i += 1
        ;Utility.Wait(0.1)
    endwhile

    jValue.release(jlocationDistancesMap)
    jValue.zeroLifetime(jlocationDistancesMap)

    Debug.Trace("SAB: recalculate location distances - end")

    isBusyUpdatingLocationData = false

    OnDoneUpdatingLocationData()

EndFunction

; checks if other update data requests were sent during this update and starts updating again if so
Function OnDoneUpdatingLocationData()
    if shouldRebuildEnabledLocations
        RebuildEnabledLocationsArray()
    endif

    if shouldRecalculateDistances
        CalculateLocationDistances()
    endif
EndFunction


; for each location, attempts to set up the configurable parts of their data using the data stored in jLocationsConfigMap
Function UpdateLocationsAccordingToJMap()
    int i = jMap.count(jLocationsConfigMap)
    bool hasChangedEnabledLocations = false

    While (i > 0)
        i -= 1
        
        string locId = jMap.getNthKey(jLocationsConfigMap, i)

        SAB_LocationScript locScript = GetLocationById(locId)

        if locScript != None
            int jLocDataMap = jMap.getObj(jLocationsConfigMap, locId)

            if jLocDataMap != 0
                bool enableLoc = jMap.getInt(jLocDataMap, "IsEnabled", 1) != 0

                if locScript.isEnabled != enableLoc
                    hasChangedEnabledLocations = true
                    SetLocationEnabled(locScript, enableLoc)
                endif

                if enableLoc
                    int ownerFacIndex = jMap.getInt(jLocDataMap, "OwnerFactionIndex", -1)

                    if ownerFacIndex > -1 
                        if ownerFacIndex < FactionDataHandler.SAB_FactionQuests.Length
                            if locScript.factionScript != FactionDataHandler.SAB_FactionQuests[ownerFacIndex]
                                locScript.BeTakenByFaction(FactionDataHandler.SAB_FactionQuests[ownerFacIndex], true)

                                locScript.SetOwnedUnits(jMap.getObj(jLocDataMap, "jStartingGarrison"))
                            endif
                        endif
                    else 
                        if locScript.factionScript != None
                            locScript.BecomeNeutral(true)
                        endif
                    endif
                endif

                locScript.GoldRewardMultiplier = jMap.getFlt(jLocDataMap, "GoldRewardMultiplier", 1.0)
                locScript.GarrisonSizeMultiplier = jMap.getFlt(jLocDataMap, "GarrisonSizeMultiplier", 1.0)
                locScript.OverrideDisplayName = jMap.getStr(jLocDataMap, "OverrideDisplayName")

            endif
        endif
        
    EndWhile

    if hasChangedEnabledLocations
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
    endif
EndFunction


Function WriteCurrentLocOwnershipsToJmap()
    
    int i = 0

    while i < NextLocationIndex
        int jLocDataMap = JMap.getObj(jLocationsConfigMap, Locations[i].GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsConfigMap, Locations[i].GetLocId(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", FactionDataHandler.GetFactionIndex(Locations[i].factionScript))

        i += 1
    endwhile

EndFunction

Function WriteCurrentLocNamesToJmap()
    
    int i = 0

    while i < NextLocationIndex
        int jLocDataMap = JMap.getObj(jLocationsConfigMap, Locations[i].GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsConfigMap, Locations[i].GetLocId(), jLocDataMap)
        endif

        jMap.setStr(jLocDataMap, "OverrideDisplayName", Locations[i].GetLocName())

        i += 1
    endwhile

EndFunction

Function WriteCurrentLocStartGarrsToJmap()
    
    int i = 0

    while i < NextLocationIndex
        int jLocDataMap = JMap.getObj(jLocationsConfigMap, Locations[i].GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsConfigMap, Locations[i].GetLocId(), jLocDataMap)
        endif

        jMap.setObj(jLocDataMap, "jStartingGarrison", Locations[i].jStartingUnitsMap)

        i += 1
    endwhile

EndFunction

; creates a string array with location IDs accompanied by their names
string[] Function CreateStringArrayWithLocationIdentifiers()

    string[] namesArray = Utility.CreateStringArray(NextLocationIndex)
    int endingIndex = NextLocationIndex

    int i = 0

    while(i < endingIndex)

        string locName = Locations[i].GetLocName()

        namesArray[i] = ((i + 1) as string) + " - " + locName

        i += 1
    endwhile

    return namesArray
EndFunction

; creates a string array with only enabled location IDs accompanied by their names
string[] Function CreateStringArrayWithEnabledLocationIdentifiers()

    string[] namesArray = Utility.CreateStringArray(NextEnabledLocationIndex)
    int endingIndex = NextEnabledLocationIndex

    int i = 0

    while(i < endingIndex)

        string locName = EnabledLocations[i].GetLocName()

        namesArray[i] = ((i + 1) as string) + " - " + locName

        i += 1
    endwhile

    return namesArray
EndFunction


int Function GetEnabledLocationIndex(SAB_LocationScript locScript)
    int i = 0

    while i < NextEnabledLocationIndex
        if EnabledLocations[i] == locScript
            return i
        endif
        i += 1
    endwhile

    return -1
EndFunction

; returns a jArray with the indexes of the locations that have the target faction as owner
int Function GetLocationIndexesOwnedByFaction(SAB_FactionScript factionScript)
    int i = 0
    int jReturnedArray = jArray.object()

    while i < NextLocationIndex
        if Locations[i].factionScript == factionScript
            JArray.addInt(jReturnedArray, i)
        endif
        i += 1
    endwhile

    return jReturnedArray
EndFunction


; returns a random location from the enabled locations list
SAB_LocationScript Function GetRandomLocation()
    return EnabledLocations[Utility.RandomInt(0, NextEnabledLocationIndex - 1)]
endfunction


SAB_LocationScript Function GetLocationByName(string name)
    int i = 0

    while i < NextLocationIndex
        if Locations[i].GetLocName() == name
            return Locations[i]
        endif
        i += 1
    endwhile

    return None
EndFunction

SAB_LocationScript Function GetLocationById(string Id)
    int i = 0

    while i < NextLocationIndex
        if Locations[i].GetLocId() == Id
            return Locations[i]
        endif
        i += 1
    endwhile

    return None
EndFunction


; locationData jmap entries:

; int IsEnabled - 0 = disabled, anything else = enabled
; string OverrideDisplayName
; float GarrisonSizeMultiplier
; float GoldRewardMultiplier
; int OwnerFactionIndex - -1 for neutral

; a intMap. The keys for each entry are unit indexes
; int jStartingGarrison