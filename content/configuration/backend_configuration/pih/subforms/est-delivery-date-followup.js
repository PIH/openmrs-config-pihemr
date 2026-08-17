
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
        <lookup complexExpression="#set( $lmpObs = $fn.latestObsBeforeCurrentEncounter('CIEL:1427', false) )"/>
        const lastLMP = '<lookup complexExpression="#if($lmpObs)$!{fn.formatDate($lmpObs.getValueDatetime(), 'yyyy-MM-dd')}#end"/>';

        if ( lastLMP ) {

            const lastLMPrecordedDate = '<lookup complexExpression="#if($lmpObs)$!{fn.formatDate($lmpObs.obsDatetime, 'yyyy-MM-dd')}#end"/>';
            const lastLMPformName = '<lookup complexExpression="#if($lmpObs)$!{lmpObs.encounter.form.name}#end"/>';
            const lastLMPencLocation = '<lookup complexExpression="#if($lmpObs)$!{lmpObs.encounter.location.name}#end"/>';
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
            <lookup complexExpression="#set( $gaObs = $fn.latestObsBeforeCurrentEncounter('CIEL:1438', false) )"/>
            const lastGA = '<lookup complexExpression="#if($gaObs)$!{gaObs.getValueNumeric()}#end"/>';
            if (lastGA) {
                jq("#lastGACaption").removeClass("hidden");
                const lastGArecordedDate = '<lookup complexExpression="#if($gaObs)$!{fn.formatDate($gaObs.obsDatetime, 'yyyy-MM-dd')}#end"/>';
                const lastGAformName = '<lookup complexExpression="#if($gaObs)$!{gaObs.encounter.form.name}#end"/>';
                const lastGAencLocation = '<lookup complexExpression="#if($gaObs)$!{gaObs.encounter.location.name}#end"/>';
                jq("#lastGAValue").text(lastGA);
                jq("#lastGAFormName").text(lastGAformName);
                jq("#lastGAobsDateTime").text(lastGArecordedDate);
                jq("#lastGAencLocation").text(lastGAencLocation);
            }
        }

        var encObsEdd = getField("edd.value") != null ? getField("edd.value").val() : null; // the encounter already has an EDD obs value
        if ( !encObsEdd ) {
            <lookup complexExpression="#set( $eddObs = $fn.latestObsBeforeCurrentEncounter('CIEL:5596', false) )"/>
            const lastEDD = '<lookup complexExpression="#if($eddObs)$!{fn.formatDate($eddObs.getValueDatetime(), 'yyyy-MM-dd')}#end"/>';
            const lastEnteredEDD = '<lookup complexExpression="#if($eddObs)$!{fn.formatDate($eddObs.obsDatetime, 'yyyy-MM-dd')}#end"/>';
            const lastEDDformName = '<lookup complexExpression="#if($eddObs)$!{eddObs.encounter.form.name}#end"/>';
            const lastEDDencLocation = '<lookup complexExpression="#if($eddObs)$!{eddObs.encounter.location.name}#end"/>';
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
