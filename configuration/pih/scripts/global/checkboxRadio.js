function setupCheckboxRadioGroups() {
  jq(".checkbox-radio-group").each(function(groupIndex, groupElement) {
    const options = jq(groupElement).find(".checkbox-radio-option");
    jq(options).each(function(index1, option1) {
      const checkbox = jq(option1).find("input:checkbox");
      jq(checkbox).change(function(event) {
        if(jq(checkbox).is(":checked")) {
          jq(options).each(function(index2, option2) {
            if (index1 !== index2) {
              jq(option2).find("input:checkbox").prop("checked", false);
            }
          });
        }
      });
    });
  });
}
