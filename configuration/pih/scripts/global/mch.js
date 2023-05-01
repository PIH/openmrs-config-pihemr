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
      const gestAgeText = calculateGestationalDays(lastPeriodDate, currentEncounterDate, msgWeeks);
      const edd = calculateExpectedDeliveryDate(lastPeriodDate);
      const locale = window.sessionContext.locale || navigator.language;
      jq("#calculated-edd-and-gestational").show();
      getField("edd.value").datepicker("setDate", edd);
      jq("#calculated-edd").text((Intl.DateTimeFormat(locale, { dateStyle: "medium" })).format(edd));
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

/**
 * return a string representation of the gestational age as of the passed currentEncounterDate
 */
function calculateGestationalDays(lastPeriodDate, currentEncounterDate, msgWeeks) {
  const today = currentEncounterDate ? new Date(+currentEncounterDate) : new Date();
  const gestAgeMs = today.getTime() - lastPeriodDate.getTime();
  const gestAgeDays = Math.floor(gestAgeMs / (1000 * 3600 * 24))
  const gestAgeWeeks = Math.floor(gestAgeDays / 7);
  const gestAgeRemainderDays = gestAgeDays % 7;
  return gestAgeWeeks + " " + (gestAgeRemainderDays ? gestAgeRemainderDays + "/7 " : " ") + msgWeeks;
}

/**
 * takes lastPeriodDate:Date as input, returns Date as output
 */
function calculateExpectedDeliveryDate(lastPeriodDate) {
  return new Date(lastPeriodDate.getTime() + 1000 * 60 * 60 * 24 * 280);
}

/**
 * 
 * This is for showing the calculated gestational age at birth,
 * for the delivery form.
 * 
 * @param {Date} lastPeriodDate 
 */
function setUpGestationalAgeAtBirth(lastPeriodDate) {
  function updateGestationalAge() {
    if (lastPeriodDate) {
      jq("#calculated-edd-wrapper").show();
      const deliveryDateValue = htmlForm.getValueIfLegal("deliveryDate.value");
      if (deliveryDateValue) {
        const gestAgeMs = deliveryDateValue.getTime() - lastPeriodDate.getTime();
        const gestAgeDays = Math.floor(gestAgeMs / (1000 * 3600 * 24))
        const gestAgeWeeks = Math.floor(gestAgeDays / 7);
        const gestAgeRemainderDays = gestAgeDays % 7;
        jq("#calculated-gestational").show();
        const gestAgeText = gestAgeWeeks + " " +
          (gestAgeRemainderDays ? gestAgeRemainderDays + "/7 " : " ") +
          msgWeeks;
        jq("#calculated-gestational-age-value").text(gestAgeText);
      } else {
        jq("#calculated-gestational").hide();
      }
    } else {
      jq("#calculated-edd-wrapper").hide();
    }
  };

  jq("#calculated-gestational").hide();

  jq("#deliveryDate").change(function () {
    updateGestationalAge();
  });

  updateGestationalAge();
}
