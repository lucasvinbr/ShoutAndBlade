scriptname SAB_LocationDataHandler extends Quest
{script for setting up and getting data for locations used by the mod.}

SAB_AliasUpdater Property Locations Auto
{ all locations useable by the mod, enabled and disabled. }

SAB_AliasUpdater Property EnabledLocations Auto
{ locations that are currently being used by the mod. Factions will browse this list when thinking about where to go }

FormList Property SAB_ObjectsToUseAsSpawnsList Auto
{ (Auto-fill) Formlist with objects like xmarkers, that should generally serve as "good enough" spawn points }

SAB_FactionDataHandler Property FactionDataHandler Auto

Keyword Property SAB_PlaceholderLocationKeyword Auto
{ keyword used for marking the placeholder SAB locations, which should be replaced by valid ingame locations }

bool initialSetupDone = false
bool isBusyUpdatingLocationData = false
bool isBusyAddingNewLocsToBaseArray = false
bool isBusySortingLocNames = false

bool shouldReSortLocNames = false
bool shouldRecalculateDistances = false
bool shouldRebuildEnabledLocations = false
bool isReaddingAllLocations = false

int Property NextLocationIndex = 0 Auto Hidden
int Property NextEnabledLocationIndex = 0 Auto Hidden

; a jMap, mapped by location name, containing jMaps with some configurable data on locations
int Property jLocationsConfigMap Auto Hidden

; the cell in which all markers are in, before we start moving them
Cell Property MarkersHolderCell auto

; a jArray with objects with loc names and their indexes in the locations array
int jLocationsSortedByNameArr

; a jArray with objects with loc names and their indexes in the enabled locations array
int jEnabledLocationsSortedByNameArr

; a jArray of forms (quests), that we should cast to SAB_LocationDataAddon
int jregisteredAddonsArray

Function Initialize()
    Locations.Initialize(false)
    EnabledLocations.Initialize(false)

    jLocationsConfigMap = jMap.object()
    JValue.retain(jLocationsConfigMap, "ShoutAndBlade")

    jregisteredAddonsArray = jArray.object()
    JValue.retain(jregisteredAddonsArray, "ShoutAndBlade")

    jLocationsSortedByNameArr = jArray.object()
    JValue.retain(jLocationsSortedByNameArr, "ShoutAndBlade")

    jEnabledLocationsSortedByNameArr = jArray.object()
    JValue.retain(jEnabledLocationsSortedByNameArr, "ShoutAndBlade")

    JDB.solveFormSetter(".ShoutAndBlade_global.locDataHandler", self, true)

    initialSetupDone = true

    CalculateLocationDistances()
EndFunction

SAB_LocationDataHandler function GetFromJdb() global
	return JDB.solveForm(".ShoutAndBlade_global.locDataHandler") as SAB_LocationDataHandler
endfunction

bool Function IsDoneSettingUp()
    return initialSetupDone
EndFunction


Function AddNewLocationsFromAddon(SAB_LocationDataAddon addon, int addonIndex)

    if addonIndex < 0
        ; register addon in an array
        int indexForAddon = GetNextIndexForLocationAddon()

        jArray.setForm(jregisteredAddonsArray, indexForAddon, addon)

        addon.SetIndexInRegisteredAddons(indexForAddon)
    endif

    while isBusyAddingNewLocsToBaseArray
        Debug.Trace("[SAB]  queued new addon location registration is waiting")
        Utility.Wait(1.5)
    endwhile

    isBusyAddingNewLocsToBaseArray = true

    SAB_LocationScript[] newLocations = addon.NewLocations
    int i = 0
    bool hasMadeChanges = false
    SAB_LocationScript newLoc = None

    ; set up locations
    while i != -1 && i < newLocations.Length
        newLoc = newLocations[i]
        if newLoc != None
            If GetLocationIndexById(newLoc.GetLocId()) == -1
                int locIndex = Locations.RegisterAliasForUpdates(newLoc)
                int jlocNameEntry = jMap.object()
                jMap.setStr(jlocNameEntry, "locName", newLoc.GetLocName())
                jMap.setInt(jlocNameEntry, "locIndex", locIndex)
                jArray.addObj(jLocationsSortedByNameArr, jlocNameEntry)
                hasMadeChanges = true
                NextLocationIndex = Locations.GetTopIndex() + 1

                ; enable this loc if it starts enabled.
                ; editable locs always start disabled!
                SetLocationEnabled(newLoc, newLoc.startsEnabled && !newLoc.isChangeable, false)

                debug.Trace("SAB: added new location " + newLoc.GetLocName())
            EndIf

            i += 1
        else
            debug.Trace("SAB: addon " + addon + " has a none loc script in its list?!")
        endif
    endwhile
    
    debug.Notification("SAB: added new location(s) from " + addon.GetName())
    isBusyAddingNewLocsToBaseArray = false

    If hasMadeChanges
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
        RebuildSortedLocNamesArrays()
    EndIf
    
