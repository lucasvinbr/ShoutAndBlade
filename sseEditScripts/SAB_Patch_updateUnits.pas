{
  Attempts to update some values of all units based on unit00's values.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_updateUnits;

interface
implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
  sabFile: IwbFile;
  
  
procedure UpdateUnitElement(elementSignature: string; sourceUnit: IInterface; targetUnit: IInterface);
var
	sourceElement, targetElement : IInterface;
begin
	sourceElement := ElementBySignature(sourceUnit, elementSignature);
	targetElement := ElementBySignature(targetUnit, elementSignature);
	
	if not Assigned(sourceElement) then begin
		//source unit does not have the field!
		//if target unit has it, we should remove it
		if Assigned(targetElement) then begin
			Remove(targetElement);
			Exit;
		end;
	end else begin
		//source unit has the field!
		//if target unit doesn't, we should create it		
		if not Assigned(targetElement) then begin
			targetElement := Add(targetUnit, elementSignature, false);
		end;
	end;
	
	ElementAssign(targetElement, LowInteger, sourceElement, false);
end;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  baseNpc,
  curEditedElement, curEditedUnit,
  allUnitsList : IInterface;
  unitIndex : string;
  i: integer;

begin
  //5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseNpc := getRecordByFormID('050477EC');

  allUnitsList := getRecordByFormID('050240DF');

  //update entries!
  for i := 1 to 255 do begin

	unitIndex := i;

	curEditedUnit := LinksTo(ElementByIndex(ElementByPath(allUnitsList, 'FormIDs'), i));

	//copy AI data from unit00
	UpdateUnitElement('AIDT', baseNpc, curEditedUnit);

	//copy combat style from unit00
	UpdateUnitElement('ZNAM', baseNpc, curEditedUnit);
	
	//copy override package lists from unit00
	UpdateUnitElement('SPOR', baseNpc, curEditedUnit);
	UpdateUnitElement('OCOR', baseNpc, curEditedUnit);
	UpdateUnitElement('ECOR', baseNpc, curEditedUnit);
	
	//copy default package list from unit00
	UpdateUnitElement('DPLT', baseNpc, curEditedUnit);
	
	//copy main packages from unit00
	curEditedElement := Add(curEditedUnit, 'Packages', false);
	ElementAssign(curEditedElement, LowInteger, ElementByPath(baseNpc, 'Packages'), false);

	log('updated unit ' + unitIndex);
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

  // it will check if SkyrimUtils data variables were used and will clean them from memory
  // also finishes any needed internal processes like log()
  FinalizeUtils();

end;

end.