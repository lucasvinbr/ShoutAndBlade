scriptname SAB_UnitDataHandler extends Quest
{script for setting up and getting data for units/soldiers.}

LeveledActor Property SAB_LooksList_Argonian_M Auto
LeveledActor Property SAB_LooksList_Argonian_F Auto
LeveledActor Property SAB_LooksList_Orc_M Auto
LeveledActor Property SAB_LooksList_Orc_F Auto
LeveledActor Property SAB_LooksList_Khajiit_M Auto
LeveledActor Property SAB_LooksList_Khajiit_F Auto
LeveledActor Property SAB_LooksList_Breton_M Auto
LeveledActor Property SAB_LooksList_Breton_F Auto
LeveledActor Property SAB_LooksList_Imperial_M Auto
LeveledActor Property SAB_LooksList_Imperial_F Auto
LeveledActor Property SAB_LooksList_Nord_M Auto
LeveledActor Property SAB_LooksList_Nord_F Auto
LeveledActor Property SAB_LooksList_Redguard_M Auto
LeveledActor Property SAB_LooksList_Redguard_F Auto
LeveledActor Property SAB_LooksList_DarkElf_M Auto
LeveledActor Property SAB_LooksList_DarkElf_F Auto
LeveledActor Property SAB_LooksList_HighElf_M Auto
LeveledActor Property SAB_LooksList_HighElf_F Auto
LeveledActor Property SAB_LooksList_WoodElf_M Auto
LeveledActor Property SAB_LooksList_WoodElf_F Auto

FormList Property SAB_UnitActorBases Auto
FormList Property SAB_UnitGearSets Auto
FormList Property SAB_UnitAllowedRacesGenders Auto

; an array of jMaps, each one defining a unit's data
int Property jSABUnitDatasArray Auto

; a unit data jMap just for testing
int Property jTestGuyData Auto
LeveledActor Property SAB_UnitLooks_TestGuy Auto
LeveledItem Property SAB_UnitGear_TestGuy Auto

Function InitializeJData()
    jSABUnitDatasArray = JArray.object()
    JValue.retain(jSABUnitDatasArray, "ShoutAndBlade")

    jTestGuyData = JMap.object()
    JValue.retain(jTestGuyData, "ShoutAndBlade")
EndFunction

Function SetupRaceGendersLvlActorAccordingToUnitData(int jUnitData, LeveledActor lvlActor)
    
    ;Debug.Notification("SetupRaceGendersLvlActorAccordingToUnitData " + lvlActor)

    lvlActor.Revert()

    int addedEntries = 0

    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceBreton", SAB_LooksList_Breton_M, SAB_LooksList_Breton_M)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceImperial", SAB_LooksList_Imperial_M, SAB_LooksList_Imperial_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \ 
     (jUnitData, lvlActor, "RaceNord", SAB_LooksList_Nord_M, SAB_LooksList_Nord_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceRedguard", SAB_LooksList_Redguard_M, SAB_LooksList_Redguard_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceDarkElf", SAB_LooksList_DarkElf_M, SAB_LooksList_DarkElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceHighElf", SAB_LooksList_HighElf_M, SAB_LooksList_HighElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \ 
     (jUnitData, lvlActor, "RaceWoodElf", SAB_LooksList_WoodElf_M, SAB_LooksList_WoodElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceArgonian", SAB_LooksList_Argonian_M, SAB_LooksList_Argonian_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceKhajiit", SAB_LooksList_Khajiit_M, SAB_LooksList_Khajiit_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceOrc", SAB_LooksList_Orc_M, SAB_LooksList_Orc_F)

    if addedEntries == 0
        ; if no entries have been selected,
        ; add one lvlActor anyway, to avoid spawning people with 0 appearances
        ;Debug.Notification("SetupRaceGendersLvlActorAccordingToUnitData: added argonianF to have something in the list")
        lvlActor.AddForm(SAB_LooksList_Argonian_F, 1)
    endif

EndFunction

;returns number of lvlActors added to the target LvlActor
int Function AddRaceGenderToLvlActorAccordingToUnitDataKey(int jUnitData, LeveledActor lvlActor, string dataKey, LeveledActor male, LeveledActor female)
    int raceGenderValue = JMap.getInt(jUnitData, dataKey, 0)

    ;0 is "none", 1 is "male only", 2 is "female only", 3 is "both"
    if raceGenderValue == 0
        return 0
    elseif raceGenderValue == 3
        lvlActor.AddForm(male, 1)
        lvlActor.AddForm(female, 1)
        return 2
    elseif raceGenderValue == 2
        lvlActor.AddForm(female, 1)
        return 1
    elseif raceGenderValue == 1
        lvlActor.AddForm(male, 1)
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