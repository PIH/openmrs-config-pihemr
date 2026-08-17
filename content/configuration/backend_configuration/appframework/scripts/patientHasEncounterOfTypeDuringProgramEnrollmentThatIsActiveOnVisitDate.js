//This function searches of encounter of given type that are recorded during the program enrollment that is active during the visit date
function patientHasEncounterOfTypeDuringProgramEnrollmentThatIsActiveOnVisitDate(patientPrograms, programUuid, encounters, encounterTypeUuid, visit) {

  if ( (typeof patientPrograms === 'undefined') || !patientPrograms || (typeof encounters === 'undefined') || !encounters || (typeof visit === 'undefined') || !visit ) {
    return false;
  }

  var visitStart = new Date(visit.startDatetimeInMilliseconds);
  var visitEnd = visit.stopDatetime == null ? new Date() : new Date(visit.stopDatetimeInMilliseconds);
  var foundProgram = null;
  //look for program enrollment with the given program type uuid that is active as of the given visit date
  for ( var i = 0; i < patientPrograms.length ; ++i ) {
    var programEnrollmentDate = new Date(patientPrograms[i].dateEnrolled);
    var programCompletionDate = patientPrograms[i].dateCompleted == null ? null : (new Date(patientPrograms[i].dateCompleted));
    if ( ( patientPrograms[i].programUuid === programUuid ) && programEnrollmentDate <= visitEnd && (programCompletionDate == null || programCompletionDate > visitStart) ) {
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
