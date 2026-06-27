{
  Attempts to setup faction quests.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_setupEditableLocs;

interface

implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
  sabFile: IwbFile;
  numLocsToCreate: integer;


// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  baseEditableLocsQuest, baseLocAlias, baseXmarker, baseMoveDestMarker, baseDistCalcMarker, baseLocation, curEditedElement, curEditedElementTwo, curEditedListElement: IInterface;
  locationIndex, propertyName, createdUnitIndex: string;
  i, j, nextAliasId: integer;

begin
  numLocsToCreate := 124;

  // 5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseEditableLocsQuest := getRecordByFormID('0520B606');
  baseLocation := getRecordByFormID('0521580C');
  baseXmarker := getRecordByFormID('0520B607');
  baseMoveDestMarker := getRecordByFormID('0520B608');
  baseDistCalcMarker := getRecordByFormID('0520B60A');

  // create factions!
  for i := 1 to numLocsToCreate do
  begin

    locationIndex := i;
	
	//pad index with zeroes
    if i < 10 then begin
		locationIndex := '0' + locationIndex;
		if i < 100 then begin
			locationIndex := '0' + locationIndex;
		end;
	end;

	// first, duplicate the alias, then duplicate markers etc as we assign them
	curEditedListElement := ElementByPath(baseEditableLocsQuest, 'Aliases');
	// base loc alias is index 0
	curEditedElement := ElementByIndex(curEditedListElement, 0);

	// create a copy of the base loc!
	curEditedElement := ElementAssign(curEditedListElement, HighInteger, curEditedElement, false);
	// set its name
	SetEditValue(ElementByPath(curEditedElement, 'ALID'), 'customloc_' + locationIndex);

	// set the main loc marker, its reference.
	// create the marker then assign it
	curEditedElementTwo := wbCopyElementToFile(baseXmarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_editableloc_ref_' + locationIndex); //set editor ID
	SetNativeValue(ElementByPath(curEditedElement, 'ALFR'), FormID(curEditedElementTwo));

	nextAliasId := GetEditValue(ElementByPath(baseEditableLocsQuest, 'ANAM')); //get next available aliasId
	SetEditValue(ElementByPath(curEditedElement, 'ALST'), nextAliasId); //set alias ID

	// now, in the aliases script-related part...
	curEditedListElement := ElementByPath(baseEditableLocsQuest, 'VMAD\Aliases');

	// create new entry based on the first one
	curEditedElement := ElementAssign(curEditedListElement, HighInteger, ElementByIndex(curEditedListElement, 0), false);
	// assign the alias we created before
	SetEditValue(ElementByPath(curEditedElement, 'Object Union\Object v2\Alias'), nextAliasId);

	// get the properties list of the first and only script of the loc alias
	curEditedElement := ElementByIndex(ElementByPath(curEditedElement, 'Alias Scripts'), 0);
	curEditedListElement := ElementByPath(curEditedElement, 'Properties');

	// now, we want to edit the marker and location variables
	// index 2 is distcalc
	curEditedElement := ElementByIndex(curEditedListElement, 2);
	// create the marker clone...
	curEditedElementTwo := wbCopyElementToFile(baseDistCalcMarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'sab_editableloc_distcalc_' + locationIndex); //set editor ID
	SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedElementTwo));

	// index 5 is movedest
	curEditedElement := ElementByIndex(curEditedListElement, 5);
	// create the marker clone...
	curEditedElementTwo := wbCopyElementToFile(baseMoveDestMarker, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'sab_editableloc_movedest_' + locationIndex); //set editor ID
	SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedElementTwo));

	// index 7 is thisLocation
	curEditedElement := ElementByIndex(curEditedListElement, 7);
	// create the loc clone...
	curEditedElementTwo := wbCopyElementToFile(baseLocation, sabFile, true, true);
	SetEditValue(ElementByPath(curEditedElementTwo, 'EDID'), 'SAB_Placeholder_location_' + locationIndex); //set editor ID
	SetNativeValue(ElementByPath(curEditedElement, 'Value\Object Union\Object v2\FormID'), FormID(curEditedElementTwo));

	// last edit: the loc addon locs array! we've got to add this new loc alias to it
	curEditedListElement := ElementByPath(baseEditableLocsQuest, 'VMAD\Scripts');
	curEditedElement := ElementByIndex(curEditedListElement, 0);
	// second property of the script is the locs array
	curEditedElement := ElementByIndex(ElementByPath(curEditedElement,'Properties'), 1);
	curEditedListElement := ElementByPath(curEditedElement, 'Value\Array of Object');
	// create new entry in the array, then fill it
	curEditedElement :=
	  ElementAssign(curEditedListElement, HighInteger, ElementByIndex(curEditedListElement, 0), false);
	SetEditValue(ElementByPath(curEditedElement, 'Object v2\Alias'), nextAliasId);

	nextAliasId := nextAliasId + 1;
	// finally, set the next available aliasID in the faction quest
	SetEditValue(ElementByPath(baseEditableLocsQuest, 'ANAM'), nextAliasId);

	AddMessage('added loc ' + locationIndex);

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

  // it will check if SkyrimUtils data variables were used and will clean them from memory
  // also finishes any needed internal processes like log()
  FinalizeUtils();

end;

end.
