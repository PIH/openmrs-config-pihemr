
// This calculates the shows the estimated delivery date (edd) and gestational age (GA)

jq(function() {
    var encounterDate = '<lookup expression="encounter.getEncounterDatetime().getTime()" />';
    setUpEdd(encounterDate,'<uimessage code="pihcore.weeks" />');
    validateEstimatedDeliveryDate("lastPeriodDate", new Date(+encounterDate), '<uimessage code="pihcore.errors.lastPeriodDateField.invalidDate" />');
    validateEstimatedDeliveryDate("edd", new Date(+encounterDate), '<uimessage code="pihcore.errors.eddField.invalidDate" />');
    eddCannotBeOlderThanTwoWeeks("edd", new Date(+encounterDate), '<uimessage code="pihcore.errors.eddField.twoWeeksOlder" />');

    // handlers for next and submit buttons, see nextAndSubmitButtons.js
    setUpNextAndSubmitButtons();

    htmlForm.getBeforeValidation().push(function() {
        //SL-1279, Last menstruation date should not be more than 10 months in the past of the encounter date
        const lastPeriodElem = jq("#lastPeriodDate input[type='hidden']");
        if ( lastPeriodElem ) {
            const lastPeriodVal = lastPeriodElem.val();
            if ( lastPeriodVal ) {
                if ( daysBetweenUTCDates(new Date(lastPeriodVal), new Date(+encounterDate)) &gt; 305 ) {
                    jq(window).scrollTop(jq("#lastPeriodDate").offset().top - 100);
                    return false;
                }
            }
        }
        return true;
    });
});

jq(document).ready(function() {

    jq("#edd input[type='hidden']").change(function() {
        const estimatedDelivery = this.value;
        const estimatedDeliveryDate = new Date(estimatedDelivery);
        if ( estimatedDeliveryDate.getTime() &gt; currentEncounterDate.getTime() ) {
            // the estimated gestational age only makes sense if EDD is after the encounter time
            const daysDiff = daysBetweenUTCDates(estimatedDeliveryDate, currentEncounterDate);
            const diffWeeks = Math.floor( daysDiff / 7);
            const gestAgeRemainderDays = daysDiff % 7;
            const gestAge = diffWeeks + (gestAgeRemainderDays ? gestAgeRemainderDays / 10 : 0);
            const estGestAge = (40 - gestAge).toFixed(1);
            jq(".gestationalAge input[type='text']").val(estGestAge);
        }
    });

    jq(".gestationalAge input[type='text']").change(function() {
        const numValue = Number(this.value);
        if (isNaN(numValue)) {
            console.error("Gestational age must be a valid number");
            return;
        }
        // EDD = (40 weeks - current estimated gestational age in weeks) * 7 days * 24 hours * 60 minutes * 60 seconds * 1000ms
        const newEdd = new Date(currentEncounterDate.getTime() + (40 - numValue) * 7 * 24 * 60 * 60 * 1000);
        getField("edd.value").datepicker("setDate", newEdd);
    });
});
