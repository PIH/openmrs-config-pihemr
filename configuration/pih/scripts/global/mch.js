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
    //the lastPerioDate is a string with the following format YYYY-MM-DD
    if (lastPeriodDateValue) {
      const lastPeriodDate = new Date(lastPeriodDateValue);
      let yearMonthDay = lastPeriodDateValue.split('-');
      if (yearMonthDay.length == 3) {
        lastPeriodDate.setFullYear(yearMonthDay[0]);
        lastPeriodDate.setMonth(+yearMonthDay[1] - 1); // the month starts from 0 for January
        lastPeriodDate.setDate(yearMonthDay[2]);
        lastPeriodDate.setHours(0, 0, 0);
      }

      const gestAgeText = calculateGestationalDays(lastPeriodDate, currentEncounterDate, msgWeeks);
      const edd = calculateExpectedDeliveryDate(lastPeriodDate);
      const locale = window.sessionContext.locale || navigator.language;
      jq(".calculated-edd-and-gestational").show();
      getField("edd.value").datepicker("setDate", edd);
      jq(".calculated-edd").text((Intl.DateTimeFormat(locale, { dateStyle: "medium" })).format(edd));
      jq(".calculated-gestational-age-value").text(gestAgeText);
    } else {
      jq(".calculated-edd-and-gestational").hide();
    }
  };

  jq(".calculated-edd-and-gestational").hide();
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
jq(document).ready(function () {

  // Check if the URL contains the specified parameter
  const urlContainsParam = window.location.href.includes('editHtmlFormWithStandardUi.page');
  if (urlContainsParam) {
    // Iterate through each collapsible-content element
    jq('.collapsible-content').each(function () {
      const content = jq(this);
      // Check if any checkboxes inside are checked
      if (content.find('input[type="checkbox"]:checked').length > 0) {
        content.addClass('open'); // Add the open class
        content.css('max-height', content[0].scrollHeight + 'px'); // Dynamically set max-height
      }
    });
  }
  jq('.toggle-div').on('click', function () {
    const content = jq(this).next('.collapsible-content');
    content.toggleClass('open');
    // content.css('max-height', content.hasClass('open') ? content[0].scrollHeight + 'px' : '0');
  });


  // This is a function that wii hide or show other inputs and make them required based on the selected choice
  function checkRadioSelectionPeriod() {
    const selectedIndex = $('#knowing_period_question input[type="radio"]').index($('#knowing_period_question input[type="radio"]:checked'));

    if (selectedIndex === 0) {
      jq('#lastPeriod').show();
      jq('#lastPeriod input[type="text"]').attr('required', true);
      jq('#trimesterAtEnrollment input[type="radio"]').attr('required', true);
      jq('#trimesterAtEnrollment').show();
      jq('#trimesterAtEnrollment_label').show();
    } else {
      jq('#lastPeriod').hide();
      jq('#lastPeriod input[type="text"]').removeAttr('required');
      jq('#trimesterAtEnrollment input[type="radio"]').removeAttr('required');
      jq('#trimesterAtEnrollment').hide();
      jq('#trimesterAtEnrollment_label').hide();

    }
  }
  jq('#baby-live-or-death-1 input[type="radio"]').attr('required', true)
  jq('#delivery-type-1 input[type="radio"]').attr('required', true)


  function checkRadioSelectionBirthType() {
    const typeOfBirthIndex = $('#baby-live-or-death-1 input[type="radio').index($('#baby-live-or-death-1 input[type="radio"]:checked'));
    if (typeOfBirthIndex === 0) {

      $('#gender_weight input[type="radio"]:first').attr('required', true);

      $('#gender_weight input[type="text"]:first').attr('required', true);
    } else {
      $('#gender_weight input[type="radio"]:first').attr('required', false);

      $('#gender_weight input[type="text"]:first').attr('required', false);
    }
  }

  jq('#knowing_period_question input[type="radio"]').on('change', checkRadioSelectionPeriod);
  jq('#baby-live-or-death-1 input[type="radio"]').on('change', checkRadioSelectionBirthType);

  checkRadioSelectionPeriod();


});


