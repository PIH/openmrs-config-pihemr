
// This finds previous womens health procedures but could be expanded for
// all procedures.

const whProcedurePerformed = "1651AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
const whProcedures = "57755670-c183-494b-bd5e-723e0978c3e3";
const whSterilizationProcedures = "46cbbdd9-9cc2-42c6-8ecb-4dbe6ea01354";

let procedures = [];
// retrieve all Sterilization procedures for females concept UUIDs
jq.getJSON(apiBaseUrl + "/concept" + "/" + whSterilizationProcedures, {
        v: 'custom:(id,uuid,display,setMembers:(id,uuid,display)'
    },
    function(data) {
        if (data &amp;&amp;data.setMembers.length > 0) {
            for (let index = 0; index &lt; data.setMembers.length; index++) {
                let procedure = data.setMembers[index];
                procedures.push(procedure.uuid);
            }
        }
        if (procedures.length > 0) {
            jq.getJSON(apiBaseUrl + "/obs", {
                    patient: patientUuid,
                    concept: whProcedurePerformed,
                    answers: procedures.join(),
                    v: 'custom:(uuid,display,obsDatetime,value:(uuid,display),concept:(uuid,display,name:(display))'
                },
                function(data) {
                    if (data.results.length > 0) {
                        jq("#whProceduresDiv").show();
                        for (let index = 0; index &lt; data.results.length; index++) {
                            let procPerformed = data.results[index];
                            jq("#whProceduresDiv ul").append('&lt;li&gt;').append(' - ').append(procPerformed.value.display).append(' on ').append(new Date(procPerformed.obsDatetime).toDateString()).append('&lt;/li&gt;');
                        }
                    }
                });
        }
    });

