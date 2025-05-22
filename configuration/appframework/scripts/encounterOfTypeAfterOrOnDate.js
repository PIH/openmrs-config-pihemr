function encounterOfTypeAfterOrOnDate(encounters, encounterTypeUuid, afterDate) {
  if (!encounters) {
    return false;
  }

  return some(encounters, (function(encounter) {
    return ( encounter.encounterTypeUuid === encounterTypeUuid ) &&  ( !afterDate || (new Date(encounter.encounterDatetime)) >= new Date(afterDate) );
  }))
  
}
