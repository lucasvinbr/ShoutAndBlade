scriptname SAB_UnitDataHandler extends Quest
{script for setting up and getting data for units/soldiers.}

LeveledActor Property ArgonianM Auto
LeveledActor Property ArgonianF Auto
LeveledActor Property OrcM Auto
LeveledActor Property OrcF Auto
LeveledActor Property KhajiitM Auto
LeveledActor Property KhajiitF Auto
LeveledActor Property BretonM Auto
LeveledActor Property BretonF Auto
LeveledActor Property ImperialM Auto
LeveledActor Property ImperialF Auto
LeveledActor Property NordM Auto
LeveledActor Property NordF Auto
LeveledActor Property RedguardM Auto
LeveledActor Property RedguardF Auto
LeveledActor Property DarkElfM Auto
LeveledActor Property DarkElfF Auto
LeveledActor Property HighElfM Auto
LeveledActor Property HighElfF Auto
LeveledActor Property WoodElfM Auto
LeveledActor Property WoodElfF Auto

FormList Property SAB_UnitActorBases Auto
FormList Property SAB_UnitGearSets Auto
FormList Property SAB_UnitAllowedRacesGenders Auto

; an array of jMaps, each one defining a unit's data
int Property jSABUnitDatasArray Auto

; a unit data jMap just for testing
int Property jTestGuyData Auto

Function InitializeJData()
    jSABUnitDatasArray = JArray.object()
    JValue.retain(jSABUnitDatasArray, "ShoutAndBlade")

    jTestGuyData = JMap.object()
    JValue.retain(jTestGuyData, "ShoutAndBlade")
EndFunction

Function SetupRaceGendersLvlActorAccordingToUnitData(int jUnitData, LeveledActor lvlActor)
    
    lvlActor.Revert()

    int addedEntries = 0

    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceBreton", BretonM, BretonF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceImperial", ImperialM, ImperialF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceNord", NordM, NordF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceRedguard", RedguardM, RedguardF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceDarkElf", DarkElfM, DarkElfF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceHighElf", HighElfM, HighElfF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceWoodElf", WoodElfM, WoodElfF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceArgonian", ArgonianM, ArgonianF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceKhajiit", KhajiitM, KhajiitF)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey(jUnitData, lvlActor, "RaceOrc", OrcM, OrcF)

    if addedEntries == 0
        ; add one lvlActor, to avoid spawning people with 0 appearances
        lvlActor.AddForm(ArgonianF, 0)
    endif

EndFunction

;returns number of lvlActors added to the target LvlActor
int Function AddRaceGenderToLvlActorAccordingToUnitDataKey(int jUnitData, LeveledActor lvlActor, string dataKey, LeveledActor male, LeveledActor female)
    int raceGenderValue = JMap.getInt(jUnitData, dataKey, 0)

    ;0 is "none", 1 is "male only", 2 is "female only", 3 is "both"
    if raceGenderValue == 0
        return 0
    elseif raceGenderValue == 3
        lvlActor.AddForm(male, 0)
        lvlActor.AddForm(female, 0)
        return 2
    elseif raceGenderValue == 2
        lvlActor.AddForm(female, 0)
        return 1
    elseif raceGenderValue == 1
        lvlActor.AddForm(male, 0)
        return 1
    endif

    return 0

EndFunction


int Function GetUnitIndexByUnitName(string name)
    int i = JArray.count(jSABUnitDatasArray)

    while i > 0
        i -= 1

        int unitData = JArray.getObj(jSABUnitDatasArray, i)
        if unitData != 0
            string unitName = jMap.getStr(unitData, "Name", "")

            if unitName == name
                return i
            endif
        endif
    endwhile

    return -1
EndFunction

; unitData jmap entries:

; string Name
; float Health
; float Stamina
; float Magicka
; float SkillMarksman
; float SkillOneHanded
; float SkillTwoHanded
; float SkillLightArmor
; float SkillHeavyArmor
; float SkillBlock

;allowed races/genders - 0 is "none", 1 is "male only", 2 is "female only", 3 is "both"

; int RaceBreton
; int RaceImperial
; int RaceNord
; int RaceRedguard

; int RaceDarkElf
; int RaceHighElf
; int RaceWoodElf

; int RaceArgonian
; int RaceKhajiit
; int RaceOrc