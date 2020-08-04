#
DROP PROCEDURE IF EXISTS initialize_global_metadata;
#
CREATE PROCEDURE initialize_global_metadata()
BEGIN

	SET @dosId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566');
    SET @zlId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'a541af1e-105c-40bf-b345-ba1fd6a59b85');
    SET @hivId = (select patient_identifier_type_id from patient_identifier_type where uuid = '139766e8-15f5-102d-96e4-000c29c2a5d7');
    SET @biometricId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'e26ca279-8f57-44a5-9ed8-8cc16e90e559');

    SET @testPt = (select person_attribute_type_id from person_attribute_type where uuid = '4f07985c-88a5-4abd-aa0c-f3ec8324d8e7');
    SET @unknownPt = (select person_attribute_type_id from person_attribute_type where uuid = '8b56eac7-5c76-4b9c-8c6f-1deab8d3fc47');

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
    SET @oncNoteEnc = encounter_type('035fb8da-226a-420b-8d8b-3904f3bedb');
    SET @oncIntakeEnc = encounter_type('f9cfdf8b-d086-4658-9b9d-45a62896da03');
    SET @chemoEnc = encounter_type('828964fa-17eb-446e-aba4-e940b0f4be5b');
    SET @dispEnc = encounter_type('8ff50dea-18a1-4609-b4c9-3f8f2d611b84');
    SET @EDTriageEnc = encounter_type('74cef0a6-2801-11e6-b67b-9e71128cae77');
    SET @vctEnc = encounter_type('616b66fe-f189-11e7-8c3f-9a214cf093ae');

    SET @pathologyTestOrder = (select order_type_id from order_type where uuid='65c912c2-88cf-46c2-83ae-2b03b1f97d3a');

    SET @consultingClinician = (select encounter_role_id from encounter_role where uuid = '4f10ad1a-ec49-48df-98c7-1391c6ac7f05');
    SET @orderingProvider = (select encounter_role_id from encounter_role where uuid = 'c458d78e-8374-4767-ad58-9f8fe276e01c');
    SET @principalResultsInterpreter = (select encounter_role_id from encounter_role where uuid = '08f73be2-9452-44b5-801b-bdf7418c2f71');
    SET @radiologyTech = (select encounter_role_id from encounter_role where uuid = '8f4d96e2-c97c-4285-9319-e56b9ba6029c');
    SET @clerkEncRole = (select encounter_role_id from encounter_role where uuid = 'cbfe0b9d-9923-404c-941b-f048adc8cdc0');

    SET @dispo = concept_from_mapping('PIH', 'HUM Disposition categories');
    SET @admitDispoConcept = concept_from_mapping('PIH', 'ADMIT TO HOSPITAL');
    SET @leftWithoutSeeingDispoConcept = concept_from_mapping('PIH', 'Left without seeing a clinician');
    SET @deathDispoConcept = concept_from_mapping('PIH', 'DEATH');
    SET @transferOutDispoConcept = concept_from_mapping('PIH', 'Transfer out of hospital');
    SET @leftWithoutCompletingDispoConcept = concept_from_mapping('PIH', 'Departed without medical discharge');
    SET @dischargeDispoConcept = concept_from_mapping('PIH', 'DISCHARGED');

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
    SET @tramaOccur = (select concept_id from concept where uuid='f8134959-62d2-4f94-af6c-3580312b07a0');
    SET @tramaType = (select concept_id from concept where uuid='7c5ef8cd-3c2b-46c1-b995-20e52c11ce94');
    SET @rvd = (select concept_id from concept where uuid='3ce94df0-26fe-102b-80cb-0017a47871b2');
    SET @comment = (select concept_id from concept where uuid='3cd9d956-26fe-102b-80cb-0017a47871b2');
    SET @boardingFor = (select concept_id from concept where uuid='83a54c1d-510e-4860-8971-61755c71f0ed');

    SET @paid = (select concept_id from concept where uuid='5d1bc5de-6a35-4195-8631-7322941fe528');
    SET @reasonForVisit = (select concept_id from concept where uuid='e2964359-790a-419d-be53-602e828dcdb9');

END
#
