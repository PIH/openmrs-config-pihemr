function getDateEnrolledByProgramUuid(patientPrograms, programUuid) {
  if (!patientPrograms) {
    return false;
  }
  var i, len = patientPrograms.length;
  for (i = 0; i < len; ++i) {
    if (patientPrograms[i]['programUuid'] === programUuid) {
      return patientPrograms[i]['dateEnrolled'];
    }
  }
  return false;
}
