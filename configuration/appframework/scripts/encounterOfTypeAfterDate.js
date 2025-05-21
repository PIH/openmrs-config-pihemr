function encounterOfTypeAfterDate(encounters, encounterTypeUuid, dateEnrolled) {
  if (!encounters) {
    return false;
  }

  if (!dateEnrolled) {
    return false;
  }

  var i, len = encounters.length;
  for (i = 0; i < len; ++i) {
    if ( (new Date(encounters[i].encounterDatetime)) >= new Date(dateEnrolled) && encounters[i].encounterTypeUuid === encounterTypeUuid) {
      return true;
    }
  }
  return false;
}
