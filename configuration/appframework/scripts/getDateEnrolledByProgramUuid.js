function getDateEnrolledByProgramUuid(list, programUuid) {
  if (!list) {
    return false;
  }
  var i, len = list.length;
  for (i = 0; i < len; ++i) {
    if (list[i]['programUuid'] === programUuid) {
      return list[i]['dateEnrolled'];
    }
  }
  return false;
}
