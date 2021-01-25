angular.module("encounterTypeConfig", [])

    .factory("EncounterTypeConfig", function() {

        var hfeSimpleEditUrl = "/htmlformentryui/htmlform/editHtmlFormWithSimpleUi.page?patientId={{encounter.patient.uuid}}&encounterId={{encounter.uuid}}&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}";
        var hfeStandardEditUrl = "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{encounter.patient.uuid}}&encounterId={{encounter.uuid}}&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}";

        var getFormResource = function(formName) {
          return "file:configuration/pih/htmlforms/" + formName;
        };

        // template model url:
        // if a template operates off an model different that the standard OpenMRS REST representation of an encounter,
        // you specify the URL of the source here; used currently for htmlFormEntry encounter templates, which
        // require the encounter to be formatted using the HFE schema

        /* Define Sections */
        var chiefComplaint = {
            type: "encounter-section",
            id: "pihcore-chief-complaint",
            label: "pihcore.chiefComplaint.title",
            icon: "fas fa-fw fa-list-ul",
            classes: "indent",
            shortTemplate: "templates/sections/chiefComplaintSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-chief-complaint.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=file:configuration/pih/htmlforms/section-chief-complaint.xml&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        // we include the edit url here because the "Next" navigator functionality uses it
        var allergies = {
            type: "include-section",
            id: "allergies",
            template: "templates/allergies/reviewAllergies.page",
            editUrl: "/allergyui/allergies.page?patientId={{patient.uuid}}&returnUrl={{returnUrl}}"
        };

        var vaccinations = {
            id: "chVaccinations",
            type: "include-section",
            template: "templates/vaccination/vaccinations.page",
            editUrl: ""
        };

        var pedsVaccinations = {
            type: "include-section",
            id: "vaccinations",
            template: "templates/vaccination/vaccinations.page",
            editUrl: "",
            require: "patientAgeInYearsOnDate(visit.startDatetime) < 15"
        };

        var ancVaccinations = {
            type: "include-section",
            id: "vaccinations",
            template: "templates/vaccination/vaccinations.page",
            editUrl: "",
            require: "patient.person.gender == 'F'"
        };

        var primaryCareHistory = {
            type: "encounter-section",
            id: "pihcore-history",
            label: "pihcore.history.label",
            icon: "fas fa-fw fa-history",
            classes: "indent",
            shortTemplate: "templates/sections/primaryCareHistorySectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-history.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-history.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var primaryCareExam = {
            type: "encounter-section",
            id: "physical-exam",
            label: "pihcore.exam.label",
            icon: "fas fa-fw fa-stethoscope",
            shortTemplate: "templates/sections/examSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-exam.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-exam.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var pedsFoodAndSupplements = {
            type: "encounter-section",
            id: "pihcore-peds",
            label: "pihcore.foodAndSupplements.label",
            icon: "fas fa-fw fa-utensils",
            shortTemplate: "templates/sections/pedsSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-peds.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-peds.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}",
            require: "patientAgeInYearsOnDate(visit.startDatetime) < 15"
        };

        var primaryCareDx = {
            type: "encounter-section",
            id: "pihcore-diagnosis",
            label: "pihcore.diagnosis.label",
            icon: "fas fa-fw fa-diagnoses",
            shortTemplate: "templates/sections/dxSectionShort.page",
            longTemplate: "templates/sections/dxLong.page",
            //templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-dx.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-dx.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var primaryCarePlan = {
            type: "encounter-section",
            id: "pihcore-plan",
            label: "pihcore.visitNote.plan",
            icon: "fas fa-fw fa-list-ul",
            shortTemplate: "templates/sections/primaryCarePlanSectionShort.page",
            longTemplate: "templates/sections/viewPlanSectionWithHtmlFormLong.page",
            printTemplate: "templates/sections/printPrescriptionsWithHtmlFormLong.page",
            printTemplateUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-prescriptions-print.xml"),
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-plan.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-plan.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"

        };

        // Sierra Leone has one Plan section used on it's Outpatient forms, and then a medication-only
        // plans section used on other forms, so we need a separate "medication plan" section for that
        var primaryCarePlanMedication = {
          type: "encounter-section",
          id: "pihcore-plan-medication",
          label: "pihcore.visitNote.plan",
          icon: "fas fa-fw fa-list-ul",
          shortTemplate: "templates/sections/primaryCarePlanSectionShort.page",
          longTemplate: "templates/sections/viewPlanSectionWithHtmlFormLong.page",
          printTemplate: "templates/sections/printPrescriptionsWithHtmlFormLong.page",
          printTemplateUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-prescriptions-print.xml"),
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-plan-medication.xml"),
          editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-plan-medication.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"

        };

        var ncd = {
            type: "encounter-section",
            id: "pihcore-ncd",
            label: "pihcore.visitNote.ncdInitial",
            icon: "fas fa-fw fa-heart",
            shortTemplate: "templates/sections/ncdSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }

        // ToDo: ncdInitial and ncdFollowup are the same and replaced by ncd
        var ncdInitial = {
            type: "encounter-section",
            id: "pihcore-ncd",
            label: "pihcore.visitNote.ncdInitial",
            icon: "fas fa-fw fa-list-heart",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }
        var ncdFollowup = {
            type: "encounter-section",
            id: "pihcore-ncd",
            label: "pihcore.visitNote.ncdFollowup",
            icon: "fas fa-fw fa-heart",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-ncd.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }

        var hivHistory = {
            type: "encounter-section",
            id: "hiv-history",
            label: "pihcore.history.label",
            icon: "fas fa-fw fa-history",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-history.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-history.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var labRadOrder = {
            type: "encounter-section",
            id: "lab-rad-order",
            label: "pihcore.order.title",
            icon: "fas fa-fw fa-vial",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-lab-order.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-lab-order.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };


        var hivAssessment = {
            type: "encounter-section",
            id: "hiv-assessment",
            label: "pihcore.assessment",
            icon: "fas fa-fw fa-th-large",
            shortTemplate: "templates/sections/hivSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-assessment.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-assessment.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var familyPlanningHistory = {
            type: "encounter-section",
            id: "family-planning-history",
            label: "pihcore.familyPlanning.title",
            icon: "fas fa-fw fa-users",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-family-planning.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-family-planning.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var hivPlan = {
            type: "encounter-section",
            id: "hiv-intake-plan",
            label: "pihcore.visitNote.plan",
            icon: "fas fa-fw fa-list-ul",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-plan.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-plan.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var hivState = {
            type: "encounter-section",
            id: "hiv-state",
            label: "pihcore.hiv.clinicalState.short",
            icon: "fas fa-fw fa-bolt",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-state.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/section-hiv-state.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var ancInitial = {
            type: "encounter-section",
            id: "section-anc-intake",
            label: "pihcore.ancIntake.title",
            icon: "fas fa-fw fa-gift",
            shortTemplate: "templates/sections/ancIntakeSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-anc-intake.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-anc-intake.xml")+ "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }

        var ancFollowup = {
            type: "encounter-section",
            id: "section-anc-followup",
            label: "pihcore.ancFollowup.title",
            icon: "fas fa-fw fa-gift",
            shortTemplate: "templates/sections/ancIntakeSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-anc-followup.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-anc-followup.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }

        var delivery = {
            type: "encounter-section",
            id: "section-delivery",
            label: "pihcore.delivery.title",
            icon: "fas fa-fw fa-baby",
            shortTemplate: "templates/sections/deliverySectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-delivery.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-delivery.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }

        var obgynInitial = {
            type: "encounter-section",
            id: "section-obgyn-initial",
            label: "pihcore.obGynInitial.title",
            icon: "fas fa-fw fa-female",
            shortTemplate: "templates/sections/obgynInitialSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-obgyn-initial.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-obgyn-initial.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        }


        var obgynPlan = {
            type: "encounter-section",
            id: "section-obgyn-plan",
            label: "pihcore.visitNote.plan",
            icon: "fas fa-fw fa-flag-checkered",
            shortTemplate: "templates/sections/obgynPlanSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-obgyn-plan.xml"),
            editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-obgyn-plan.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var mchReferral = {
          type: "encounter-section",
          id: "section-mch-referral",
          label: "pihcore.refer.title",
          icon: "icon-share",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-mch-referral.xml"),
          editUrl: "/htmlformentryui/htmlform/editHtmlFormWithStandardUi.page?patientId={{visit.patient.uuid}}&visitId={{visit.uuid}}&encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-mch-referral.xml") + "&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        var maternalDangerSigns = {
          type: "encounter-section",
          id: "section-maternal-danger-signs",
          label: "pihcore.mch.dangerSigns",
          icon: "icon-warning-sign",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-maternal-danger-signs.xml"),
          editUrl:""
        };

        var maternalVitalSigns = {
          type: "encounter-section",
          id: "section-maternal-vital-signs",
          label: "pihcore.vitalSigns",
          icon: "fas fa-fw fa-heartbeat",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-maternal-vital-signs.xml"),
        };

        var educationSubjects = {
          type: "encounter-section",
          id: "section-education-subjects",
          label: "pihcore.socioEconomic.education",
          icon: "fas fa-fw fa-clipboard-check",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-education-subjects.xml"),
        };

        var postpartumCounsel = {
            type: "encounter-section",
            id: "section-postpartum-training",
            label: "pihcore.socioEconomic.education",
            icon: "fas fa-fw fa-clipboard-check",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-postpartum-counsel.xml"),
        };

        var maternalFamilyPlanning = {
            type: "encounter-section",
            id: "maternal-family-planning",
            label: "pihcore.familyPlanning.title",
            icon: "icon-umbrella",
            shortTemplate: "templates/sections/defaultSectionShort.page",
            longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-family-planning-simple.xml"),
        };

        var comments = {
          type: "encounter-section",
          id: "section-comments",
          label: "pihcore.remarks",
          icon: "icon-comment",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-comments.xml"),
        };

        var returnVisitDate = {
          type: "encounter-section",
          id: "section-return-visit-date",
          label: "pihcore.consult.returnVisitDate",
          icon: "icon-calendar",
          shortTemplate: "templates/sections/defaultSectionShort.page",
          longTemplate: "templates/sections/viewSectionWithHtmlFormLong.page",
          templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("section-return-visit-date.xml"),
        };

        

        /**
         * Define Encounter Types
         * Should support all of the following formats:
         *
         * encounterTypes['some-uuid'] = {
         *    // single config
         * }
         *
         * encounterTypes['some-uuid'] = {
         *    DEFAULT: {
         *      // default config
         *    }
         *    SPECIFIC_COUNTRY: {
         *      // specific country config
         *    }
         * }
         *
         *
         * encounterTypes['some-uuid'] = {
         *    DEFAULT: {
         *      // default config
         *    }
         *    SPECIFIC_COUNTRY: {
         *      DEFAULT: {
         *        // specific country config
         *      }
         *      SPECIFIC_SITE: {
         *        // specific site config
         *      }
         *    }
         * }
         **/

        var encounterTypes = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultHtmlFormEncounterLong.page",
                templateModelUrl: "/module/htmlformentry/encounter.json?encounter={{encounter.uuid}}",
                showOnVisitList: true
            }
        };

        // patientRegistration
        encounterTypes["873f968a-73a8-4f9c-ac78-9f4778b751b6"] = {  // should never appear on dashboard?
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterLong.page"
        };

        // prenatalHomeAssessment
        encounterTypes["91DDF969-A2D4-4603-B979-F2D6F777F4AF"] = {
          defaultState: "short",
          shortTemplate: "templates/encounters/defaultEncounterShort.page",
          longTemplate: "templates/encounters/defaultEncounterShort.page",
          showOnVisitList: true,
          sections: [
            mchReferral,
            maternalVitalSigns,
            maternalDangerSigns,
            educationSubjects,
            comments,
            returnVisitDate
          ],
        };

        // pediatricHomeAssessment
        encounterTypes["0CF4717A-479F-4349-AE6F-8602E2AA41D3"] = {
          defaultState: "short",
          shortTemplate: "templates/encounters/defaultEncounterShort.page",
          longTemplate: "templates/encounters/defaultEncounterShort.page",
          icon: "fas fa-fw fa-baby",
          showOnVisitList: true,
          sections: [
            mchReferral,
            maternalVitalSigns,
            maternalDangerSigns,
            postpartumCounsel,
            comments,
            returnVisitDate
          ],
        };

        // maternalPostPartumHomeAssessment
        encounterTypes["0E7160DF-2DD1-4728-B951-641BBE4136B8"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-female",
            showOnVisitList: true,
            sections: [
                mchReferral,
                maternalVitalSigns,
                maternalDangerSigns,
                postpartumCounsel,
                maternalFamilyPlanning,
                comments,
                returnVisitDate
            ],
        };

        // maternalFollowUpHomeAssessment
        encounterTypes["690670E2-A0CC-452B-854D-B95E2EAB75C9"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-female",
            showOnVisitList: true,
            sections: [
                mchReferral,
                maternalVitalSigns,
                postpartumCounsel,
                maternalFamilyPlanning,
                comments
            ],
        };

        // checkIn
        encounterTypes["55a0d3ea-a4d7-4e88-8f01-5aceb2d3c61b"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/checkInShort.page",
            longTemplate: "templates/encounters/defaultHtmlFormEncounterLong.page",
            templateModelUrl: "/module/htmlformentry/encounter.json?encounter={{encounter.uuid}}",
            icon: "fas fa-fw icon-check-in",
            editUrl: hfeSimpleEditUrl
        };

        // vitals
        encounterTypes["4fb47712-34a6-40d2-8ed3-e153abbd25b7"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/vitalsShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-heartbeat",
            editUrl: hfeSimpleEditUrl
        };

        // consultation / outpatientConsult
        encounterTypes["92fd09b4-5335-4f7e-9f63-b2a663fd09a6"] = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/clinicConsultLong.page",
                icon: "fas fa-fw fa-stethoscope",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true
            },
            peru: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultEncounterShort.page",
                icon: "fas fa-fw fa-gift",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true,
                sections: [
                    primaryCareHistory,
                    primaryCareExam,
                    primaryCareDx,
                    primaryCarePlan
                ]
            }
        };

        // primaryCarePedsInitialConsult
        encounterTypes["5b812660-0262-11e6-a837-0800200c9a66"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",  // no expanded view, instead there are individual sections
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                primaryCareHistory,
                pedsVaccinations,
                pedsFoodAndSupplements,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan
            ]
        };

        // primaryCarePedsFollowupConsult
        encounterTypes["229e5160-031b-11e6-a837-0800200c9a66"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",   // no expanded view, instead there are individual sections
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                chiefComplaint,
                pedsVaccinations,
                pedsFoodAndSupplements,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan
            ]
        };

        // primaryCareAdultInitialConsult
        encounterTypes["27d3a180-031b-11e6-a837-0800200c9a66"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",   // no expanded view, instead there are individual sections
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                primaryCareHistory,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan
            ]
        };

        // primaryCareAdultFollowupConsult
        encounterTypes["27d3a181-031b-11e6-a837-0800200c9a66"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",   // no expanded view, instead there are individual sections
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                chiefComplaint,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan
            ]
        };

        // ncdInitialConsult
        encounterTypes["ae06d311-1866-455b-8a64-126a9bd74171"] = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultEncounterShort.page",
                icon: "fas fa-fw fa-heart",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true,
                sections: [
                    primaryCareHistory,
                    primaryCareExam,
                    pedsVaccinations,
                    pedsFoodAndSupplements,
                    ncd,
                    primaryCareDx,
                    primaryCarePlan
                ]
            },
            "liberia": {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
                templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("ncd-adult-initial.xml"),
                icon: "fas fa-fw fa-user",
                editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("ncd-adult-initial.xml"),
                showOnVisitList: true
            }
        };

        // ncdFollowupConsult
        encounterTypes["5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c"] = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultEncounterShort.page",
                icon: "fas fa-fw fa-heart",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true,
                sections: [
                    primaryCareExam,
                    pedsVaccinations,
                    ncd,
                    primaryCareDx,
                    primaryCarePlan
                ]
            },
            "liberia": {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
                templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("ncd-adult-followup.xml"),
                icon: "fas fa-fw fa-user",
                editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("ncd-adult-followup.xml"),
                showOnVisitList: true
            }
        };

        // echocardiogramConsult
        encounterTypes["fdee591e-78ba-11e9-8f9e-2a86e4085a59"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-heartbeat",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true
        };

        // zlHivIntake
        // ToDo: Replace the icon and add more sections
        encounterTypes["c31d306a-40c4-11e7-a919-92ebcb67fe33"] = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultEncounterShort.page",   // no expanded view, instead there are individual sections
                icon: "fas fa-fw fa-ribbon",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true,
                sections: [
                    hivHistory,
                    primaryCareExam,
                    pedsVaccinations,
                    hivAssessment,
                    hivPlan
                ]
            },
            peru: {
                ...encounterTypes.DEFAULT,
                icon: "fas fa-fw fa-ribbon",
                editUrl: hfeStandardEditUrl
            }
        };

        // zlHivFollowup
        // ToDo: Replace the icon and add sections
        encounterTypes["c31d3312-40c4-11e7-a919-92ebcb67fe33"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",   // no expanded view, instead there are individual sections
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                hivState,
                primaryCareExam,
                pedsVaccinations,
                primaryCareDx,
                hivPlan
            ]
        };

        // oncologyConsult
        encounterTypes["035fb8da-226a-420b-8d8b-3904f3bedb25"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-paste",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true
        };

        // oncologyInitialVisit
        encounterTypes["f9cfdf8b-d086-4658-9b9d-45a62896da03"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-paste",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true
        };

        // chemotherapySession
        encounterTypes["828964fa-17eb-446e-aba4-e940b0f4be5b"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-retweet",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true
        };

        // medicationDispensed
        encounterTypes["8ff50dea-18a1-4609-b4c9-3f8f2d611b84"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-pills",
            editUrl: hfeStandardEditUrl
        };

        // postOperativeNote
        encounterTypes["c4941dee-7a9b-4c1c-aa6f-8193e9e5e4e5"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            primaryEncounterRoleUuid: "9b135b19-7ebe-4a51-aea2-69a53f9383af",  // attendingSurgeon
            icon: "fas fa-fw fa-paste",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true
        };

        // transfer
        encounterTypes["436cfe33-6b81-40ef-a455-f134a9f7e580"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultHtmlFormEncounterLong.page",
            templateModelUrl: "/module/htmlformentry/encounter.json?encounter={{encounter.uuid}}",
            icon: "fas fa-fw fa-share",
            editUrl: hfeStandardEditUrl
        };

        // admission
        encounterTypes["260566e1-c909-4d61-a96f-c1019291a09d"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/admissionLong.page",
            icon: "fas fa-fw fa-sign-in-alt",
            editUrl: hfeStandardEditUrl
        };

        // cancelAdmission
        encounterTypes["edbb857b-e736-4296-9438-462b31f97ef9"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-ban",
            editUrl: hfeStandardEditUrl
        };

        // exitFromCare
        encounterTypes["b6631959-2105-49dd-b154-e1249e0fbcd7"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-sign-out-alt",
            editUrl: hfeStandardEditUrl
        };

        // labResults
        encounterTypes["4d77916a-0620-11e5-a6c0-1697f925ec7b"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-vial",
            editUrl: hfeSimpleEditUrl,
            showOnVisitList: true
        };

        // radiologyOrder
        encounterTypes["1b3d1e13-f0b1-4b83-86ea-b1b1e2fb4efa"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterLong.page",
            icon: "fas fa-fw fa-x-ray"
        };

        // radiologyStudy
        encounterTypes["5b1b4a4e-0084-4137-87db-dba76c784439"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterLong.page",
            icon: "fas fa-fw fa-x-ray"
        };

        // radiologyReport
        encounterTypes["d5ca53a7-d3b5-44ac-9aa2-1491d2a4b4e9"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterLong.page",
            icon: "fas fa-fw fa-x-ray"
        };

        // deathCertificate
        encounterTypes["1545d7ff-60f1-485e-9c95-5740b8e6634b"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-times-circle",
            editUrl: hfeStandardEditUrl
        };

        // mentalHealth
        // because of a bug, we manually append the defintionUiResource to the template and edit urls
        // see: https://tickets.pih-emr.org/browse/UHM-2524
        encounterTypes["a8584ab8-cc2a-11e5-9956-625662870761"] = {
          DEFAULT: {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("mentalHealth.xml"),
            icon: "fas fa-fw fa-user",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("mentalHealth.xml"),
            showOnVisitList: true
          },
          "liberia": {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("mentalHealth.xml"),
            icon: "fas fa-fw fa-user",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("mentalHealth.xml"),
            showOnVisitList: true
          }
        };

        // artAdherence
        // HIV forms from MSPP and iSantePlus
        encounterTypes["c45d7299-ad08-4cb5-8e5d-e0ce40532939"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/iSantePlus/Adherence.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/iSantePlus/Adherence.xml"),
            showOnVisitList: true
        };

        // hivIntakeAdult
        encounterTypes["17536ba6-dd7c-4f58-8014-08c7cb798ac7"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/iSantePlus/SaisiePremiereVisiteAdult.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/iSantePlus/SaisiePremiereVisiteAdult.xml"),
            showOnVisitList: true
        };

        // hivIntakePeds
        encounterTypes["349ae0b4-65c1-4122-aa06-480f186c8350"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/iSantePlus/SaisiePremiereVisitePediatrique.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/iSantePlus/SaisiePremiereVisitePediatrique.xml"),
            showOnVisitList: true
        };

        // hivFollowupAdult
        encounterTypes["204ad066-c5c2-4229-9a62-644bc5617ca2"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/iSantePlus/VisiteDeSuivi.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/iSantePlus/VisiteDeSuivi.xml"),
            showOnVisitList: true
        };

        // hivFollowupPeds
        encounterTypes["33491314-c352-42d0-bd5d-a9d0bffc9bf1"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/iSantePlus/VisiteDeSuiviPediatrique.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/iSantePlus/VisiteDeSuiviPediatrique.xml"),
            showOnVisitList: true
        };

        // VCT
        encounterTypes["616b66fe-f189-11e7-8c3f-9a214cf093ae"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/vct.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/vct.xml"),
            showOnVisitList: true
        };

        // HIV dispensing
        encounterTypes["cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("hiv/hiv-dispensing.xml"),
            icon: "fas fa-fw fa-ribbon",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("hiv/hiv-dispensing.xml"),
            showOnVisitList: true
        };

        // Socio-economics (socioEcon)
        encounterTypes["de844e58-11e1-11e8-b642-0ed5f89f718b"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("socio-econ.xml"),
            icon: "fas fa-fw fa-home",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("socio-econ.xml"),
            showOnVisitList: true
        };

        /*
         * COVID-19 forms
         */

        // covid19Admission
        encounterTypes["8d50b938-dcf9-4b8e-9938-e625bd2f0a81"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("covid19Intake.xml"),
            icon: "fab fa-fw fa-first-order-alt",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("covid19Intake.xml"),
            showOnVisitList: true
        };

        // covid19Progress
        encounterTypes["ca65f5d3-6312-4143-ae4e-0237427f339e"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("covid19Followup.xml"),
            icon: "fab fa-fw fa-first-order-alt",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("covid19Followup.xml"),
            showOnVisitList: true
        };

        // covid19Discharge
        encounterTypes["5e82bea0-fd7b-47f9-858a-91be87521073"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("covid19Discharge.xml"),
            icon: "fab fa-fw fa-first-order-alt",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("covid19Discharge.xml"),
            showOnVisitList: true
        };

        /*
         * Back to non-COVID encounters now
         */

        // primaryCareVisit
        encounterTypes["1373cf95-06e8-468b-a3da-360ac1cf026d"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}",
            icon: "fas fa-fw fa-heart",
            editUrl: hfeStandardEditUrl
        };

        // edTriage
        encounterTypes["74cef0a6-2801-11e6-b67b-9e71128cae77"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/edTriageShort.page",
            icon: "fas fa-fw fa-ambulance",
            editUrl: "edtriageapp/edtriageEditPatient.page?editable=true&patientId={{patient.uuid}}&encounterId={{encounter.uuid}}&appId=edtriageapp.app.triageQueue&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}",
            viewUrl: "edtriageapp/edtriageEditPatient.page?editable=false&patientId={{patient.uuid}}&encounterId={{encounter.uuid}}&appId=edtriageapp.app.triageQueue&returnUrl={{returnUrl}}&breadcrumbOverride={{breadcrumbOverride}}"
        };

        // testOrder
        encounterTypes["b3a0e3ad-b80c-4f3f-9626-ace1ced7e2dd"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/testOrderLong.page",
            icon: "fas fa-fw fa-vial"
        };

        // pathologySpecimenCollection
        encounterTypes["10db3139-07c0-4766-b4e5-a41b01363145"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/pathologySpecimenCollectionLong.page",
            icon: "fas fa-fw fa-microscope"
        };

        // labSpecimenCollection
        encounterTypes["39C09928-0CAB-4DBA-8E48-39C631FA4286"] = {
          defaultState: "short",
          shortTemplate: "templates/encounters/defaultEncounterShort.page",
          longTemplate: "templates/encounters/labsSpecimenEncounterLong.page",
          icon: "fas fa-fw fa-vial"
        };

        /*
         * MCH/Prenatal
         */

        // ancIntake
        encounterTypes["00e5e810-90ec-11e8-9eb6-529269fb1459"] = {
          DEFAULT: {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-gift",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              ancInitial,
              ancVaccinations,
              primaryCareDx
            ]
          },
          'sierra_leone': {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-gift",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              ancInitial,
              ancVaccinations,
              primaryCareDx,
              primaryCarePlanMedication,
            ]
          },
            "liberia": {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
                templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("anc-initial.xml"),
                icon: "fas fa-fw fa-user",
                editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("anc-initial.xml"),
                showOnVisitList: true,
                sections: [
                    ancVaccinations
                ]
            }
        };

        // vaccination
        encounterTypes["1e2a509c-7c9f-11e9-8f9e-2a86e4085a59"] = {
            defaultState: "long",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/vaccination/chVaccinations.page",
            icon: "fas fa-fw fa-umbrella",
            showOnVisitList: true
        };

        // ancFollowup
        encounterTypes["00e5e946-90ec-11e8-9eb6-529269fb1459"] = {
          DEFAULT: {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-gift",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              ancFollowup,
              ancVaccinations,
              primaryCareDx
            ]
          },
          'sierra_leone': {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-gift",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              ancFollowup,
              ancVaccinations,
              primaryCareDx,
              primaryCarePlanMedication,
            ]
          },
            "liberia": {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
                templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("anc-followup.xml"),
                icon: "fas fa-fw fa-user",
                editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("anc-followup.xml"),
                showOnVisitList: true,
                sections: [
                    ancVaccinations
                ]
            }
        };

        // delivery
        encounterTypes["00e5ebb2-90ec-11e8-9eb6-529269fb1459"] = {
          DEFAULT: {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-baby",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              delivery,
              primaryCareDx
            ]
          },
          'sierra_leone': {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-gift",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
              delivery,
              primaryCareDx,
              primaryCarePlanMedication,
            ]
          },
            "liberia": {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
                templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("anc-delivery.xml"),
                icon: "fas fa-fw fa-user",
                editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("anc-delivery.xml"),
                showOnVisitList: true,
                sections: [
                    primaryCareDx,
                    delivery
                ]
            }
        };

        // obgyn
        encounterTypes["d83e98fd-dc7b-420f-aa3f-36f648b4483d"] = {
            DEFAULT: {
                defaultState: "short",
                shortTemplate: "templates/encounters/defaultEncounterShort.page",
                longTemplate: "templates/encounters/defaultEncounterShort.page",
                icon: "fas fa-fw fa-female",
                editUrl: hfeStandardEditUrl,
                showOnVisitList: true,
                sections: [
                    obgynInitial,
                    ancVaccinations,
                    primaryCareExam,
                    primaryCareDx,
                    obgynPlan
                ]
            }
        };

        // OVC Intake
        encounterTypes["651d4359-4463-4e52-8fde-e62876f90792"] = {
            ...encounterTypes.DEFAULT,
            editUrl: hfeStandardEditUrl,
        };

        // OVC Followup
        encounterTypes["f8d426fd-132a-4032-93da-1213c30e2b74"] = {
            ...encounterTypes.DEFAULT,
            editUrl: hfeStandardEditUrl,
        };

        /*
         * Site-specific encounters
         */

        // mexicoConsult
        // TODO change Mexico and Sierra Leone consults to use standard outpatient encounter types now that we support multiple configs per encounter type?
        encounterTypes["aa61d509-6e76-4036-a65d-7813c0c3b752"] = {
            defaultState: "long",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/viewEncounterWithHtmlFormLong.page",
            templateModelUrl: "/htmlformentryui/htmlform/viewEncounterWithHtmlForm/getAsHtml.action?encounterId={{encounter.uuid}}&definitionUiResource=" + getFormResource("consult.xml"),
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl + "&definitionUiResource=" + getFormResource("consult.xml"),
            showOnVisitList: true
        };

        // sierraLeoneOutpatientInitial
        encounterTypes["7d5853d4-67b7-4742-8492-fcf860690ed5"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                primaryCareHistory,
                pedsVaccinations,
                pedsFoodAndSupplements,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan,
            ]
        };

        // sierraLeoneOutpatientFollowup
        encounterTypes["d8a038b5-90d2-43dc-b94b-8338b76674f3"] = {
            defaultState: "short",
            shortTemplate: "templates/encounters/defaultEncounterShort.page",
            longTemplate: "templates/encounters/defaultEncounterShort.page",
            icon: "fas fa-fw fa-stethoscope",
            editUrl: hfeStandardEditUrl,
            showOnVisitList: true,
            sections: [
                chiefComplaint,
                pedsVaccinations,
                pedsFoodAndSupplements,
                primaryCareExam,
                primaryCareDx,
                primaryCarePlan,
            ]
        };

        return {
          get: function(uuid, country, site) {
            var encounterType = encounterTypes[uuid];

            if (encounterType == null) {
              return encounterTypes.DEFAULT;
            }

            if (encounterType.hasOwnProperty(country)) {
               if (encounterType[country].hasOwnProperty(site)) {
                 return encounterType[country][site];
               }
               else {
                 return encounterType[country].hasOwnProperty('DEFAULT') ?
                   encounterType[country]['DEFAULT'] : encounterType[country];
               }
            }

            return encounterType.hasOwnProperty(['DEFAULT']) ?
              encounterType['DEFAULT'] : encounterType;
          }
        };
    });