EndFunction

; enables or disables the target location
Function SetLocationEnabled(SAB_LocationScript locScript, bool enable, bool runDistanceRebuilds = true)

    if enable == locScript.isCurrentlyEnabled
        ; no action to be made!
        return
    endif

    while isBusyUpdatingLocationData
        Debug.Trace("[SAB] queued location enable/disable is waiting")
        Utility.Wait(0.1)
    endwhile

    int jLocDataMap = jMap.getObj(jLocationsConfigMap, locScript.GetLocId())
    int locationOwnerFacIndex = -1

    if jLocDataMap != 0
        locationOwnerFacIndex = jMap.getInt(jLocDataMap, "OwnerFactionIndex", -1)
    endif

    SAB_FactionScript ownerFactionScript = None

    if locationOwnerFacIndex > -1 && locationOwnerFacIndex < FactionDataHandler.SAB_FactionQuests.Length 
        ownerFactionScript = FactionDataHandler.SAB_FactionQuests[locationOwnerFacIndex]
    endif

    if enable
        if !locScript.isCurrentlyEnabled
            locScript.Setup(ownerFactionScript)
        endif
    else
        if locScript.isCurrentlyEnabled
            locScript.DisableLocation()
        endif
    endif

    if runDistanceRebuilds
        ; this is suboptimal, I think... we shouldn't have to rebuild if we're just adding an enabled loc
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
        RebuildSortedLocNamesArrays()
    endif
    
EndFunction


Function RebuildEnabledLocationsArray()

    if isBusyUpdatingLocationData
        if !shouldRebuildEnabledLocations
            Debug.Trace("[SAB] rebuild enabled locations is  now scheduled")
        endif
        
        shouldRebuildEnabledLocations = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRebuildEnabledLocations = false

    Debug.Trace("[SAB] rebuild enabled locations - start")
    debug.Notification("[SAB] rebuild enabled locations - start")

    int i = 0
    NextEnabledLocationIndex = 0
    EnabledLocations.UnregisterAllAliases()
    jArray.clear(jEnabledLocationsSortedByNameArr)

    while i != -1 && i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            if locScript.isCurrentlyEnabled
                int locIndex = EnabledLocations.RegisterAliasForUpdates(locScript)
                
                int jlocNameEntry = jMap.object()
                jMap.setStr(jlocNameEntry, "locName", locScript.GetLocName())
                jMap.setInt(jlocNameEntry, "locIndex", locIndex)
                jArray.addObj(jEnabledLocationsSortedByNameArr, jlocNameEntry)
            endif
        endif

        i += 1
    endwhile

    NextEnabledLocationIndex = EnabledLocations.GetTopIndex()

    Debug.Trace("[SAB] rebuild enabled locations - end")
    debug.Notification("[SAB] rebuild enabled locations - end")

    isBusyUpdatingLocationData = false

    OnDoneUpdatingLocationData()

EndFunction

function RebuildSortedLocNamesArrays()

    if isBusyUpdatingLocationData
        if !shouldReSortLocNames
            Debug.Trace("[SAB] rebuild sorted loc names is now scheduled")
        endif
        
        shouldReSortLocNames = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldReSortLocNames = false

    Debug.Trace("[SAB] rebuild sorted loc names - start")
    debug.Notification("[SAB] rebuild sorted loc names - start")

    int i = 0
    jArray.clear(jLocationsSortedByNameArr)
    jArray.clear(jEnabledLocationsSortedByNameArr)

    while i != -1 && i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            int jlocNameEntry = jMap.object()
            jMap.setStr(jlocNameEntry, "locName", locScript.GetLocName())
            jMap.setInt(jlocNameEntry, "locIndex", i)
            jArray.addObj(jLocationsSortedByNameArr, jlocNameEntry)

            if locScript.isCurrentlyEnabled
                int locIndexInEnableds = GetEnabledLocationIndex(locScript)

                int jlocNameEntry = jMap.object()
                jMap.setStr(jlocNameEntry, "locName", locScript.GetLocName())
                jMap.setInt(jlocNameEntry, "locIndex", locIndexInEnableds)
                jArray.addObj(jEnabledLocationsSortedByNameArr, jlocNameEntry)
            endif
        endif

        i += 1
    endwhile

    ; finally sort loc names array
    SortLocsNamesList(jLocationsSortedByNameArr)
    SortLocsNamesList(jEnabledLocationsSortedByNameArr)

    Debug.Trace("[SAB] rebuild sorted loc names - end")
    debug.Notification("[SAB] rebuild sorted loc names - end")

    isBusyUpdatingLocationData = false
    OnDoneUpdatingLocationData()

