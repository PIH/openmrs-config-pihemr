function patientHasEncounterOfTypeDuringProgramEnrollment(patientPrograms, programUuid, encounters, encounterTypeUuid, visit) {

  if ( (typeof patientPrograms === 'undefined') || !patientPrograms || (typeof encounters === 'undefined') || !encounters) {
    return false;
  }

  var foundProgram = null;
  for ( var i = 0; i < patientPrograms.length ; ++i ) {
    if (( patientPrograms[i].programUuid === programUuid ) && visit
      && ( (new Date(visit.startDatetimeInMilliseconds)) >= ( new Date(patientPrograms[i].dateEnrolled)))
      && ( patientPrograms[i].dateCompleted == null || (new Date(patientPrograms[i].dateCompleted)) >= (new Date(visit.startDatetimeInMilliseconds))) ) {
      foundProgram = patientPrograms[i];
      break;
    }
  }

  if (foundProgram === null ) {
    return false;
  }
  //look for encounters of type encounterTypeUuid within (foundProgram.dateEnrolled <-> foundProgram.dateCompleted) timeframe
  for ( var j = 0; j < encounters.length; ++j ) {
    if ( encounters[j].encounterTypeUuid === encounterTypeUuid &&
      (new Date(encounters[j].encounterDatetime)) >= (new Date(foundProgram.dateEnrolled))
      && ( foundProgram.dateCompleted === null || (new Date(foundProgram.dateCompleted)) >= (new Date(encounters[j].encounterDatetime)) ) ) {
      return true;
    }
  }
  return false;
}
