function isPatientEnrolled(programs, programUuid) {
  return (typeof programs !== 'undefined') && programs && (
    some(programs, (function(program) {
      return program.programUuid === programUuid
    })));
}