endfunction

function SortLocsNamesList(int jLocsArr)
    ; an attempt at copying comb sort from wikipedia
    int arrSize = jArray.count(jLocsArr)
    int gap = arrSize
    float shrinkFactor = 1.3
    bool sorted = false
    int i = 0
    int elX = 0
    int elY = 0
    string fallbackStr = "???"
    string elXName = ""
    string elYName = ""
    int elXValue = 0
    int elYValue = 0

    while !sorted
        gap = Math.Floor(gap / shrinkFactor)
        if gap <= 1
            gap = 1
            sorted = true ; we set this back to false if we find a required swap in this iteration
        elseif gap == 9 || gap == 10
            gap = 11 ; "rule of 11", said to mitigate "turtle" issues, where an element is at the opposite of where it should be
        endif

        ; comb iteration!
        i = 0
        while i + gap < arrSize
            elX = jArray.GetObj(jLocsArr, i)
            elY = jArray.GetObj(jLocsArr, i + gap)
            elXName = jMap.GetStr(elX, "locName", fallbackStr)
            elYName = jMap.GetStr(elY, "locName", fallbackStr)
            ; this only gets the value of the first letter of the name, sadly
            elXValue = StringUtil.AsOrd(elXName)
            elYValue = StringUtil.AsOrd(elYName)

            if elXValue > elYValue
                jArray.swapItems(jLocsArr, i, i + gap)
                sorted = false ; if this never happens, it's sorted!
            elseif elXValue == elYValue
                ; ok, first letter is the same, what now?
                ; if this is a big enough name, let's get letter in index 5,
                ; so that we can sort the "fort X" locs a bit
                if StringUtil.GetLength(elXName) > 5 && StringUtil.GetLength(elYName > 5)
                    elXValue = StringUtil.AsOrd(StringUtil.GetNthChar(elXName, 5))
                    elYValue = StringUtil.AsOrd(StringUtil.GetNthChar(elYName, 5))

                    if elXValue > elYValue
                        jArray.swapItems(jLocsArr, i, i + gap)
                        sorted = false
                    endif
                endif
            endif

            i += 1
        endwhile
    endwhile
endfunction

