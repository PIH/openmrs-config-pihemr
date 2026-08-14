function hideIfEmpty(selector) {
  jq(selector).find(".emptyValue").hide();
  jq(selector).each(function() {
    let numValues = jq(this).find(".value").length;
    if (numValues === 0) {
      jq(this).hide();
    }
  });
}
