/*
 * We intentionally only allow for entering appointment when in ENTER mode. In edit mode, the appointment fields are disabled
 */
if (jq('#appointment-edit-mode').length) {
    jq(document).ready(function() {
        jq('#schedule-appointment input[type="radio"]').prop('disabled', true);
        jq('#schedule-appointment-fields input, #schedule-appointment-fields select, #schedule-appointment-fields textarea').prop('disabled', true);
    });
}

/*
 * Add frontend validation of the appointment fields. They are conditionally required only when the user sets "Schdeule Appointment" to "yes"
 */

function validateAppointmentField(divId, getValue) {
    var div = jq('#' + divId);
    var errorSpan = div.find('.field-error').first();
    if (!getValue(div)) {
        errorSpan.text('Required').show();
        return false;
    }
    errorSpan.hide();
    return true;
}

beforeSubmit.push(function() {
    if (!jq('#schedule-appointment-fields').is(':visible')) {
        return true;
    }
    var valid = true;
    valid = validateAppointmentField('appointment-datetime-field', function(div) {
        return div.find('input[type="text"]').first().val();
    }) &amp;&amp; valid;
    valid = validateAppointmentField('appointment-location-field', function(div) {
        return div.find('select').first().val();
    }) &amp;&amp; valid;
    valid = validateAppointmentField('appointment-service-field', function(div) {
        return div.find('select').first().val();
    }) &amp;&amp; valid;
valid = validateAppointmentField('appointment-provider-field', function(div) {
        return div.find('input.autoCompleteHidden').first().val();
    }) &amp;&amp; valid;
    return valid;
});

// clear errors as user fills each field
jq('#appointment-datetime-field input[type="text"]').first().on('change', function() {
    jq('#appointment-datetime-field .field-error').first().hide();
});
jq('#appointment-location-field select').on('change', function() {
    jq('#appointment-location-field .field-error').first().hide();
});
jq('#appointment-service-field select').on('change', function() {
    jq('#appointment-service-field .field-error').first().hide();
});
jq('#appointment-provider-field input[type="text"]').on('change', function() {
    jq('#appointment-provider-field .field-error').first().hide();
});