; updates each enabled location's cached references to their closest enabled locations.
; should be run again whenever a location is added/removed, to make sure the faction AIs know where it's better to go
Function CalculateLocationDistances()

    if isBusyUpdatingLocationData
        ; schedule a recalculation once the current updates are done
        if !shouldRebuildEnabledLocations
            Debug.Trace("[SAB] recalculate location distances is now scheduled")
        endif
        
        shouldRecalculateDistances = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRecalculateDistances = false

    Debug.Trace("[SAB] recalculate location distances - start")
    debug.Notification("[SAB] recalculate location distances - start")

    int i = 0
    int j = 0
    int k = 0
    bool hasCreatedDistArrayEntry = false
    ObjectReference baseRef = None
    SAB_LocationScript locScript = None

    int jLocationPositionsArr = jArray.objectWithSize(NextEnabledLocationIndex)
    JValue.retain(jLocationPositionsArr, "ShoutAndBlade")

    ; fill the positions arr with the position of each location's distance check ref
    while i < NextEnabledLocationIndex
        locScript = EnabledLocations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            baseRef = locScript.GetReference()
    
            while !baseRef
                ; during the new game initialization, some aliases may take longer to be properly filled
                Utility.Wait(0.15)
                baseRef = locScript.GetReference()
                ; debug.Trace(baseRef)
            endwhile

            baseRef = locScript.GetDistanceCheckReference()
            ; use an array, because, according to the jcontainers wiki, it's faster than a map,
            ; and we know which value goes where
            int jPosInfoArr = jArray.objectWithSize(2)
            jArray.setFlt(jPosInfoArr, 0, baseRef.GetPositionX())
            jArray.setFlt(jPosInfoArr, 1, baseRef.GetPositionY())

            jArray.setObj(jLocationPositionsArr, i, jPosInfoArr)
        endif

        i += 1
    endwhile

    int jlocationDistancesArr = jArray.objectWithSize(NextEnabledLocationIndex)
    JValue.retain(jlocationDistancesArr, "ShoutAndBlade")

    int jThisLocPosArr = 0
    int jThatLocPosArr = 0
    int jDistancesFromThisLoc = 0
    int jDistancesFromJ = 0

    int jBestDistancesArray = 0
    int jClosestIndexesArray = 0

    float locsDist = 0.0

    ; fill the distances map with distances between each location
    i = 0
    while i < NextEnabledLocationIndex
        
        ; debug.Trace(EnabledLocations[i])
        locScript = EnabledLocations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            jThisLocPosArr = jArray.getObj(jLocationPositionsArr, i)

            if jThisLocPosArr != 0
                jDistancesFromThisLoc = jArray.objectWithSize(NextEnabledLocationIndex)
                jArray.setObj(jlocationDistancesArr, i, jDistancesFromThisLoc)

                ; also prepare the "top 3 closest to cur loc" jArrays
                jBestDistancesArray = jArray.object()
                JValue.retain(jBestDistancesArray, "ShoutAndBlade")
        
                jClosestIndexesArray = jArray.object()
                JValue.retain(jClosestIndexesArray, "ShoutAndBlade")

                j = 0
                while j < NextEnabledLocationIndex
                    if i != j
                        ; check if we haven't already checked the distance between j and i
                        jDistancesFromJ = jArray.getObj(jlocationDistancesArr, j)
                        locsDist = 0.0
        
                        if jDistancesFromJ != 0
                            locsDist = jArray.getFlt(jDistancesFromJ, i)
                        endif
        
                        if locsDist == 0.0
                            ; calc distance between loc positions...
                            ; we'll try to use a (probably) cheap x dist + y dist check
                            jThatLocPosArr = jArray.getObj(jLocationPositionsArr, j)
                            if jThatLocPosArr != 0
                                locsDist = Math.abs(jArray.getFlt(jThisLocPosArr, 0) - jArray.getFlt(jThatLocPosArr, 0)) + Math.abs(jArray.getFlt(jThisLocPosArr, 1) - jArray.getFlt(jThatLocPosArr, 1))
                            endif
                        endif
        
                        if locsDist != 0.0
                            ; add distance and loc index to the sorted distances arrays
                            hasCreatedDistArrayEntry = false
                            k = jValue.count(jBestDistancesArray) - 1
                            while k >= 0
                                ; keep going until we find a stored distance that is smaller.
                                ; if we find it, store the new distance right after it
                                if jArray.getFlt(jBestDistancesArray, k) < locsDist
                                    JArray.addFlt(jBestDistancesArray, locsDist, k + 1)
                                    JArray.addInt(jClosestIndexesArray, j, k + 1)
                                    hasCreatedDistArrayEntry = true
                                    ; break
                                    k = -1
                                endif
                                k -= 1
                            endwhile

                            ; if we couldn't find a smaller distance than the new one, it's the new smallest one!
                            if !hasCreatedDistArrayEntry
                                JArray.addFlt(jBestDistancesArray, locsDist, 0)
                                JArray.addInt(jClosestIndexesArray, j, 0)
                            endif


                            jArray.setFlt(jDistancesFromThisLoc, j, locsDist)
                        endif
                        
                    endif
                    j += 1
                    ;Utility.Wait(0.1)
                endwhile

                ; store the (limited to 3 elements) closest locations array in the location script
                locScript.jNearbyLocationsArray = jValue.releaseAndRetain(locScript.jNearbyLocationsArray, jArray.subArray(jClosestIndexesArray, 0, 3), "ShoutAndBlade")
        
                jValue.release(jBestDistancesArray)
                jValue.zeroLifetime(jBestDistancesArray)
        
                jValue.release(jClosestIndexesArray)
                jValue.zeroLifetime(jClosestIndexesArray)
            endif
        
        endif
        i += 1
        ;Utility.Wait(0.1)
    endwhile

    jValue.release(jlocationDistancesArr)
    jValue.zeroLifetime(jlocationDistancesArr)

    jValue.release(jLocationPositionsArr)
    jValue.zeroLifetime(jLocationPositionsArr)

    Debug.Trace("[SAB] recalculate location distances - end")
    debug.Notification("[SAB] recalculate location distances - end")

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

    if shouldReSortLocNames
        RebuildSortedLocNamesArrays()
    endif
