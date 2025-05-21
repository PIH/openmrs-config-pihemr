function patientHasEncounterOfTypeDuringProgramEnrollment(encounterTypeUuid, programUuid) {

  var isPatientEnrolled = isPatientEnrolledInProgramOfUuid(programUuid);
  if ( !isPatientEnrolled ) {
    return false;
  }
  return isPatientEnrolledInProgramOfUuid(programUuid) && encounterOfTypeAfterDate(encounters, encounterTypeUuid, getDateEnrolledByProgramUuid(activePrograms, programUuid));
}
