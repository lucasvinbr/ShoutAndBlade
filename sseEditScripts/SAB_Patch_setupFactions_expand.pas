{
  Attempts to add more faction quests. We already have a lot!
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_setupFactions_expand;

interface

implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
  sabFile: IwbFile;
  factionsList, factionQuestsList: TList;
  numFactionsToCreate: integer;
  startingNewFactionIndex: integer;


// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  baseFactionQuest, baseFaction, baseXmarker,
  baseCmderDestAPkg, baseCmderDestBPkg, baseCmderDestCPkg, baseFollowCmderPkg,
  cmderDestAPkg, cmderDestBPkg, cmderDestCPkg, followCmderPkg,
  factionQuestsFormList, sabMainQuest, sabPlayerQuest,
  curEditedFaction, curEditedQuest, curEditedElement, curEditedElementTwo, curEditedListElement: IInterface;
  factionIndex, propertyName, createdUnitIndex: string;
  i, j, k, nextAliasId: integer;

begin
  startingNewFactionIndex := 100;
  numFactionsToCreate := 26;

  // 5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseFactionQuest := getRecordByFormID('0506B3F4');
  baseFaction := getRecordByFormID('0506B3F5');
  baseXmarker := getRecordByFormID('0507A6FA');
  baseCmderDestAPkg := getRecordByFormID('0506B3F6');
  baseCmderDestBPkg := getRecordByFormID('050848FF');
  baseCmderDestCPkg := getRecordByFormID('05084900');
  baseFollowCmderPkg := getRecordByFormID('0506B3F7');
  factionQuestsFormList := getRecordByFormID('050755F9');
  sabMainQuest := getRecordByFormID('0501EFC3');
  sabPlayerQuest := getRecordByFormID('0510D4CD');

  factionsList := TList.Create;
  factionQuestsList := TList.Create;

  factionsList.Add(baseFaction);
  factionQuestsList.Add(baseFactionQuest);

  // create factions!
  for i := 1 to numFactionsToCreate do
  begin

    factionIndex := startingNewFactionIndex + i;
	
	//pad index with zeroes
    if factionIndex < 10 then begin
		factionIndex := '0' + factionIndex;
	end;
	
	// create a copy of the base faction!
	curEditedFaction := wbCopyElementToFile(baseFaction, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedFaction, 'EDID'), 'SAB_Faction_' + factionIndex); //set editor ID
	factionsList.Add(curEditedFaction);

	// create a copy of the base faction quest!
	curEditedQuest := wbCopyElementToFile(baseFactionQuest, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedQuest, 'EDID'), 'SAB_FactionQuest_' + factionIndex); //set editor ID
	factionQuestsList.Add(curEditedQuest);
	
	
	// add the faction quest to the factions formlist! (we're not using it right now, but I believe it may help in the future)
	curEditedElement :=
      ElementAssign(ElementByPath(factionQuestsFormList, 'FormIDs'), HighInteger, nil, false);
    SetNativeValue(curEditedElement, FormID(curEditedQuest));
	
	// add the faction quest to the factions array in the main quest factionsHandler script!
	curEditedListElement := ElementByPath(sabMainQuest, 'VMAD\Scripts');
	// factionsHandler is index 2
	curEditedElement := ElementByIndex(curEditedListElement, 2); 
    curEditedListElement := ElementByPath(curEditedElement, 'Properties');
	curEditedElement := ElementByIndex(curEditedListElement, 1); // SAB_FactionQuests array
	curEditedListElement := ElementByPath(curEditedElement, 'Value\Array of Object');
	curEditedElement :=
      ElementAssign(curEditedListElement, HighInteger, nil, false);
    SetNativeValue(ElementByPath(curEditedElement, 'Object v2\FormID'), FormID(curEditedQuest));
	
	
	// make faction quest script's variables point to its own quest instead of the base one
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Scripts');
	curEditedElement := ElementByIndex(curEditedListElement, 0);
	// get script's properties...
	curEditedListElement := ElementByPath(curEditedElement, 'Properties');
	
	// most of the properties of the faction script point to its own quest
	// (we avoid the exceptions below)
	for j := 0 to ElementCount(curEditedListElement) do
	begin
		curEditedElement := ElementByIndex(curEditedListElement, j);
		propertyName := GetEditValue(ElementByPath(curEditedElement, 'propertyName'));
		
		// 'OurFaction' should point to... our faction
		if propertyName = 'OurFaction' then begin
			SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedFaction));
		end else begin
			if (propertyName <> 'SpawnerScript') and (propertyName <> 'DefaultCmderSpawnPointsList') and (propertyName <> 'UnitUpdater')
				and (propertyName <> 'LocationDataHandler') and (propertyName <> 'DiplomacyDataHandler') then begin
				SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedQuest));
			end;
		end;
	end;
	
	// make existing ref aliases' scripts also point to this quest
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Aliases');

	j := ElementCount(curEditedListElement);
	while j > 0 do
	begin
		j := j - 1;
		curEditedElement := ElementByIndex(curEditedListElement, j);
		SetNativeValue(ElementByPath(curEditedElement, 'Object Union\Object v2\FormID'), FormID(curEditedQuest));
	end;
	
	
	curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
	
	// create xMarkers for each required referenceAlias of this faction
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionCmderSpawnPoint_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 2);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));
	
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionCmderDestinationA_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 3);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));
	
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionCmderDestinationB_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 4);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));
	
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionCmderDestinationC_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 5);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));
	
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionUnitSpawnPoint_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 6);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));
	
	

    AddMessage('created fac ' + factionIndex);
  end;
  
  
  
  // now that all factions exist with most of the basic data, fill in the rest and set faction relations!
  // since factions are copied from faction00, which already has an "ally" relation to itself (faction00),
  // we can just edit the first entry of the list
  // and add the rest
  for i := 1 to numFactionsToCreate do
  begin
  
	factionIndex := startingNewFactionIndex + i;
	
	//pad index with zeroes
    if factionIndex < 10 then begin
		factionIndex := '0' + factionIndex;
	end;
  
	curEditedFaction := ObjectToElement(factionsList[i]);
	curEditedListElement := ElementByPath(curEditedFaction, 'Relations');


	// faction diplomacy should take care of setting inter-faction reactions!
	// We've just got to make sure the faction is allied to itself, like faction00 is
	curEditedElement := ElementByIndex(curEditedListElement, 0);
	SetNativeValue(ElementByPath(curEditedElement, 'Faction'), FormID(ObjectToElement(factionsList[i])));

	
	AddMessage('set up relations for fac ' + factionIndex);
	
	
	
	
  
	curEditedQuest := ObjectToElement(factionQuestsList[i]);
	
	// set up cmder and unit packages...
	cmderDestAPkg := wbCopyElementToFile(baseCmderDestAPkg, sabFile, true, true);
	SetEditValue(ElementByPath(cmderDestAPkg, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_CmderTravel_A'); //set editor ID
	SetNativeValue(ElementByPath(cmderDestAPkg, 'QNAM'), FormID(curEditedQuest));

	cmderDestBPkg := wbCopyElementToFile(baseCmderDestBPkg, sabFile, true, true);
	SetEditValue(ElementByPath(cmderDestBPkg, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_CmderTravel_B'); //set editor ID
	SetNativeValue(ElementByPath(cmderDestBPkg, 'QNAM'), FormID(curEditedQuest));

	cmderDestCPkg := wbCopyElementToFile(baseCmderDestCPkg, sabFile, true, true);
	SetEditValue(ElementByPath(cmderDestCPkg, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_CmderTravel_C'); //set editor ID
	SetNativeValue(ElementByPath(cmderDestCPkg, 'QNAM'), FormID(curEditedQuest));

	followCmderPkg := wbCopyElementToFile(baseFollowCmderPkg, sabFile, true, true);
	SetEditValue(ElementByPath(followCmderPkg, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_FollowCmder_1'); //set editor ID
	SetNativeValue(ElementByPath(followCmderPkg, 'QNAM'), FormID(curEditedQuest));

	// set base cmder to use the new packages and correct faction
	curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
	curEditedElementTwo := ElementByIndex(curEditedListElement, 0); //commander1
	curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Package Data');
	SetNativeValue(ElementByIndex(curEditedElement, 1), FormID(cmderDestAPkg)); // it's the second package in the cmder stack

	curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Factions');
	SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(ObjectToElement(factionsList[i])));

	// update other cmders now
	for j := 7 to 20 do begin

		curEditedElementTwo := ElementByIndex(curEditedListElement, j);
		curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Package Data');

		// "go to destination X" is the second package in the cmder stack
		// alternate cmder destinations! A, B, C, A, B...
		if (j mod 3) = 0 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 1), FormID(cmderDestAPkg));
		end else if (j mod 3) = 1 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 1), FormID(cmderDestBPkg));
		end else begin
			SetNativeValue(ElementByIndex(curEditedElement, 1), FormID(cmderDestCPkg));
		end;

		curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Factions');
		SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(ObjectToElement(factionsList[i])));

	end;


	// set base unit to use the new packages and correct faction
	curEditedElementTwo := ElementByIndex(curEditedListElement, 1); //unit1

	curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Package Data');
	SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(followCmderPkg));

	curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Factions');
	SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(ObjectToElement(factionsList[i])));
	
	// update other units now
	for j := 21 to 119 do begin

		curEditedElementTwo := ElementByIndex(curEditedListElement, j);

		curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Package Data');
		SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(followCmderPkg));

		curEditedElement := ElementByPath(curEditedElementTwo, 'Alias Factions');
		SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(ObjectToElement(factionsList[i])));

	end;

	// create new "follow cmder" packages, one for each of the new cmders,
	// then add them to all units
	for j := 1 to 14 do begin

		nextAliasId := j + 13; // commander aliases ids go from 13 to 27. We want to start with commander 2, so 14 it is
		createdUnitIndex := (j + 1);
		// create new package based on the first one of this fac
		curEditedElementTwo := wbCopyElementToFile(followCmderPkg, sabFile, true, true);
		SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_FollowCmder_' + createdUnitIndex); //set editor ID
		
		// the first entry in the package data is the "who to follow" variable
		curEditedElement := ElementByIndex(ElementByPath(curEditedElementTwo, 'Package Data\Data Input Values'), 0);
		SetEditValue(ElementByPath(curEditedElement, 'PTDA\Target Data\Alias'), nextAliasId);
		
		// we must also change the follower faction rank condition
		curEditedElement := ElementByIndex(ElementByPath(curEditedElementTwo, 'Conditions'), 0);
		SetEditValue(ElementByPath(curEditedElement, 'CTDA\Comparison Value'), createdUnitIndex);
		
		// with the package set up, add it to every unit's packages

		curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
		// base unit is index 1
		curEditedElement := ElementByIndex(curEditedListElement, 1);
		curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
		SetNativeValue(ElementByIndex(curEditedElement, j), FormID(curEditedElementTwo));

		// now we apply it for all the other units
		for k := 21 to 119 do begin

			curEditedElement := ElementByIndex(curEditedListElement, k);
			curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
			SetNativeValue(ElementByIndex(curEditedElement, j), FormID(curEditedElementTwo));

		end;
		
		nextAliasId := nextAliasId + 1;
	end;
	
	
	

	AddMessage('set up units and cmders for fac ' + factionIndex);
  
  end;
  
  Result := 0;
end;




// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  Result := 0;

  // comment this out if you don't want those messages
  { AddMessage('Processing: ' + FullPath(e)); }
  // same as above line, but using SkyrimUtils
  //log('Processing: ' + FullPath(e));
  // processing code goes here

end;

// Called after processing
function Finalize: integer;
begin
  Result := 0;

  factionsList.Free;
  factionQuestsList.Free;
  // it will check if SkyrimUtils data variables were used and will clean them from memory
  // also finishes any needed internal processes like log()
  FinalizeUtils();

end;

end.
