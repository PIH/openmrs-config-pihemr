#
DROP PROCEDURE IF EXISTS initialize_global_metadata;
#
CREATE PROCEDURE initialize_global_metadata()
BEGIN

	SET @dosId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566');
    SET @zlId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'a541af1e-105c-40bf-b345-ba1fd6a59b85');
    SET @hivId = (select patient_identifier_type_id from patient_identifier_type where uuid = '139766e8-15f5-102d-96e4-000c29c2a5d7');
    SET @biometricId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'e26ca279-8f57-44a5-9ed8-8cc16e90e559');

	SET @phoneNumber = (select person_attribute_type_id from person_attribute_type where uuid = '14d4f066-15f5-102d-96e4-000c29c2a5d7');
    SET @testPt = (select person_attribute_type_id from person_attribute_type where uuid = '4f07985c-88a5-4abd-aa0c-f3ec8324d8e7');
    SET @unknownPt = (select person_attribute_type_id from person_attribute_type where uuid = '8b56eac7-5c76-4b9c-8c6f-1deab8d3fc47');

	SET @zikaProgram = (select program_id from program where uuid = '3bea593a-9afd-4642-96a6-210b60f5aff2');

    SET @regEnc = encounter_type('873f968a-73a8-4f9c-ac78-9f4778b751b6');
    SET @chkEnc = encounter_type('55a0d3ea-a4d7-4e88-8f01-5aceb2d3c61b');
    SET @vitEnc = encounter_type('4fb47712-34a6-40d2-8ed3-e153abbd25b7');
    SET @consEnc = encounter_type('92fd09b4-5335-4f7e-9f63-b2a663fd09a6');
    SET @admitEnc = encounter_type('260566e1-c909-4d61-a96f-c1019291a09d');
    SET @transferEnc = encounter_type('436cfe33-6b81-40ef-a455-f134a9f7e580');
    SET @exitEnc = encounter_type('b6631959-2105-49dd-b154-e1249e0fbcd7');
    SET @ANCInitEnc = encounter_type('00e5e810-90ec-11e8-9eb6-529269fb1459');
    SET @ANCFollowEnc = encounter_type('00e5e946-90ec-11e8-9eb6-529269fb1459');
    SET @DeliveryEnc = encounter_type('00e5ebb2-90ec-11e8-9eb6-529269fb1459');
    SET @postOpNoteEnc = encounter_type('c4941dee-7a9b-4c1c-aa6f-8193e9e5e4e5');
    SET @radEnc = encounter_type('1b3d1e13-f0b1-4b83-86ea-b1b1e2fb4efa');
    SET @radStudyEnc = encounter_type('5b1b4a4e-0084-4137-87db-dba76c784439');
    SET @radReportEnc = encounter_type('d5ca53a7-d3b5-44ac-9aa2-1491d2a4b4e9');
    SET @oncNoteEnc = encounter_type('035fb8da-226a-420b-8d8b-3904f3bedb25');
    SET @oncIntakeEnc = encounter_type('f9cfdf8b-d086-4658-9b9d-45a62896da03');
    SET @chemoEnc = encounter_type('828964fa-17eb-446e-aba4-e940b0f4be5b');
    SET @dispEnc = encounter_type('8ff50dea-18a1-4609-b4c9-3f8f2d611b84');
    SET @EDTriageEnc = encounter_type('74cef0a6-2801-11e6-b67b-9e71128cae77');
    SET @vctEnc = encounter_type('616b66fe-f189-11e7-8c3f-9a214cf093ae');
    SET @AdultInitEnc = encounter_type('27d3a180-031b-11e6-a837-0800200c9a66');
    SET @AdultFollowEnc = encounter_type('27d3a181-031b-11e6-a837-0800200c9a66 ');
    SET @PedInitEnc = encounter_type('5b812660-0262-11e6-a837-0800200c9a66');
    SET @PedFollowEnc = encounter_type('229e5160-031b-11e6-a837-0800200c9a66');
    SET @NCDInitEnc = encounter_type('ae06d311-1866-455b-8a64-126a9bd74171');
	SET @labResultEnc = encounter_type('4d77916a-0620-11e5-a6c0-1697f925ec7b');

    SET @pathologyTestOrder = (select order_type_id from order_type where uuid='65c912c2-88cf-46c2-83ae-2b03b1f97d3a');

    SET @consultingClinician = (select encounter_role_id from encounter_role where uuid = '4f10ad1a-ec49-48df-98c7-1391c6ac7f05');
    SET @orderingProvider = (select encounter_role_id from encounter_role where uuid = 'c458d78e-8374-4767-ad58-9f8fe276e01c');
    SET @principalResultsInterpreter = (select encounter_role_id from encounter_role where uuid = '08f73be2-9452-44b5-801b-bdf7418c2f71');
    SET @radiologyTech = (select encounter_role_id from encounter_role where uuid = '8f4d96e2-c97c-4285-9319-e56b9ba6029c');
    SET @clerkEncRole = (select encounter_role_id from encounter_role where uuid = 'cbfe0b9d-9923-404c-941b-f048adc8cdc0');
    SET @nurse = (select encounter_role_id from encounter_role where uuid = '98bf2792-3f0a-4388-81bb-c78b29c0df92');

    SET @dispo = concept_from_mapping('PIH', 'HUM Disposition categories');
    SET @admitDispoConcept = concept_from_mapping('PIH', 'ADMIT TO HOSPITAL');
    SET @leftWithoutSeeingDispoConcept = concept_from_mapping('PIH', 'Left without seeing a clinician');
    SET @deathDispoConcept = concept_from_mapping('PIH', 'DEATH');
    SET @transferOutDispoConcept = concept_from_mapping('PIH', 'Transfer out of hospital');
    SET @leftWithoutCompletingDispoConcept = concept_from_mapping('PIH', 'Departed without medical discharge');
    SET @dischargeDispoConcept = concept_from_mapping('PIH', 'DISCHARGED');
    SET @diagnosisOrder = concept_from_mapping('PIH', 'Diagnosis order');
    SET @diagnosisCertainty = concept_from_mapping('PIH', 'CLINICAL IMPRESSION DIAGNOSIS CONFIRMED');

    SET @xrayOrderables = (select concept_id from concept where uuid = global_property_value('emr.xrayOrderablesConcept', ''));
    SET @ctOrderables = (select concept_id from concept where uuid = global_property_value('emr.ctScanOrderablesConcept', ''));
    SET @ultrasoundOrderables = (select concept_id from concept where uuid = global_property_value('emr.ultrasoundOrderablesConcept', ''));

    SET @radiologyChest = (select concept_id from concept where uuid='cf739c45-e5e6-4544-b06a-16670898706e');
    SET @radiologyHeadNeck = (select concept_id from concept where uuid='c271e719-8bf7-4f06-a8d5-853210c34592');
    SET @radiologySpine = (select concept_id from concept where uuid='35ca061d-91d4-4549-aa80-be6b82706053');
    SET @radiologyVascular = (select concept_id from concept where uuid='4419626d-236c-4281-968d-961cf90567fb');
    SET @radiologyAbdomenPelvis = (select concept_id from concept where uuid='da40f72e-8c3e-4b82-8295-b4bbd656afa8');
    SET @radiologyMusculoskeletal = (select concept_id from concept where uuid='2d26d7be-f7fa-400a-9e26-2fdf5e01e9ab');

    SET @coded = (select concept_id from concept where uuid='226ed7ad-b776-4b99-966d-fd818d3302c2');
    SET @nonCoded = (select concept_id from concept where uuid='970d41ce-5098-47a4-8872-4dd843c0df3f');
    SET @transfOut = (select concept_id from concept where uuid='113a5ce0-6487-4f45-964d-2dcbd7d23b67');
    SET @traumaOccur = (select concept_id from concept where uuid='f8134959-62d2-4f94-af6c-3580312b07a0');
    SET @traumaType = (select concept_id from concept where uuid='7c5ef8cd-3c2b-46c1-b995-20e52c11ce94');
    SET @rvd = (select concept_id from concept where uuid='3ce94df0-26fe-102b-80cb-0017a47871b2');
    SET @comment = (select concept_id from concept where uuid='3cd9d956-26fe-102b-80cb-0017a47871b2');
    SET @boardingFor = (select concept_id from concept where uuid='83a54c1d-510e-4860-8971-61755c71f0ed');
    SET @notifiable = (select concept_id from concept where uuid='ddb35fb6-e69b-49cb-9540-ba11cf40ffd7');
    SET @urgent = (select concept_id from concept where uuid='0f8dc745-5f4d-494d-805b-6f8c8b5fe258');
    SET @santeFamn = (select concept_id from concept where uuid='27b6675d-02ea-4331-a5fc-9a8224f90660');
    SET @psycho = (select concept_id from concept where uuid='3b85c049-1e2d-4f58-bad4-bf3bc98ed098');
    SET @peds = (select concept_id from concept where uuid='231ac3ac-2ad4-4c41-9989-7e6b85393b51');
    SET @outpatient = (select concept_id from concept where uuid='11c8b2ab-2d4a-4d3e-8733-e10e5a3f1404');
    SET @ncd = (select concept_id from concept where uuid='6581641f-ee7e-4a8a-b271-2148e6ffec77');
    SET @notDx = (select concept_id from concept where uuid='a2d2124b-fc2e-4aa2-ac87-792d4205dd8d');
    SET @ed = (select concept_id from concept where uuid='cfe2f068-0dd1-4522-80f5-c71a5b5f2c8b');
    SET @ageRst = (select concept_id from concept where uuid='2231e6b8-6259-426d-a9b2-d3cb8fbbd6a3');
    SET @oncology = (select concept_id from concept where uuid='36489682-f68a-4a82-9cf8-4d2dca2221c6');
    SET @paid = (select concept_id from concept where uuid='5d1bc5de-6a35-4195-8631-7322941fe528');
    SET @reasonForVisit = (select concept_id from concept where uuid='e2964359-790a-419d-be53-602e828dcdb9');

    SET @icd10 = (select concept_source_id from concept_reference_source where uuid='3f65bd34-26fe-102b-80cb-0017a47871b2');

    SET @hivDosId = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE uuid = '3B954DB1-0D41-498E-A3F9-1E20CCC47323');
    SET @hivProgram = (SELECT program_id from program where uuid = "b1cb1fc1-5190-4f7a-af08-48870975dafc");
    SET @eidProgram = (SELECT program_id from program where uuid = "7e06bf82-9f1a-4218-b68f-823082ef519b");

END
#