/**
 * Expects date-type `obs` with IDs
 *   - `lastPeriodDate`
 *   - `edd`
 * Expects DOM elements with IDs
 *   - `calculated-edd-and-gestational`
 *   - `calculated-edd`
 *   - `calculated-gestational-age-value`
 * 
 * Typical usage:
 * 
 * ```
 * jq(function() {
 *   setUpEdd(
 *     '<lookup expression="encounter.getEncounterDatetime().getTime()"/>',
 *     '<uimessage code="pihcore.weeks"/>'
 *   );
 * });
 */
function setUpEdd(currentEncounterDate, msgWeeks) {
  function updateEdd() {
    const lastPeriodDateValue = htmlForm.getValueIfLegal("lastPeriodDate.value");
    if (lastPeriodDateValue) {
      const lastPeriodDate = new Date(lastPeriodDateValue);
      const today = currentEncounterDate ? new Date(+currentEncounterDate) : new Date();
      const gestAgeMs = today.getTime() - lastPeriodDate.getTime();
      const gestAgeDays = Math.floor(gestAgeMs / (1000 * 3600 * 24))
      const gestAgeWeeks = Math.floor(gestAgeDays / 7);
      const gestAgeRemainderDays = gestAgeDays % 7;
      const locale = window.sessionContext.locale || navigator.language;
      const edd = new Date(lastPeriodDate.getTime() + 1000 * 60 * 60 * 24 * 280);
      jq("#calculated-edd-and-gestational").show();
      getField("edd.value").datepicker("setDate", edd);
      jq("#calculated-edd").text((Intl.DateTimeFormat(locale, { dateStyle: "full" })).format(edd));
      const gestAgeText = gestAgeWeeks + " " +
        (gestAgeRemainderDays ? gestAgeRemainderDays + "/7 " : " ") +
        msgWeeks;
      jq("#calculated-gestational-age-value").text(gestAgeText);
    } else {
      jq("#calculated-edd-and-gestational").hide();
    }
  };

  jq("#calculated-edd-and-gestational").hide();
  jq("#lastPeriodDate input[type='hidden']").change(function () {
    updateEdd();
  });

  updateEdd();
}

function setUpNextButtonForSections(currentSection) {
  jq("#next").click(function () {
    window.htmlForm.getBeforeSubmit().push(function () {
      window.htmlForm.setReturnUrl(
        window.htmlForm.getReturnUrl() + "&amp;goToNextSection=" + currentSection
      );
      return true;
    });

    window.htmlForm.submitHtmlForm();
  });

  jq("#submit").click(function () {
    window.htmlForm.submitHtmlForm();
  });
}