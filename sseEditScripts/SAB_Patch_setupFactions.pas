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
  curEditedFaction, curEditedQuest, curEditedXmarker, curEditedElement, curEditedListElement: IInterface;
  factionIndex, propertyName, createdUnitIndex: string;
  i, j: integer;

begin
  // 6 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(6);
  baseFactionQuest := getRecordByFormID('0606B3F4');
  baseFaction := getRecordByFormID('0606B3F5');
  baseXmarker := getRecordByFormID('0607A6FA');
  baseCmderDestAPkg := getRecordByFormID('0606B3F6');
  baseCmderDestBPkg := getRecordByFormID('060848FF');
  baseCmderDestCPkg := getRecordByFormID('06084900');
  baseFollowCmderPkg := getRecordByFormID('0606B3F7');
  factionQuestsFormList := getRecordByFormID('060755F9');
  sabMainQuest := getRecordByFormID('0601EFC3');

  factionsList := TList.Create;
  factionQuestsList := TList.Create;

  factionsList.Add(baseFaction);
  factionQuestsList.Add(baseFactionQuest);

  // create factions!
  for i := 1 to 25 do
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
	// factionsHandler is index 0
	curEditedElement := ElementByIndex(curEditedListElement, 0); 
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
	
	//faction script has 7 properties, almost all of them (except two, 'OurFaction' and 'SpawnerScript') point to our quest
	for j := 0 to ElementCount(curEditedListElement) do
	begin
		curEditedElement := ElementByIndex(curEditedListElement, j);
		propertyName := GetEditValue(ElementByPath(curEditedElement, 'propertyName'));
		
		// 'OurFaction' should point to... our faction
		if propertyName = 'OurFaction' then begin
			SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedFaction));
		end else begin
			if propertyName <> 'SpawnerScript' then begin
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
	curEditedXmarker := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedXmarker, 'EDID'), 'SAB_FactionCmderSpawnPoint_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 2);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedXmarker));
	
	curEditedXmarker := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedXmarker, 'EDID'), 'SAB_FactionCmderDestinationA_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 3);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedXmarker));
	
	curEditedXmarker := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedXmarker, 'EDID'), 'SAB_FactionCmderDestinationB_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 4);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedXmarker));
	
	curEditedXmarker := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedXmarker, 'EDID'), 'SAB_FactionCmderDestinationC_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 5);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedXmarker));
	
	curEditedXmarker := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedXmarker, 'EDID'), 'SAB_FactionUnitSpawnPoint_' + factionIndex); //set editor ID
	curEditedElement := ElementByIndex(curEditedListElement, 6);
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedXmarker));
	
	

    log('created fac ' + factionIndex);
  end;
  
  
  
  // now that all factions exist, set faction relations!
  // since factions are copied from faction00, which already has an "ally" relation to itself (faction00),
  // we can just edit the first entry of the list
  // and add the rest
  for i := 0 to 25 do
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
	for j := 1 to 25 do
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
		SetEditValue(ElementByPath(followCmderPkg, 'EDID'), 'SAB_FactionPackage_' + factionIndex + '_FollowCmder_0'); //set editor ID
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
	// create new cmders now
	for j := 1 to 8 do begin
	
		createdUnitIndex := (j + 1);
	
		curEditedElement := ElementAssign(curEditedListElement, HighInteger, ElementByIndex(curEditedListElement, 0), false);
		SetEditValue(ElementByPath(curEditedElement, 'ALID'), 'Commander' + createdUnitIndex); //set editor ID
		curEditedElement := ElementByPath(curEditedElement, 'Alias Package Data');
		
		if (j mod 3) = 0 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestAPkg));
		end else if (j mod 3) = 1 then begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestBPkg));
		end else begin
			SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(cmderDestCPkg));
		end;
		
	end;
	
	
	
	
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
