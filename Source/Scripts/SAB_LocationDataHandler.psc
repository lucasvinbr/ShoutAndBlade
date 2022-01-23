scriptname SAB_LocationDataHandler extends Quest
{script for setting up and getting data for locations used by the mod.}

SAB_LocationScript[] Property Locations Auto
{ all locations used by the mod. Factions will browse this list when thinking about where to go }

Function Initialize()
    int i = 0

    ; set up locations
    while i < Locations.Length
        Locations[i].Setup(Locations[i].factionScript)
        
        i += 1
    endwhile

EndFunction



event OnInit()

    int i = 0
    int j = 0
    int k = 0
    bool hasCreatedDistArrayEntry = false

    int jlocationDistancesMap = jIntMap.object()
    JValue.retain(jlocationDistancesMap, "ShoutAndBlade")

    ; fill the distances map with distances between each location
    while i < Locations.Length
        
        debug.Trace(Locations[i])
        
        ObjectReference baseRef = Locations[i].GetReference()
        debug.Trace(baseRef)

        while !baseRef
            Utility.Wait(0.5)
            baseRef = Locations[i].GetReference()
            debug.Trace(baseRef)
        endwhile
        
        int jDistMapsFromI = jIntMap.object()
        JIntMap.setObj(jlocationDistancesMap, i, jDistMapsFromI)

        ; also prepare the "top 3 closest" jArray
        int jDistancesArray = jArray.object()
        JValue.retain(jDistancesArray, "ShoutAndBlade")

        int jClosestIndexesArray = jArray.object()
        JValue.retain(jClosestIndexesArray, "ShoutAndBlade")
        
        j = 0
        while j < Locations.Length
            if i != j
                ; check if we haven't already checked the distance between j and i
                int jDistMapsFromJ = JIntMap.getObj(jlocationDistancesMap, j)
                float distance = 0.0

                if jDistMapsFromJ != 0
                    distance = JIntMap.getFlt(jDistMapsFromJ, i)
                endif

                if distance == 0.0
                    distance = baseRef.GetDistance(Locations[j].GetReference())
                endif

                ; add distance and loc index to the sorted distances arrays
                hasCreatedDistArrayEntry = false
                k = jValue.count(jDistancesArray) - 1
                while k >= 0
                    if jArray.getFlt(jDistancesArray, k) > distance
                        JArray.addFlt(jDistancesArray, distance, k + 1)
                        JArray.addInt(jClosestIndexesArray, j, k + 1)
                        hasCreatedDistArrayEntry = true
                        ; break
                        k = -1
                    endif
                    k -= 1
                endwhile

                if !hasCreatedDistArrayEntry
                    JArray.addFlt(jDistancesArray, distance)
                    JArray.addInt(jClosestIndexesArray, j)
                endif
                

                JIntMap.setFlt(jDistMapsFromI, j, distance)
            endif
            j += 1
            Utility.Wait(0.1)
        endwhile

        ; store the (limited to 3 elements) closest locations array in the location script
        int jTopClosestLocationsArray = jArray.subArray(jClosestIndexesArray, 0, 3)
        jValue.retain(jTopClosestLocationsArray, "ShoutAndBlade")
        Locations[i].jNearbyLocationsArray = jTopClosestLocationsArray

        jValue.release(jDistancesArray)
        jValue.zeroLifetime(jDistancesArray)

        jValue.release(jClosestIndexesArray)
        jValue.zeroLifetime(jClosestIndexesArray)

        i += 1
        Utility.Wait(0.1)
    endwhile

    jValue.release(jlocationDistancesMap)
endevent


; returns a jArray with the indexes of the locations that have the target faction as owner
int Function GetLocationIndexesOwnedByFaction(SAB_FactionScript factionScript)
    int i = 0
    int jReturnedArray = jArray.object()

    while i < Locations.Length
        if Locations[0].factionScript == factionScript
            JArray.addInt(jReturnedArray, i)
        endif
        i += 1
    endwhile

    return jReturnedArray
EndFunction


; returns a random location from the list
SAB_LocationScript Function GetRandomLocation()
    return Locations[Utility.RandomInt(0, Locations.Length - 1)]
endfunction