EndFunction


; for each location, attempts to set up the configurable parts of their data using the data stored in jLocationsConfigMap
Function UpdateLocationsAccordingToJMap()
    int i = jMap.count(jLocationsConfigMap)
    bool hasChangedEnabledLocations = false
    int jLocDataMap = 0

    While (i > 0)
        i -= 1
        
        string locId = jMap.getNthKey(jLocationsConfigMap, i)
        jLocDataMap = jMap.getObj(jLocationsConfigMap, locId)

        Debug.Trace("[SAB] load loc with id " + locId)
        Debug.Trace("[SAB] loc's name is " + jMap.getStr(jLocDataMap, "OverrideDisplayName", "(no OverrideDisplayName set)"))

        bool isEditableLoc = jMap.getInt(jLocDataMap, "isEditable", 0) > 0
        SAB_LocationScript locScript = GetLocationById(locId)

        if locScript == None && isEditableLoc
            ; we're loading an editable loc that hasn't been assigned a script yet! Let's assign
            Debug.Trace("[SAB] loc is editable! assigning an unused script now")
            locScript = GetAnUnusedChangeableLocation()
            Location newLoc = JString.decodeFormStringToForm(locId) as Location
            if newLoc != None && locScript != None
                locScript.ThisLocation = newLoc
                Debug.Trace("[SAB] location found and assigned!")
            endif
        endif

        if locScript != None
            if jLocDataMap != 0
                Debug.Trace("[SAB] loc data ok, fetching stuff from it now")
                bool enableLoc = jMap.getInt(jLocDataMap, "IsEnabled", 1) != 0

                if locScript.isCurrentlyEnabled != enableLoc
                    hasChangedEnabledLocations = true
                    SetLocationEnabled(locScript, enableLoc, false)
                endif

                if enableLoc
                    Debug.Trace("[SAB] this loc is enabled!")
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
                locScript.jStartingUnitsMap = jValue.releaseAndRetain(locScript.jStartingUnitsMap, jMap.getObj(jLocDataMap, "jStartingGarrison"), "ShoutAndBlade")

                if isEditableLoc
                    Debug.Trace("[SAB] this loc is editable! Assign markers now")
                    ; assign markers!
                    int jmarkerMap = jMap.getObj(jLocDataMap, "jRefPosMap")
                    if jmarkerMap != 0
                        SAB_Utils.ApplyJObjectRepresentingMarkerPosition(locScript.GetReference(), jmarkerMap)
                    endif

                    jmarkerMap = jMap.getObj(jLocDataMap, "jMoveDestPosMap")
                    if jmarkerMap != 0
                        SAB_Utils.ApplyJObjectRepresentingMarkerPosition(locScript.MoveDestination, jmarkerMap)
                    endif

                    jmarkerMap = jMap.getObj(jLocDataMap, "jDistCalcPosMap")
                    if jmarkerMap != 0
                        SAB_Utils.ApplyJObjectRepresentingMarkerPosition(locScript.DistCalculationReference, jmarkerMap)
                    endif
                    
                    ; extra markers
                    locScript.GuardExtraMarkersArray()

                    int jWrittenExtraMarkersArr = jMap.getObj(jLocDataMap, "jExtraMarkersArr")
                    
                    int jLocExtraMarkersArr = locScript.jExtraNearbyOutsideMarkersArr
                    int k = jArray.count(jWrittenExtraMarkersArr) ;j's are all over, so I preferred to use k here haha
                    int jWrittenMarkerData = 0

                    while k > 0
                        k -= 1
                        
                        jWrittenMarkerData = jarray.getObj(jWrittenExtraMarkersArr, k)
                        if jWrittenMarkerData != 0
                            ; create new marker and set its pos
                            ; clone one of the markers!
                            ObjectReference newMarker = locScript.MoveDestination.PlaceAtMe(locScript.MoveDestination.GetBaseObject())
                            if !SAB_Utils.ApplyJObjectRepresentingMarkerPosition(newMarker, jWrittenMarkerData)
                                ; the position applying failed, delete this marker
                                newMarker.Delete()
                            else
                                jArray.addForm(jLocExtraMarkersArr, newMarker)
                            endif
                        endif
                    endwhile


                    ; interior cells
                    locScript.GuardInteriorCellsJArray()

                    int jWrittenInteriorCellsArr = jMap.getObj(jLocDataMap, "jInteriorCellsArr")

                    if jWrittenInteriorCellsArr != 0
                        k = jArray.count(jWrittenInteriorCellsArr)

                        while k > 0
                            k -= 1
                            
                            Form newCellForm = jArray.getForm(jWrittenInteriorCellsArr, k)
	                        Debug.Trace("[SAB] load interiorcell form: " + newCellForm)
                            Cell newCell = newCellForm as Cell
                            if newCell != None
                                locScript.AddInteriorCell(newCell)
                            else
                                Debug.Trace("[SAB] got invalid interior cell for location " + locScript.GetLocName())
                            endif
                        endwhile
                        
                    endif
                    
                endif
            else
                Debug.Trace("[SAB] jlocdatamap is invalid! abort")
            endif
        else
            Debug.Trace("[SAB] locscript is none! abort")
        endif
        
    EndWhile

    if hasChangedEnabledLocations
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
        RebuildSortedLocNamesArrays()
    endif
