/*
    The goal of this function is to replace the standard orderWidget initialization javascript with one that
    renders lab orders as checkboxes and supports the same capabilities as the standalone lab orders page.  This supports 2 actions:
    1. If a lab has previously been ordered in the given encounter, it starts out checked.  Unchecking and saving will discontinue/void that order.
    2. If a lab has not been previously ordered in the given encounter, it starts out as non-checked.  Checking and saving will add a new order.
 */
function renderLabOrdersByCategory(config) {
    console.debug(config);

    const $widgetField = jq('#' + config.fieldName);
    var $orderSection = $widgetField.find(".orderwidget-order-section");

    config.concepts.forEach(function(concept, conceptIndex) {
        const fieldIndex = conceptIndex+1;
        const toggleField = "order_toggle_"  + fieldIndex;
        const toggleInput = jq(document.createElement("input")).prop({id: toggleField, name: toggleField, value: '', type: 'checkbox'});
        const actionField = config.widgets.action + '_'  + fieldIndex;
        const actionInput = jq(document.createElement("input")).prop({id: actionField, name: actionField, value: '', type: 'hidden'});
        const conceptField = config.widgets.concept + '_' + fieldIndex;
        const conceptInput = jq(document.createElement("input")).prop({id: conceptField, name: conceptField, value: concept.conceptId, type: 'hidden'});
        const urgencyField = config.widgets.urgency + '_'  + fieldIndex;
        const urgencyInput = jq(document.createElement("input")).prop({id: urgencyField, name: urgencyField, value: 'ROUTINE', type: 'hidden'});
        const careSettingField = config.widgets.careSetting + '_'  + fieldIndex;
        const careSettingInput = jq(document.createElement("input")).prop({id: careSettingField, name: careSettingField, value: 'OUTPATIENT', type: 'hidden'});
        const previousOrderField = config.widgets.previousOrder + '_'  + fieldIndex;
        const previousOrderInput = jq(document.createElement("input")).prop({id: previousOrderField, name: previousOrderField, type: 'hidden'});

        // Determine if there is already an existing order in the encounter for this concept
        let previousOrderId = null;
        config.history.forEach(function(order) {
            if (order.encounterId === config.encounterId && order.concept.value === concept.conceptId) {
                previousOrderId = order.orderId;
            }
        });

        const labSection = jq(document.createElement("div"));
        if (config.mode === 'VIEW') {
            const labValueSection = jq(document.createElement("span"));
            if (previousOrderId) {
                labValueSection.addClass("value").html("[X]&nbsp;" + concept.conceptLabel);
            }
            else {
                labValueSection.addClass("emptyValue").html("[&nbsp;&nbsp;]&nbsp;" + concept.conceptLabel);
            }
            labSection.append(labValueSection)
        }
        else {
            labSection.append(toggleInput);
            labSection.append(conceptInput).append(" " + concept.conceptLabel);
            labSection.append(actionInput);
            labSection.append(urgencyInput);
            labSection.append(careSettingInput);
            labSection.append(previousOrderInput);

            jq(actionInput).val('');
            if (previousOrderId) {
                jq(previousOrderInput).val(previousOrderId);
                jq(toggleInput).prop("checked", true);
            }

            jq(toggleInput).click(function(event) {
                if(jq(toggleInput).is(':checked')) {
                    if (previousOrderId) {
                        jq(actionInput).val('');
                    }
                    else {
                        jq(actionInput).val('NEW');
                    }
                }
                else {
                    if (previousOrderId) {
                        jq(actionInput).val('DISCONTINUE');
                    }
                    else {
                        jq(actionInput).val('');
                    }
                }
            });
        }
        $orderSection.append(labSection);
    });
}