function patientHasEncounterOfTypeDuringProgramEnrollment(encounterTypeUuid, programUuid) {

  var isPatientEnrolled = isPatientEnrolled(programUuid);
  if ( !isPatientEnrolled ) {
    return false;
  }
  return encounterOfTypeAfterDate(encounters, encounterTypeUuid, getDateEnrolledByProgramUuid(activePrograms, programUuid));
}