EndFunction


function WriteLocDatasToJmap(bool writeOwnerships, bool writeCurrGarrsInsteadOfStarting)

    int i = 0

    while i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && (!locScript.isChangeable || locScript.AppearsToHaveBeenEdited())
            int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
            endif
    
            jMap.setStr(jLocDataMap, "OverrideDisplayName", locScript.GetLocName())

            if writeOwnerships
                jMap.setInt(jLocDataMap, "OwnerFactionIndex", FactionDataHandler.GetFactionIndex(locScript.factionScript))
            endif
            
            if writeCurrGarrsInsteadOfStarting
                jMap.setObj(jLocDataMap, "jStartingGarrison", locScript.jOwnedUnitsMap)
            else
                jMap.setObj(jLocDataMap, "jStartingGarrison", locScript.jStartingUnitsMap)
            endif

            if locScript.isChangeable
                jMap.setInt(jLocDataMap, "isEditable", 1)

                ; marker-related stuff are written at the time of addition/removal,
                ; as getting the cell of a marker when we're not in that cell can return none

                ; interior cells
                locScript.GuardInteriorCellsJArray()
                jMap.setObj(jLocDataMap, "jInteriorCellsArr", locScript.jInteriorCellsArr)
            endif

        endif

        i += 1
    endwhile

endfunction

Function WriteEditableLocMarkerDataToJmap(SAB_LocationScript locScript, ObjectReference marker, string jDataMapName)
    if !locScript.isChangeable
        return
    endif

    int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

    if jLocDataMap == 0
        jLocDataMap = jMap.object()
        jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
    endif

    if jDataMapName == "jExtraMarkersArr"
        ; special handle to add this marker to the extra markers arr
        int jExtraMarkersArr = jMap.GetObj(jLocDataMap, jDataMapName)
        if jExtraMarkersArr == 0
            jExtraMarkersArr = jArray.object()
            jMap.setObj(jLocDataMap, jDataMapName, jExtraMarkersArr)
        endif

        jArray.addObj(jExtraMarkersArr, SAB_Utils.GetJObjectRepresentingMarkerPosition(marker))
    else
        jMap.setObj(jLocDataMap, jDataMapName, SAB_Utils.GetJObjectRepresentingMarkerPosition(marker))
    endif
endfunction

