function patientHasEncounterOfTypeDuringProgramEnrollment(programs, encounterTypeUuid, programUuid) {

  var patientEnrolled = isPatientEnrolled(programs, programUuid);
  if ( !patientEnrolled ) {
    return false;
  }
  var dateEnrolled = getDateEnrolledByProgramUuid(programs, programUuid);
  if ( !dateEnrolled ) {
    return false;
  }
  return encounterOfTypeAfterOrOnDate(encounters, encounterTypeUuid, dateEnrolled);
}
