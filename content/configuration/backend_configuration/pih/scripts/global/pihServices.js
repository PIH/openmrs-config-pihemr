/**
 * Adds javascript functions to the pihemr
 * Must be instantiated with jQuery instance
 */
class PihServices {

    constructor(jq) {
        this.jq = jq;
    }

    getJq() {
        return this.jq;
    }

    getContextPath() {
        return window.location.href.split('/')[3];
    }

    getApiBaseUrl() {
        return "/" + this.getContextPath() + "/ws/rest/v1";
    }

    getResourceUrl(resource) {
        return this.getApiBaseUrl() + "/" + resource;
    }

    /**
     * Returns a promise of concepts that match the passed conceptReferences, with the given representation
     * @param conceptReferences a comma-delimited string of uuids or mappings in source:code format
     * @param representation the object representation to return
     * @returns {Promise<*>}
     */
    async getConceptsByReferences(conceptReferences, representation) {
        let data = await jq.getJSON(this.getResourceUrl("concept"), {
            references: conceptReferences,
            v: representation
        });
        if (data.results) {
            return data.results;
        }
        return [];
    }

    /**
     * Returns a promise of an array of uuids for all concepts passed.  this will include the passed concepts, and if they are sets, the member concepts
     * @param conceptReferences a comma-delimited string of uuids or mappings in source:code format
     * @returns {Promise<*>}
     */
    async getUuidsOfConceptsAndSetMembers(conceptReferences) {
        let results = new Set();
        const concepts = await this.getConceptsByReferences(conceptReferences, 'custom:(id,uuid,setMembers:(uuid))');
        concepts.forEach(function(concept) {
            results.add(concept.uuid);
            if (concept.setMembers) {
                concept.setMembers.forEach(function (setMember) {
                    results.add(setMember.uuid);
                });
            }
        });
        return Array.from(results);
    }

    /**
     * Return promise of all conditions for the patient with the given uuid, and the given representation
     * @param patientUuid - the uuid of the patient
     * @param representation - the object representation to return
     * @returns {Promise<*>}
     * Example representation: custom:(uuid,display,clinicalStatus,onsetDate,endDate,encounter:(id,uuid),condition:(coded:(uuid)))
     */
    async getConditionsForPatient(patientUuid, representation) {
        let data = await jq.getJSON(this.getResourceUrl("condition"), {
            patientUuid: patientUuid,
            includeInactive: true,
            v: representation ?? 'full'
        });
        if (data.results) {
            return data.results;
        }
        return [];
    }

    /**
     * Return promise of all conditions for the patient that matches the given arguments
     * @param patientUuid - the uuid of the patient
     * @param clinicalStatus - if specified, will limit the results to only conditions with this status.  if null, does not limit
     * @param conceptReferences - a comma-delimited string of uuids or mappings in source:code format to restrict conditions to only those with a coded condition that matches these or a set member
     * @param representation - the object representation to return for each condition
     * @returns {Promise<*>}
     */
    async getMatchingConditions(patientUuid, clinicalStatus, conceptReferences, representation) {
        const status = clinicalStatus;
        const conditionsForPatient = await this.getConditionsForPatient(patientUuid, representation);
        const concepts = await this.getUuidsOfConceptsAndSetMembers(conceptReferences);
        let matches = [];
        conditionsForPatient.forEach(function(condition) {
            if (!status || status === condition.clinicalStatus) {
                const conditionCodedUuid = condition.condition?.coded?.uuid;
                if (!conceptReferences || (conditionCodedUuid && concepts.includes(conditionCodedUuid))) {
                    matches.push(condition);
                }
            }
        });
        return matches;
    }

    /**
     * @param condition the condition to check.  must have onsetDate, endDate, and clinicalStatus fields
     * @param dateYmd the date to check in YYYY-MM-DD format
     * @returns {boolean} if the condition is considered active on the given date
     */
    isConditionActiveOnDate(condition, dateYmd) {
        let onsetDateYmd = !condition.onsetDate ? null : condition.onsetDate.substring(0, 10);
        let endDateYmd = !condition.endDate ? null : condition.endDate.substring(0, 10);
        if (onsetDateYmd) {
            if (endDateYmd) {
                return onsetDateYmd <= dateYmd && endDateYmd >= dateYmd;
            }
            else {
                return onsetDateYmd <= dateYmd;
            }
        }
        else {
            if (endDateYmd) {
                return endDateYmd >= dateYmd;
            }
            else {
                return (condition.clinicalStatus === 'ACTIVE');
            }
        }
    }
}