scriptname SAB_RefAliasContainer extends Form
{ a container for SAB_UpdatedReferenceAlias. 
 We can make an array of this container to get storage for as much as 128 * 128 aliases. }

; we need more arrays because of the 128 elements limit
SAB_UpdatedReferenceAlias[] SAB_ActiveElements

function Initialize()
	debug.Trace("alias container: initialize!")
	SAB_ActiveElements = new SAB_UpdatedReferenceAlias[128]
endfunction

SAB_UpdatedReferenceAlias[] function GetElementsArray()
	return SAB_ActiveElements
endfunction