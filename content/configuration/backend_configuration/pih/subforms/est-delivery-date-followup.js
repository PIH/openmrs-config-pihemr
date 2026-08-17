
// This calculates the shows the estimated delivery date (edd) and gestational age (GA)
jq(document).ready(function() {

    const encounterDate = '<lookup expression="encounter.getEncounterDatetime().getTime()"/>';
    var currentEncounterDate = new Date();

    if (typeof encounterDate !== "undefined" &amp;&amp; encounterDate !== null &amp;&amp; (encounterDate.length > 0)) {
        currentEncounterDate = new Date(+encounterDate);
    } else {
        // look for the encounterDate datepicker widget
        var encounterDateValue = jq("#encounterDate .hasDatepicker");
        if (encounterDateValue) {
            var getDate = encounterDateValue.datepicker('getDate');
            if (getDate) {
                currentEncounterDate = new Date(getDate);
            }
        }
    }

    const locale = (window.sessionContext &amp;&amp; window.sessionContext.locale) || navigator.language;
    jq("#visitDateDisplay").text((Intl.DateTimeFormat(locale, { dateStyle: "medium" })).format(currentEncounterDate));
    <ifMode mode="VIEW" include="false">
        const lastLMP = '<lookup complexExpression="$fn.formatDate($fn.latestObsBeforeCurrentEncounter('CIEL:1427', false).getValueDatetime(), 'yyyy-MM-dd')"/>';

        if ( lastLMP ) {
            const lastLMPrecordedDate = '<lookup complexExpression="$fn.formatDate($fn.latestObsBeforeCurrentEncounter('CIEL:1427', false).obsDatetime, 'yyyy-MM-dd')"/>';
            const lastLMPformName = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:1427', false).encounter.form.name"/>';
            const lastLMPencLocation = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:1427', false).encounter.location.name"/>';
            const lastLMPDate = new Date(lastLMP);
            var daysBetween = daysBetweenUTCDates(currentEncounterDate, lastLMPDate);
            if (daysBetween &lt;= 305) {
                // SL-1279: The last menstruation date should not be more than 10 months in the past of the encounter date
                jq("#lastPeriodDateGroup").removeClass("hidden");
                jq("#lastLMPCaption").removeClass("hidden");
                jq("#lastPeriodDateValue").text(lastLMP);
                jq("#lastLMPFormName").text(lastLMPformName);
                jq("#lastLMPobsDateTime").text(lastLMPrecordedDate);
                jq("#lastLMPencLocation").text(lastLMPencLocation);
            }
        }

        var encObsGA = getField("estimatedGestationalAge.value") != null ? getField("estimatedGestationalAge.value").val() : null; // the encounter already has an GA obs value
        if ( ! encObsGA ) {
            const lastGA = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:1438', false).getValueNumeric()"/>';
            if (lastGA) {
                jq("#lastGACaption").removeClass("hidden");
                const lastGArecordedDate = '<lookup complexExpression="$fn.formatDate($fn.latestObsBeforeCurrentEncounter('CIEL:1438', false).obsDatetime, 'yyyy-MM-dd')"/>';
                const lastGAformName = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:1438', false).encounter.form.name"/>';
                const lastGAencLocation = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:1438', false).encounter.location.name"/>';
                jq("#lastGAValue").text(lastGA);
                jq("#lastGAFormName").text(lastGAformName);
                jq("#lastGAobsDateTime").text(lastGArecordedDate);
                jq("#lastGAencLocation").text(lastGAencLocation);
            }
        }

        var encObsEdd = getField("edd.value") != null ? getField("edd.value").val() : null; // the encounter already has an EDD obs value
        if ( !encObsEdd ) {
            const lastEDD = '<lookup complexExpression="$fn.formatDate($fn.latestObsBeforeCurrentEncounter('CIEL:5596', false).getValueDatetime(), 'yyyy-MM-dd')"/>';
            const lastEnteredEDD = '<lookup complexExpression="$fn.formatDate($fn.latestObsBeforeCurrentEncounter('CIEL:5596', false).obsDatetime, 'yyyy-MM-dd')"/>';
            const lastEDDformName = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:5596', false).encounter.form.name"/>';
            const lastEDDencLocation = '<lookup complexExpression="$fn.latestObsBeforeCurrentEncounter('CIEL:5596', false).encounter.location.name"/>';
            if (lastEDD) {
                // UHM-8643: Estimated Delivery Date should not be greater than 10 months from encounter date
                const deliveryDate = dateFromString(lastEDD);
                if (deliveryDate) {
                    var daysBetween = daysBetweenUTCDates(deliveryDate, currentEncounterDate);
                    if (daysBetween &lt;= 305) {
                        //valid EDD - display EDD
                        if (getField("edd.value")) {
                            getField("edd.value").datepicker("setDate", deliveryDate);
                            jq("#lastEDDCaption").removeClass("hidden");
                            jq("#lastEDDValue").text(lastEDD);
                            jq("#lastEDDFormName").text(lastEDDformName);
                            jq("#lastEDDobsDateTime").text(lastEnteredEDD);
                            jq("#lastEDDencLocation").text(lastEDDencLocation);
                        }
                    }
                }
            }
        }
        validateEstimatedDeliveryDate("edd", currentEncounterDate, '<uimessage code="pihcore.errors.eddField.invalidDate" />');

        jq("#gestationalAge input[type='text']").change(function() {
            const numValue = Number(this.value);
            const newEdd = calculateEddFromGA(numValue, currentEncounterDate);
            if (newEdd) {
                getField("edd.value").datepicker("setDate", newEdd);
            }
        });
    </ifMode>
});
