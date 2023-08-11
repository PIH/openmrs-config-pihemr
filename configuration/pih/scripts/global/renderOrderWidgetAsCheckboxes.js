/*
    The goal of this function is to replace the standard orderWidget initialization javascript with one that
    renders lab orders as checkboxes.  This supports 2 actions:
    1. If a lab has previously been ordered in the given encounter, it starts out checked.  Unchecking and saving will discontinue/void that order.
    2. If a lab has not been previously ordered in the given encounter, it starts out as non-checked.  Checking and saving will add a new order.
    This hard-codes the order attributes of careSetting = OUTPATIENT, urgency = ROUTINE.  It does not use those values configured in the template,
    though this is something that could be improved upon if desired.
 */
function renderOrderWidgetAsCheckboxes(config) {
    console.debug(config);

    let $widgetField = $('#' + config.fieldName);
    var $orderSection = $widgetField.find(".orderwidget-order-section");

    config.concepts.forEach(function(concept, conceptIndex) {
        let fieldIndex = conceptIndex+1;
        let toggleField = "order_toggle_"  + fieldIndex;
        let toggleInput = $(document.createElement("input")).prop({id: toggleField, name: toggleField, value: '', type: 'checkbox'});
        let actionField = config.widgets.action + '_'  + fieldIndex;
        let actionInput = $(document.createElement("input")).prop({id: actionField, name: actionField, value: '', type: 'hidden'});
        let conceptField = config.widgets.concept + '_' + fieldIndex;
        let conceptInput = $(document.createElement("input")).prop({id: conceptField, name: conceptField, value: concept.conceptId, type: 'hidden'});
        let urgencyField = config.widgets.urgency + '_'  + fieldIndex;
        let urgencyInput = $(document.createElement("input")).prop({id: urgencyField, name: urgencyField, value: 'ROUTINE', type: 'hidden'});
        let careSettingField = config.widgets.careSetting + '_'  + fieldIndex;
        let careSettingInput = $(document.createElement("input")).prop({id: careSettingField, name: careSettingField, value: 'OUTPATIENT', type: 'hidden'});
        let previousOrderField = config.widgets.previousOrder + '_'  + fieldIndex;
        let previousOrderInput = $(document.createElement("input")).prop({id: previousOrderField, name: previousOrderField, type: 'hidden'});

        // Determine if there is already an existing order in the encounter for this concept
        let previousOrderId = null;
        config.history.forEach(function(order) {
            if (order.encounterId === config.encounterId && order.concept.value === concept.conceptId) {
                previousOrderId = order.orderId;
            }
        });

        let labSection = $(document.createElement("div"));
        if (config.mode === 'VIEW') {
            let labValueSection = $(document.createElement("span"));
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

            $(actionInput).val('');
            if (previousOrderId) {
                $(previousOrderInput).val(previousOrderId);
                $(toggleInput).prop("checked", true);
            }

            $(toggleInput).click(function(event) {
                if($(toggleInput).is(':checked')) {
                    if (previousOrderId) {
                        $(actionInput).val('');
                    }
                    else {
                        $(actionInput).val('NEW');
                    }
                }
                else {
                    if (previousOrderId) {
                        $(actionInput).val('DISCONTINUE');
                    }
                    else {
                        $(actionInput).val('');
                    }
                }
            });
        }
        $orderSection.append(labSection);
    });
}