function RemoveEditableLocExtraMarkerFromJmap(SAB_LocationScript locScript, ObjectReference marker)
    if !locScript.isChangeable
        return
    endif

    int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

    if jLocDataMap == 0
        jLocDataMap = jMap.object()
        jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
    endif

    int jExtraMarkersArr = jMap.GetObj(jLocDataMap, "jExtraMarkersArr")
    if jExtraMarkersArr == 0
        jExtraMarkersArr = jArray.object()
        jMap.setObj(jLocDataMap, "jExtraMarkersArr", jExtraMarkersArr)
    endif

    ; get the marker's jData, then compare it to each one already written. Remove the best match
    int jtargetMarkerData = SAB_Utils.GetJObjectRepresentingMarkerPosition(marker)
    JValue.retain(jtargetMarkerData, "ShoutAndBlade")

    int i = jArray.count(jExtraMarkersArr)
    int jMarkerData = 0
    while i > 0
        i -= 1

        jMarkerData = jArray.getObj(jExtraMarkersArr, i)
        if jMarkerData != 0
            Cell tMarkerCell = jMap.getForm(jtargetMarkerData, "ParentCell") as Cell
            Cell markerCell = jMap.getForm(jMarkerData, "ParentCell") as Cell
            if tMarkerCell == markerCell
                float tPosValue = jMap.getFlt(jtargetMarkerData, "PosX")
                float posValue = jMap.getFlt(jMarkerData, "PosX")
                float threshold = 20.0
                if Math.abs(tPosValue - posValue) <= threshold
                    tPosValue = jMap.getFlt(jtargetMarkerData, "PosY")
                    posValue = jMap.getFlt(jMarkerData, "PosY")
                    if Math.abs(tPosValue - posValue) <= threshold
                        tPosValue = jMap.getFlt(jtargetMarkerData, "PosZ")
                        posValue = jMap.getFlt(jMarkerData, "PosZ")
                        if Math.abs(tPosValue - posValue) <= threshold
                            ; ok, close enough, remove it!
                            jArray.eraseIndex(jMarkerData, i)
                        endif
                    endif
                endif
            endif
        endif
    endwhile

    JValue.release(jtargetMarkerData)
    JValue.zeroLifetime(jtargetMarkerData)
endfunction

function ClearEditableLocExtraMarkersArr(SAB_LocationScript locScript)
    if !locScript.isChangeable
        return
    endif

    int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

    if jLocDataMap == 0
        jLocDataMap = jMap.object()
        jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
    endif

    int jExtraMarkersArr = jMap.GetObj(jLocDataMap, "jExtraMarkersArr")
    if jExtraMarkersArr == 0
        jExtraMarkersArr = jArray.object()
        jMap.setObj(jLocDataMap, "jExtraMarkersArr", jExtraMarkersArr)
    endif

    jArray.clear(jExtraMarkersArr)
endfunction

; creates a string array with location IDs accompanied by their names
string[] Function CreateStringArrayWithLocationIdentifiers(int page = 0)

    int jStringsArr = jArray.object()
    jValue.retain(jStringsArr, "ShoutAndBlade")

    int startingIndex = page * 128
    int i = startingIndex
    int endingIndex = NextLocationIndex
    if ((page + 1) * 128) < endingIndex
        endingIndex = (page + 1) * 128
    endif

    ; Debug.Trace("[SAB] get locs name from " + startingIndex + " to " + endingIndex)

    while i < endingIndex
        int jlocEntryMap = jArray.getObj(jLocationsSortedByNameArr, i)
        if jlocEntryMap != 0
            string locName = jMap.getStr(jlocEntryMap, "locName", "???")
            ; add extra prefix for editable locs... is this loc editable?
            int locIndex = jMap.getInt(jlocEntryMap, "locIndex", -1)
            if locIndex != -1
                if GetLocationByIndex(locIndex).isChangeable
                    locName = "(E) " + locName
                endif
            endif

            ; add loc's name to the jarray
            jArray.addStr(jStringsArr, locName)
        endif

        i += 1
    endwhile

    ; create actual string array with the jarray's size
    ; fill string array with jarray's contents
    ; return string array
    ; Debug.Trace("[SAB] create locs string array with " + jArray.count(jStringsArr) + " entries")
    string[] namesArray = Utility.CreateStringArray(jArray.count(jStringsArr))

    i = startingIndex
    int i_clamped

    while(i < endingIndex)
        i_clamped = i % 128

        namesArray[i_clamped] = jArray.getStr(jStringsArr, i_clamped)

        i += 1
    endwhile

    jValue.release(jStringsArr)
    jValue.zeroLifetime(jStringsArr)

    return namesArray
EndFunction

