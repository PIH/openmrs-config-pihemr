function encounterOfTypeAfterDate(encounters, encounterTypeUuid, afterDate) {
  if (!encounters) {
    return false;
  }

  if (!afterDate) {
    return false;
  }

  var i, len = encounters.length;
  for (i = 0; i < len; ++i) {
    if ( (new Date(encounters[i].encounterDatetime)) >= new Date(afterDate) && encounters[i].encounterTypeUuid === encounterTypeUuid) {
      return true;
    }
  }
  return false;
}
