function isPatientEnrolledInProgramOfUuid(programUuid) {
  return (typeof activePrograms !== 'undefined') && activePrograms && (
    some(activePrograms, (function(program) {
      return program.programUuid === programUuid
    })));
}
