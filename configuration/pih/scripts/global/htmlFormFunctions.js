/**
 * Adds javascript functions for use within html forms
 * Requires jQuery and moment js
 */
class HtmlFormFunctions {

    constructor(pihemr, patientUuid, encounterUuid, encounterDateStr) {
        this.pihemr = pihemr;
        this.jq = pihemr.getJq();
        this.patientUuid = patientUuid;
        this.encounterUuid = encounterUuid;
        this.encounterDateStr = encounterDateStr;
    }

    getPatientUuid() {
        return this.patientUuid;
    }

    getEncounterUuid() {
        return this.encounterUuid;
    }

    getEncounterDateYmd() {
        let encDate = jq('#encounterDate').find('input[type="hidden"]').val();
        if (!encDate) {
            encDate = this.encounterDateStr;
        }
        if (!encDate) {
            encDate = moment().format('YYYY-MM-DD');
        }
        return encDate;
    }
}
