{
  Attempts to setup faction quests.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_setupFactions;

interface

implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
  sabFile: IwbFile;
  factionsList, factionQuestsList: TList;


// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  baseFactionQuest, baseFaction, baseXmarker,
  baseCmderDestAPkg, baseCmderDestBPkg, baseCmderDestCPkg, baseFollowCmderPkg,
  cmderDestAPkg, cmderDestBPkg, cmderDestCPkg, followCmderPkg,
  factionQuestsFormList, sabMainQuest,
  curEditedFaction, curEditedQuest, curEditedElement, curEditedElementTwo, curEditedListElement: IInterface;
  factionIndex, propertyName, createdUnitIndex: string;
  i, j, nextAliasId: integer;

begin
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

  factionsList := TList.Create;
  factionQuestsList := TList.Create;

  factionsList.Add(baseFaction);
  factionQuestsList.Add(baseFactionQuest);

  // create factions!
  for i := 1 to 40 do
  begin

    factionIndex := i;
	
	//pad index with zeroes
    if i < 10 then begin
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
	// factionsHandler is index 1
	curEditedElement := ElementByIndex(curEditedListElement, 1); 
    curEditedListElement := ElementByPath(curEditedElement, 'Properties');
	curEditedElement := ElementByIndex(curEditedListElement, 0);
	curEditedListElement := ElementByPath(curEditedElement, 'Value\Array of Object');
	curEditedElement :=
      ElementAssign(curEditedListElement, HighInteger, nil, false);
    SetNativeValue(ElementByPath(curEditedElement, 'Object v2\FormID'), FormID(curEditedQuest));
	
	
	// make faction quest script's variables point to this quest instead of the base one
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Scripts');
	curEditedElement := ElementByIndex(curEditedListElement, 0);
	// get script's properties...
	curEditedListElement := ElementByPath(curEditedElement, 'Properties');
	
	// most of the properties of the faction script point to our quest
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
				and (propertyName <> 'LocationDataHandler') then begin
				SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedQuest));
			end;
		end;
	end;
	
	// make existing ref aliases' scripts also point to this quest
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Aliases');
	
	for j := 0 to ElementCount(curEditedListElement) do
	begin
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
	
	

    log('created fac ' + factionIndex);
  end;
  
  
  
  // now that all factions exist with most of the basic data, fill in the rest and set faction relations!
  // since factions are copied from faction00, which already has an "ally" relation to itself (faction00),
  // we can just edit the first entry of the list
  // and add the rest
  for i := 0 to 40 do
  begin
  
	factionIndex := i;
	
	//pad index with zeroes
    if i < 10 then begin
		factionIndex := '0' + factionIndex;
	end;
  
	curEditedFaction := ObjectToElement(factionsList[i]);
	curEditedListElement := ElementByPath(curEditedFaction, 'Relations');
	
	if i > 0 then begin
		//set relations with faction00
		//get relation entry...
		curEditedElement := ElementByIndex(curEditedListElement, 0);
		SetEditValue(ElementByPath(curEditedElement, 'Group Combat Reaction'), 'Enemy');
	end;
	
	// add relation entries for each faction
	for j := 1 to 40 do
	begin
		curEditedElement := ElementAssign(curEditedListElement, HighInteger, nil, false);
		SetNativeValue(ElementByPath(curEditedElement, 'Faction'), FormID(ObjectToElement(factionsList[j])));
		if i = j then begin
			SetEditValue(ElementByPath(curEditedElement, 'Group Combat Reaction'), 'Ally');
		end else begin
			SetEditValue(ElementByPath(curEditedElement, 'Group Combat Reaction'), 'Enemy');
		end;
	end;
	
	log('set up relations for fac ' + factionIndex);
	
	
	
	
	// create extra cmders and units for all factions!
	// faction00 already has part of the stuff set up, but still needs some editing as well
  
	curEditedQuest := ObjectToElement(factionQuestsList[i]);
	
	// set up cmder and unit packages... faction00 already has 4 of them set up
	if i = 0 then begin
		cmderDestAPkg := baseCmderDestAPkg;
		cmderDestBPkg := baseCmderDestBPkg;
		cmderDestCPkg := baseCmderDestCPkg;
		followCmderPkg := baseFollowCmderPkg;
	end else begin
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
		
		// set existing unit and cmder to use the new packages
		curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
		curEditedElement := ElementByIndex(curEditedListElement, 0); //commander1
		curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
		SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestAPkg));
		
		curEditedElement := ElementByIndex(curEditedListElement, 1); //unit1
		curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
		SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(followCmderPkg));
		
	end;
	
	curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
	nextAliasId := GetEditValue(ElementByPath(curEditedQuest, 'ANAM')); //get next available aliasId
	
	// create new cmders now
	for j := 1 to 14 do begin
		
		createdUnitIndex := (j + 1);
		// the first alias of the quest is the base cmder
		curEditedElement := ElementAssign(curEditedListElement, HighInteger, ElementByIndex(curEditedListElement, 0), false);
		SetEditValue(ElementByPath(curEditedElement, 'ALID'), 'Commander' + createdUnitIndex); //set editor ID
		SetEditValue(ElementByPath(curEditedElement, 'ALST'), nextAliasId); //set alias ID
		nextAliasId := nextAliasId + 1;
		curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
		
		if (j mod 3) = 0 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestAPkg));
		end else if (j mod 3) = 1 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestBPkg));
		end else begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestCPkg));
		end;
		
	end;
	
	// create script entries for the new cmders
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Aliases');
	// reset the aliasID counter, because we'll count through it again for each cmder
	nextAliasId := nextAliasId - 14;
	
	for j := 1 to 14 do begin
		
		createdUnitIndex := (j + 1);
	
		// the second script in the alias scripts list is a cmder script!
		curEditedElement := ElementAssign(curEditedListElement, HighInteger, ElementByIndex(curEditedListElement, 1), false);
		SetEditValue(ElementByPath(curEditedElement, 'Object Union\Object v2\Alias'), nextAliasId);
		
		// get the properties list of the first and only script of the cmder
		curEditedElement := ElementByIndex(ElementByPath(curEditedElement, 'Alias Scripts'), 0);
		curEditedElement := ElementByPath(curEditedElement, 'Properties');
		
		// get the two properties we're interested in (2 = CmderDestinationType, 3 = CmderFollowFactionRank)
		curEditedElementTwo := ElementByIndex(curEditedElement, 3);
		curEditedElement := ElementByIndex(curEditedElement, 2);
		
		
		if (j mod 3) = 0 then begin
			SetEditValue(ElementByPath(curEditedElement, 'String'), 'a');
		end else if (j mod 3) = 1 then begin
			SetEditValue(ElementByPath(curEditedElement, 'String'), 'b');
		end else begin
			SetEditValue(ElementByPath(curEditedElement, 'String'), 'c');
		end;
		
		SetEditValue(ElementByPath(curEditedElementTwo, 'Int32'), createdUnitIndex);
		
		nextAliasId := nextAliasId + 1;
	end;
	
	
	
	// set up the base unit of this fac:
	// create new "follow cmder" packages, one for each of the new cmders,
	// then add them to the unit
	curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
	// base unit is index 1
	curEditedElement := ElementByIndex(curEditedListElement, 1);
	curEditedListElement := ElementByPath(curEditedElement, 'Alias Package Data');
	
	// reset the aliasID counter, because we'll count through it again for each cmder
	nextAliasId := nextAliasId - 14;
	
	for j := 1 to 14 do begin
		
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
		
		// with the package set up, add it to the unit's packages
		curEditedElement := ElementAssign(curEditedListElement, HighInteger, nil, false);
		SetNativeValue(curEditedElement, FormID(curEditedElementTwo));
		
		nextAliasId := nextAliasId + 1;
	end;
	
	// move the sandbox package of the unit to the bottom of its list!
	// the sandbox package should be in index 1
	curEditedElementTwo := ElementByIndex(curEditedListElement, 1);
	curEditedElement := ElementAssign(curEditedListElement, HighInteger, nil, false);
	SetNativeValue(curEditedElement, GetNativeValue(curEditedElementTwo));
	RemoveByIndex(curEditedListElement, 1, true);
	
	
	// the base unit is all set now!
	// it's time to make lots of copies of it
	curEditedListElement := ElementByPath(curEditedQuest, 'Aliases');
	// base unit is index 1
	curEditedElement := ElementByIndex(curEditedListElement, 1);
	
	// set the base unit's aliasID to the next ID, so that we can have all units in one block over which we can iterate by ID
	SetEditValue(ElementByPath(curEditedElement, 'ALST'), nextAliasId); //set alias ID
	
	//we've got to update the script alias ID too
	curEditedElementTwo := ElementByPath(curEditedQuest, 'VMAD\Aliases');
	curEditedElementTwo := ElementByIndex(curEditedElementTwo, 0);
	SetEditValue(ElementByPath(curEditedElementTwo, 'Object Union\Object v2\Alias'), nextAliasId);
	
	nextAliasId := nextAliasId + 1;
	
	for j := 1 to 99 do begin
		
		createdUnitIndex := (j + 1);
		
		curEditedElementTwo := ElementAssign(curEditedListElement, HighInteger, curEditedElement, false);
		SetEditValue(ElementByPath(curEditedElementTwo, 'ALID'), 'Unit' + createdUnitIndex); //set alias name
		SetEditValue(ElementByPath(curEditedElementTwo, 'ALST'), nextAliasId); //set alias ID
		
		nextAliasId := nextAliasId + 1;
	end;
	
	// make lots of copies of the unit script as well
	curEditedListElement := ElementByPath(curEditedQuest, 'VMAD\Aliases');
	// since we've edited unit1's ID and the list is sorted, it should have moved to the end of the list!
	curEditedElement := ElementByIndex(curEditedListElement, ElementCount(curEditedListElement) - 1);
	// count aliases from 1 to 100 again
	nextAliasId := nextAliasId - 99;
	
	for j := 1 to 99 do begin
		
		createdUnitIndex := (j + 1);
		
		curEditedElementTwo := ElementAssign(curEditedListElement, HighInteger, curEditedElement, false);
		SetEditValue(ElementByPath(curEditedElementTwo, 'Object Union\Object v2\Alias'), nextAliasId);
		
		nextAliasId := nextAliasId + 1;
	end;
	
	
	// finally, set the next available aliasID in the faction quest
	SetEditValue(ElementByPath(curEditedQuest, 'ANAM'), nextAliasId);
	
	log('set up units and cmders for fac ' + factionIndex);
  
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
  log('Processing: ' + FullPath(e));
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
