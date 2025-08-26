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

const yesValue = "1";
const noValue = "2";

function dateFromString(dateString) {
  var returnDate = null;
  //the dateString is a string with the following format YYYY-MM-DD
  if (dateString) {
    const returnDate = new Date(dateString);
    let yearMonthDay = dateString.split('-');
    if (yearMonthDay.length == 3) {
      returnDate.setFullYear(yearMonthDay[0]);
      returnDate.setMonth(+yearMonthDay[1] - 1); // the month starts from 0 for January
      returnDate.setDate(yearMonthDay[2]);
      returnDate.setHours(0, 0, 0);
    }
    return returnDate;
  }
}

function isPatientPregnant() {
  var returnValue = true; // If Patient pregnant question is not present on the form, or visible then use the LMP field to calculate the EDD
  const pregnantQuestion = jq("#isPatientPregnant");
  if (pregnantQuestion && jq(pregnantQuestion).is(":visible")) {
    const isPatientPregnant = jq("#isPatientPregnant input[type='radio']:checked").val();
    if (isPatientPregnant === yesValue) {
      returnValue = true;
    } else {
      returnValue = false;
    }
  }
  return returnValue;
}
function setUpEdd(currentEncounterDate, msgWeeks) {
  var encObsEdd = getField("edd.value") != null ? getField("edd.value").val() : null; // the encounter already has an EDD obs value
  var encFollowUpObsEdd = getField("obgyn_initial_previous_edd.value") != null ? getField("obgyn_initial_previous_edd.value").val() : null;
  var encObsGestagionalAge = getField("gestationalAge.value") != null ? getField("gestationalAge.value").val() : null; // the encounter already has a Gestational Age obs value
  var encFollowUpObsGestagionalAge = getField("followUpGestationalAge.value") != null ? getField("followUpGestationalAge.value").val() : null;

  function updateEdd() {
    const lastPeriodDateValue = htmlForm.getValueIfLegal("lastPeriodDate.value");
    //the lastPerioDate is a string with the following format YYYY-MM-DD
    if (lastPeriodDateValue && isPatientPregnant()) {
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
      if (!encObsEdd && !encFollowUpObsEdd) {
        getField("edd.value").datepicker("setDate", edd);
      }
      jq(".calculated-edd").text((Intl.DateTimeFormat(locale, { dateStyle: "medium" })).format(edd));
      if (!encObsGestagionalAge && !encFollowUpObsGestagionalAge && getField("gestationalAge.value")) {
        getField("gestationalAge.value").val(gestAgeText);
      }
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

function validateEstimatedDeliveryDate(fieldId, encounterDate, errorMessage) {
  if ( fieldId && encounterDate) {
    jq("#" + fieldId + " input[type='hidden']").change(function () {
      htmlForm.enableSubmitButton();
      jq("#" + fieldId + " .field-error").text('');
      jq("#" + fieldId + " .field-error").hide();
      const estimatedDelivery = this.value;
      //the deliveryDate is a string with the following format YYYY-MM-DD
      if ( estimatedDelivery ) {
        const deliveryDate = new Date(estimatedDelivery);
        if ( deliveryDate ) {
          // UHM-8643: Estimated Delivery Date should not be greater than 10 months from encounter date
          var daysBetween = daysBetweenUTCDates(deliveryDate, encounterDate);
          if ( daysBetween > 305 ) {
            jq("#" + fieldId + " .field-error").text(errorMessage).show();
            htmlForm.disableSubmitButton();
          }
        }
      }
    });
  }
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
  return gestAgeWeeks + (gestAgeRemainderDays ? gestAgeRemainderDays / 10 : 0) ;
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
function setUpGestationalAgeAtBirth(lastPeriodDateValue, msgWeeks) {
  function updateGestationalAge() {
    if (lastPeriodDateValue) {
      const lastPeriodDate = new Date(parseInt(lastPeriodDateValue));
      jq("#calculated-edd-wrapper").show();
      const deliveryDateValue = htmlForm.getValueIfLegal("deliveryDate.value.date");
      if (deliveryDateValue) {
        const deliveryDate = new Date(deliveryDateValue);
        const gestAgeMs = deliveryDate.getTime() - lastPeriodDate.getTime();
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

function daysBetweenUTCDates(date1, date2) {
  const date1UTC = Date.UTC(date1.getFullYear(), date1.getMonth(), date1.getDate());
  const date2UTC = Date.UTC(date2.getFullYear(), date2.getMonth(), date2.getDate());
  const timeDiff = Math.abs(date2UTC - date1UTC);
  const daysDiff = Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
  return daysDiff;
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
      jq('#pregnancyDiv').show();
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


