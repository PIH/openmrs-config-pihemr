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

    async showSectionBasedOnCondition(conceptOrSet, sectionSelector, showIfActive, showIfInactive, showIfInEncounter) {
        const encDateYmd = this.getEncounterDateYmd();
        const conditionRep = 'custom:(uuid,display,clinicalStatus,onsetDate,endDate,encounter:(id,uuid),condition:(coded:(uuid)))';
        await this.pihemr.getMatchingConditions(this.patientUuid, null, conceptOrSet, conditionRep).then(matchingConditions => {
            let foundInEncounter = false;
            let foundActiveAtEncounter = false;
            let hfe = this;
            matchingConditions.forEach(function(condition) {
                if (hfe.encounterUuid && hfe.encounterUuid === condition?.encounter?.uuid) {
                    foundInEncounter = true;
                }
                if (hfe.pihemr.isConditionActiveOnDate(condition, encDateYmd)) {
                    foundActiveAtEncounter = true;
                }
            });
            if ((foundActiveAtEncounter && showIfActive) || (!foundActiveAtEncounter && showIfInactive) || (foundInEncounter && showIfInEncounter)) {
                jq(sectionSelector).show();
            }
        });
    }
}
