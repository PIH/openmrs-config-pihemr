function daysBetweenUTCDates(date1, date2) {
    const date1UTC = Date.UTC(date1.getFullYear(), date1.getMonth(), date1.getDate());
    const date2UTC = Date.UTC(date2.getFullYear(), date2.getMonth(), date2.getDate());
    const timeDiff = Math.abs(date2UTC - date1UTC);
    const daysDiff = Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
    return daysDiff;
}
/**
 * takes lastPeriodDate:Date as input, returns Date as output
 */
function calculateExpectedDeliveryDate(lastPeriodDate) {
    const date = new Date(lastPeriodDate);
    // EDD = LMP + 280 days (40 weeks). An exact 280-day offset is used, rather than the
    // calendar-based Naegele rule (+1 year -3 months +7 days, which varies 279-282 days),
    // so this stays consistent with the gestational-age calculations that assume 40 weeks
    // = 280 days. setDate() advances the calendar date, keeping the result at local midnight
    // (DST-safe) and handling month/year rollover.
    date.setDate(date.getDate() + 280);
    return date;
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
    return gestAgeWeeks +
        " " +
        (gestAgeRemainderDays ? gestAgeRemainderDays + "/7 " : " ") +
        msgWeeks;
}

function calculateEddFromGA(gestationalAgeValue, currentEncounterDate) {
    if (isNaN(gestationalAgeValue)) {
        console.error("Gestational age must be a valid number");
        return;
    }
    // The gestational age is stored in weeks.days notation (e.g. 25.5 = 25 weeks 5 days),
    // so convert it to days before computing days remaining, to stay consistent with the
    // EDD -> gestational age calculation above.
    const gestAgeWeeks = Math.floor(gestationalAgeValue);
    const gestAgeRemainderDays = Math.round((gestationalAgeValue - gestAgeWeeks) * 10);
    const gestAgeDays = gestAgeWeeks * 7 + gestAgeRemainderDays;
    // EDD = encounter date + days remaining until 40 weeks (280 days) is reached
    const daysRemaining = 280 - gestAgeDays;
    const newEdd = new Date(currentEncounterDate.getTime() + daysRemaining * 24 * 60 * 60 * 1000);
    return newEdd;
}

function calculateEddFromLmp(lastPeriodDateValue) {
    var edd = null;
    if (lastPeriodDateValue) {
        const lastPeriodDate = dateFromString(lastPeriodDateValue);
        let yearMonthDay = lastPeriodDateValue.split('-');
        if (yearMonthDay.length == 3) {
            lastPeriodDate.setFullYear(yearMonthDay[0]);
            lastPeriodDate.setMonth(+yearMonthDay[1] - 1); // the month starts from 0 for January
            lastPeriodDate.setDate(yearMonthDay[2]);
            lastPeriodDate.setHours(0, 0, 0);
        }
        edd = calculateExpectedDeliveryDate(lastPeriodDate);
    }
    return edd;
}

function validateEstimatedDeliveryDate(fieldId, encounterDate, errorMessage) {
    if (fieldId &amp;&amp; encounterDate) {
        jq("#" + fieldId + " input[type='hidden']").change(function () {
            htmlForm.enableSubmitButton();
            jq("#" + fieldId + " .field-error").text('');
            jq("#" + fieldId + " .field-error").hide();
            const estimatedDelivery = this.value;
            //the deliveryDate is a string with the following format YYYY-MM-DD
            if (estimatedDelivery) {
                const deliveryDate = new Date(estimatedDelivery);
                if (deliveryDate) {
                    // UHM-8643: Estimated Delivery Date should not be greater than 10 months from encounter date
                    var daysBetween = daysBetweenUTCDates(deliveryDate, encounterDate);
                    if (daysBetween &gt;= 305) {
                        jq("#" + fieldId + " .field-error").text(errorMessage).show();
                        htmlForm.disableSubmitButton();
                    }
                }
            }
        });
    }
}