; creates a string array with only enabled location IDs accompanied by their names
string[] Function CreateStringArrayWithEnabledLocationIdentifiers(int page = 0)

    int jStringsArr = jArray.object()
    jValue.retain(jStringsArr, "ShoutAndBlade")

    int startingIndex = page * 128
    int i = startingIndex
    int endingIndex = NextEnabledLocationIndex
    if (page + 1) * 128 < endingIndex
        endingIndex = (page + 1) * 128
    endif

    while i < endingIndex
        int jlocEntryMap = jArray.getObj(jEnabledLocationsSortedByNameArr, i)
        if jlocEntryMap != 0
            string locName = jMap.getStr(jlocEntryMap, "locName", "???")
            ; add loc's name to the jarray
            jArray.addStr(jStringsArr, locName)
        endif

        i += 1
    endwhile

    ; create actual string array with the jarray's size
    ; fill string array with jarray's contents
    ; return string array
    string[] namesArray = Utility.CreateStringArray(jArray.count(jStringsArr))

    i = startingIndex
    int i_clamped

    while(i < endingIndex)
        i_clamped = i % 128

        namesArray[i_clamped] = jArray.getStr(jStringsArr, i_clamped)

        i += 1
    endwhile

    jValue.release(jStringsArr)
    jValue.zeroLifetime(jStringsArr)

    return namesArray
EndFunction


int Function GetEnabledLocationIndex(SAB_LocationScript targetLocScript)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextEnabledLocationIndex
        locScript = EnabledLocations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript == targetLocScript
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
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.factionScript == factionScript
            JArray.addInt(jReturnedArray, i)
        endif
        i += 1
    endwhile

    return jReturnedArray
EndFunction


; returns a random location from the enabled locations list
SAB_LocationScript Function GetRandomLocation()
    return EnabledLocations.GetRandomFilledRefAlias() as SAB_LocationScript
endfunction

; returns the location script at the target index of the Locations alias updater
SAB_LocationScript Function GetLocationByIndex(int index)
    if index < 0
        return None
    endif

    return Locations.GetUpdatedAliasAtIndex(index) as SAB_LocationScript
EndFunction

; returns the location script at the target index of the ENABLED Locations alias updater
SAB_LocationScript Function GetEnabledLocationByIndex(int index)
    if index < 0
        return None
    endif

    return EnabledLocations.GetUpdatedAliasAtIndex(index) as SAB_LocationScript
EndFunction

SAB_LocationScript Function GetLocationByName(string name)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocName() == name
            return locScript
        endif
        i += 1
    endwhile

    return None
EndFunction

SAB_LocationScript function GetLocationByIndexInSortedNamesArr(int index)
    int jlocNameEntry = jArray.getObj(jLocationsSortedByNameArr, index)
    if jlocNameEntry == 0
        return None
    endif

    return GetLocationByIndex(jMap.getInt(jlocNameEntry, "locIndex", -1))
endfunction

SAB_LocationScript function GetEnabledLocationByIndexInSortedNamesArr(int index)
    int jlocNameEntry = jArray.getObj(jEnabledLocationsSortedByNameArr, index)
    if jlocNameEntry == 0
        return None
    endif

    return GetEnabledLocationByIndex(jMap.getInt(jlocNameEntry, "locIndex", -1))
endfunction

SAB_LocationScript Function GetLocationById(string Id)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocId() == Id
            return locScript
        endif
        i += 1
    endwhile

    return None
EndFunction

; returns location's index in the Locations array. -1 if not found
int Function GetLocationIndexById(string Id)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocId() == Id
            return i
        endif
        i += 1
    endwhile

    return -1
EndFunction

; returns one of the disabled, apparently not edited changeable locs, or none
SAB_LocationScript function GetAnUnusedChangeableLocation()
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.isChangeable && !locScript.isCurrentlyEnabled && !locScript.ShouldBeSaved()
            return locScript
        endif
        i += 1
    endwhile

    return None
endfunction


int Function GetNextIndexForLocationAddon()

    return jArray.count(jregisteredAddonsArray)

EndFunction

bool Function GetIsReaddingAllLocs()
    return isReaddingAllLocations
EndFunction

bool Function GetIsBusyEditingLocData()
    return isReaddingAllLocations || isBusyAddingNewLocsToBaseArray || isBusyUpdatingLocationData
EndFunction

; locationData jmap entries:

; int IsEnabled - key exists = enabled
; int isEditable - greater than 0 = is editable. don't set this to true for locs not set up via the MCM!
; string OverrideDisplayName
; float GarrisonSizeMultiplier
; float GoldRewardMultiplier
; int OwnerFactionIndex - -1 for neutral

; a intMap. The keys for each entry are unit indexes
; int jStartingGarrison