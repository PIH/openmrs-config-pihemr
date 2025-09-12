/*
    The goal of this function is to replace the standard orderWidget initialization javascript with one that
    renders lab orders as checkboxes and supports the same capabilities as the standalone lab orders page.  This supports 2 actions:
    1. If a lab has previously been ordered in the given encounter, it starts out checked.  Unchecking and saving will discontinue/void that order.
    2. If a lab has not been previously ordered in the given encounter, it starts out as non-checked.  Checking and saving will add a new order.
 */
function renderLabOrdersByCategory(config) {
    console.debug(config);

    const $widgetField = jq('#' + config.fieldName);
    const $orderSection = $widgetField.find(".orderwidget-order-section");
    const $templateSection = jq('#' + config.fieldName + "_template");

    // Determine which fields need to be collected, by examining both the template or default configuration with multiple options
    const labOrderFields = Object.keys(config.widgets);

    // Iterate over each field in the template and determine if it should be displayed or not
    const templateSections = $templateSection.find(".order-field-widget");
    const fieldSections = [];
    templateSections.each(function () {
        const fieldName = labOrderFields.filter((field) => $(this).hasClass("order-" + field)).at(0);
        const fieldWidgetSection = $templateSection.find(".order-field.order-" + fieldName);
        const numRadioInputs = fieldWidgetSection.find("input[type=radio][value != '']").length;
        const numSelectInputs = fieldWidgetSection.find("select").length;
        const numSelectOptions = fieldWidgetSection.find("option[value != '']").length;
        const isInFormTemplate = fieldWidgetSection.parents(".non-template-field").length === 0;
        fieldSections.push({fieldName, fieldWidgetSection, isInFormTemplate, numRadioInputs, numSelectInputs, numSelectOptions})
    });

    config.labTestCategories.forEach(function(category) {

        // Create section for each category, with the category name, and the category tests
        const $labCategorySection = jq(document.createElement("div")).attr("id", "lab-category-" + category.conceptId).addClass("lab-category");
        const $labCategoryNameElement = jq(document.createElement("div")).addClass("lab-category-name").html(category.displayName);
        const $labCategoryTestsSection = jq(document.createElement("div")).attr("id", "lab-category-tests-" + category.conceptId).addClass("lab-category-tests");

        // Organize the tests to render based on whether they are in panels
        const configuredTests = new Map();
        category.labTests.forEach(test => {
            configuredTests.set(test.conceptId, test);
        });

        const testsWithinPanels = new Map();
        category.labTests.forEach(function(panel) {
            if (panel.testsInPanel) {
                panel.testsInPanel.forEach(function (test) {
                    testsWithinPanels.set(test.conceptId, panel);
                });
            }
        });

        let testsForCategory = [];
        category.labTests.forEach(labTest => {
            if (!testsWithinPanels.has(labTest.conceptId)) {
                testsForCategory.push(labTest);
            }
            if (labTest.testsInPanel) {
                labTest.testsInPanel.forEach(testInPanel => {
                    if (configuredTests.has(testInPanel.conceptId)) {
                        testsForCategory.push(testInPanel);
                    }
                });
            }
        });

        // Render the tests the given category
        testsForCategory.forEach(function(labTest) {

            const idSuffix = '_' + labTest.conceptId;

            // Determine if there is already an existing order in the encounter for this concept
            let previousOrder = null;
            config.history.forEach(function(order) {
                if (order.encounterId === config.encounterId && order.concept.value === labTest.conceptId) {
                    previousOrder = order;
                }
            });

            const $labSection = jq(document.createElement("div")).attr("id", "lab" + idSuffix).addClass("lab-test-section");
            const panel = testsWithinPanels.get(labTest.conceptId);
            if (panel) {
                $labSection.addClass("test-in-panel").addClass("test-in-panel-" + panel.conceptId);
            }
            $labCategoryTestsSection.append($labSection);

            // Create the tooltip section
            const $toolTipSection = jq(document.createElement("span")).addClass("panel-tool-tip-section");
            if (labTest.testsInPanel && labTest.testsInPanel.length > 0) {
                const $toolTipButton = jq(document.createElement("i")).addClass("icon-info-sign").addClass("tooltip");
                const $toolTipText = jq(document.createElement("span")).addClass("tooltip-text");
                const $toolTipTitle = jq(document.createElement("p")).html(config.translations.testsIncludedInThisPanel);
                const $toolTipTests = jq(document.createElement("div"));
                labTest.testsInPanel.forEach(function(test) {
                    $toolTipTests.append(jq(document.createElement("span")).html(test.displayName));
                });
                $toolTipText.append($toolTipTitle);
                $toolTipText.append($toolTipTests);
                $toolTipButton.append($toolTipText);
                $toolTipSection.append($toolTipButton);
            }

            // Handle the test concept, action, and previous order fields first

            if (config.mode === 'VIEW') {
                const labValueSection = jq(document.createElement("span"));
                if (previousOrder) {
                    labValueSection.addClass("value").html("[X]&nbsp;" + labTest.displayName);
                    $labSection.find(".lab-fields").show();
                } else {
                    labValueSection.addClass("emptyValue").html("[&nbsp;&nbsp;]&nbsp;" + labTest.displayName);
                    $labSection.find(".lab-fields").hide();
                }
                $labSection.append(labValueSection);
                $labSection.append($toolTipSection);
            }
            else {
                const toggleField = "order_toggle"  + idSuffix;
                const toggleInput = jq(document.createElement("input")).prop({id: toggleField, name: toggleField, value: '', type: 'checkbox'});
                $labSection.append(toggleInput);

                const actionField = config.widgets.action + idSuffix;
                const actionInput = jq(document.createElement("input")).prop({id: actionField, name: actionField, value: '', type: 'hidden'});
                $labSection.append(actionInput);

                const conceptField = config.widgets.concept + idSuffix;
                const conceptInput = jq(document.createElement("input")).prop({id: conceptField, name: conceptField, value: labTest.conceptId, type: 'hidden'});
                $labSection.append(conceptInput).append(" " + labTest.displayName);
                $labSection.append($toolTipSection);

                const previousOrderField = config.widgets.previousOrder + idSuffix;
                const previousOrderInput = jq(document.createElement("input")).prop({id: previousOrderField, name: previousOrderField, type: 'hidden'});
                $labSection.append(previousOrderInput);

                // Set up the toggle checkbox to set the order action to either NEW, DISCONTINUE, or null
                jq(actionInput).val('');
                if (previousOrder) {
                    jq(previousOrderInput).val(previousOrder ? previousOrder.orderId : '');
                    jq(toggleInput).prop("checked", true);
                }
                jq(toggleInput).click(function() {
                    if(jq(toggleInput).is(':checked')) {
                        jq(actionInput).val(previousOrder ? "" : "NEW");
                        $labSection.find(".lab-fields").show();
                    }
                    else {
                        jq(actionInput).val(previousOrder ? "DISCONTINUE" : "");
                        $labSection.find(".lab-fields").hide();
                    }
                });
            }

            const $labFieldsSection = jq(document.createElement("span")).attr("id", "lab-fields" + idSuffix).addClass("lab-fields");
            $labSection.append($labFieldsSection);
            if (previousOrder) {
                $labFieldsSection.show();
            }
            else {
                $labFieldsSection.hide();
            }

            const requiredCodedFields = ["careSetting", "urgency"];
            const nonRequiredCodedFields = ["orderReason", "specimenSource", "laterality", "frequency", "location"];
            const nonCodedFields = ["orderReasonNonCoded", "instructions", "clinicalHistory", "numberOfRepeats", "scheduledDate", "dateActivated"];

            fieldSections.forEach(function(fieldSection) {
                const field = fieldSection.fieldName;
                const $clonedFieldSection = jq(fieldSection.fieldWidgetSection).clone(true, true);

                $clonedFieldSection.find("[id]").add($clonedFieldSection).each(function () {
                    if (this.id) {
                        this.id = this.id + idSuffix;
                    }
                });
                $clonedFieldSection.find("[name]").add($clonedFieldSection).each(function () {
                    if (this.name) {
                        this.name = this.name + idSuffix;
                    }
                });

                // We have special handling for orderReason and urgency, so do these first
                if (field === "orderReason") {
                    if (labTest.reasons && labTest.reasons.length > 0) {
                        const $orderReasonSelect = $clonedFieldSection.find("select");
                        labTest.reasons.forEach(function(reason) {
                            $orderReasonSelect.append(jq(document.createElement("option")).attr("value", reason.conceptId).html(reason.displayName));
                        });
                        $labFieldsSection.append($clonedFieldSection);
                    }
                    else {
                        $clonedFieldSection.hide();
                    }
                }
                else {
                    if (requiredCodedFields.includes(field)) {
                        if (fieldSection.numRadioInputs < 2 && fieldSection.numSelectOptions < 2) {
                            $clonedFieldSection.hide();
                        }
                        $labFieldsSection.append($clonedFieldSection);
                    }
                    else if (nonRequiredCodedFields.includes(field) || nonCodedFields.includes(field)) {
                        if (fieldSection.isInFormTemplate) {
                            $labFieldsSection.append($clonedFieldSection);
                        }
                    }
                }
            });

            if (previousOrder) {
                orderWidget.populateOrderForm(config, $labFieldsSection, previousOrder);
            }
        });

        $labCategorySection.append($labCategoryNameElement).append($labCategoryTestsSection);
        $orderSection.append($labCategorySection);
    });
}
