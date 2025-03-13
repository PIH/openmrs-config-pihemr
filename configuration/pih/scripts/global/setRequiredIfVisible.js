
function setRequiredIfVisible(obs_field_id) {
  const element = jq("#" + obs_field_id);
  const isVisible = jq(element).is(":visible");
  const value = getValue(obs_field_id + ".value");
  if (isVisible && !value) {
    jq(element).parent().find('.field-error').css('display', 'inline-block').text('*Required').show();
    return false;
  }
  else {
    jq(element).parent().find('.field-error').text('').hide();
    return true;
  }
}
