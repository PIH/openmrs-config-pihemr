CALL initialize_global_metadata();

SELECT
  e.patient_id as 'patient_id',
  zl.identifier zlemr,
  CONCAT(family_name, ' ', given_name) AS 'PRÉNOM NOM (SURNOMS)',
  pa.value                             AS 'PRÉNOM DE LA MÈRE',
  commune                              AS 'Commune',
  section_communal                     AS 'Sect. Comm',
  (SELECT pa.value
   FROM
     person_attribute pa
   WHERE
     person_attribute_type_id = (SELECT person_attribute_type_id
                                 FROM
                                   person_attribute_type
                                 WHERE
                                   name = 'Telephone Number')
     AND pa.person_id = e.patient_id)  AS 'Adresse/Tél',
  birthdate                               'DATE DE NAISSANCE',
  gender                               AS 'SEXE',
  CAST(CONCAT(TIMESTAMPDIFF(YEAR, birthdate, NOW()),
              '.',
              MOD(TIMESTAMPDIFF(MONTH, birthdate, NOW()),
                  12))
       AS CHAR)                        AS AGE,
  DATE(e.encounter_datetime)           AS 'ENCOUNTER DATE',
  category_hiv_screen.result           AS 'MOTIF DE DEPISTAGE (#1 - #8)',
  reason_hiv_screen.notes              AS 'NOTES',
  (SELECT name
   FROM
     concept_name
   WHERE
     concept_id = o.value_coded
     AND locale = 'fr'
     AND concept_name_type = 'SHORT'
     AND voided = 0)                   AS 'VIOLENCE PHYSIQUE ET/OU EMOTIONNELLE',
  DATE(prcd.value_datetime)            AS 'DATE PRÉ-TEST COUNSELING',
  DATE(hivd.value_datetime)            AS 'DATE TEST VIH',
  (SELECT name
   FROM
     concept_name
   WHERE
     concept_id = hivr.value_coded
     AND locale = 'fr'
     AND concept_name_type = 'FULLY_SPECIFIED'
     AND voided = 0)                   AS 'RÉSULTAT TEST VIH',
  DATE(hivrd.value_datetime)           AS 'DATE RESULTAT VIH',
  DATE(rprd.value_datetime)            AS 'DATE TEST RPR',
  (SELECT name
   FROM
     concept_name
   WHERE
     concept_id = rpr.value_coded
     AND locale = 'fr'
     AND concept_name_type = 'FULLY_SPECIFIED'
     AND voided = 0)                   AS 'RÉSULTAT TEST RPR',
  DATE(rprrd.value_datetime)           AS 'DATE RESULTAT RPR',
  DATE(hepbd.value_datetime)		   AS  'DATE TEST HEPATITE B',
  (SELECT name
   FROM
     concept_name
   WHERE
     concept_id = hepbr.value_coded
     AND locale = 'fr'
     AND concept_name_type = 'FULLY_SPECIFIED'
     AND voided = 0)                   AS 'TEST HEPATITE B QUALITATIVE',
  DATE(hepbrd.value_datetime)		   AS 'DATE RESULTATS HEPATITE B',
  DATE(postd.value_datetime)           AS 'DATE POST-TEST COUNSELING',
  DATE(tbd.obs_datetime)               AS 'DATE ÉVALUATION TB',
  tb_evaluation.tb_result              AS 'TB EVALUATION',
  DATE(rxrpr.value_datetime)           AS 'DATE DEBUT Rx RPR',
  DATE(rxrprd.value_datetime)          AS 'DATE FIN Rx RPR',
  DATE(rspec.value_datetime)           AS 'DATE RÉFÉRENCE SERVICE PRISE EN CHARGE',
  DATE(pres.value_datetime)            AS 'DATE PROPHYLAXIE AES',
  DATE(preas.value_datetime)           AS 'DATE PROPHYLAXIE AGRESSION SEXUELLE',
  cmnt.value_text                      AS 'REMARQUES'
FROM
  encounter e
  INNER JOIN
  -- Patient's demographics
  current_name_address cna ON cna.person_id = e.patient_id
							   AND date(e.encounter_datetime) >= @startDate
							   AND date(e.encounter_datetime) <= @endDate
                               AND e.encounter_type = @vctEnc -- 41
  -- Most recent ZL EMR ID
  INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = @zlId -- 3
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON e.patient_id = zl.patient_id
  -- Name of Mother
  LEFT OUTER JOIN
  person_attribute pa ON pa.person_id = e.patient_id
                         AND pa.person_attribute_type_id = (SELECT person_attribute_type_id
                                                            FROM
                                                              person_attribute_type
                                                            WHERE
                                                              name = 'First Name of Mother')
  -- Category of HIV screening
  LEFT JOIN
  (SELECT
     person_id,
     encounter_id,
     GROUP_CONCAT(name
                  SEPARATOR ', ') AS result
   FROM
     concept_name cn
     JOIN obs o ON cn.concept_id = o.value_coded
                   AND locale = 'fr'
                   AND concept_name_type = 'FULLY_SPECIFIED'
                   AND cn.voided = 0
                   AND o.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'CIEL' AND rm.code = 164082)
   GROUP BY o.encounter_id) category_hiv_screen ON category_hiv_screen.person_id = e.patient_id
                                                   AND e.encounter_id = category_hiv_screen.encounter_id
  -- Reason for HIV screening note
  LEFT JOIN
  (SELECT
     o.person_id,
     o.encounter_id,
     GROUP_CONCAT(name
                  SEPARATOR ', ') AS notes
   FROM
     concept_name cn
     JOIN obs o ON cn.concept_id = o.value_coded
                   AND locale = 'fr'
                   AND concept_name_type = 'FULLY_SPECIFIED'
                   AND cn.voided = 0
                   AND o.concept_id IN (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code IN (11535, 11559, 11527, 3082))
   GROUP BY o.encounter_id) reason_hiv_screen ON reason_hiv_screen.person_id = e.patient_id
                                                 AND e.encounter_id = reason_hiv_screen.encounter_id
  -- Victim of gender-based violence
  LEFT JOIN
  obs o ON o.person_id = e.patient_id
           AND o.concept_id = (SELECT concept_id
                               FROM
                                 report_mapping rm
                               WHERE
                                 rm.source = 'PIH' AND rm.code = 8849)
           AND value_coded = (SELECT concept_id
                              FROM
                                report_mapping rm
                              WHERE
                                rm.source = 'CIEL' AND rm.code = 165088)
           AND o.voided = 0
           AND e.encounter_id = o.encounter_id
  -- Date of pre-test counseling
  LEFT JOIN
  obs prcd ON prcd.person_id = e.patient_id
              AND prcd.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'PIH' AND rm.code = 11577)
              AND prcd.voided = 0
              AND e.encounter_id = prcd.encounter_id
  -- HIV test date
  LEFT JOIN
  obs hivd ON hivd.person_id = e.patient_id
              AND hivd.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'CIEL' AND rm.code = 164400)
              AND hivd.voided = 0
              AND e.encounter_id = hivd.encounter_id
  -- HIV rapid test, qualitative
  LEFT JOIN
  obs hivr ON hivr.person_id = e.patient_id
              AND hivr.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'CIEL' AND rm.code = 163722)
              AND hivd.voided = 0
              AND e.encounter_id = hivr.encounter_id
  -- HIV test result received date
  LEFT JOIN
  obs hivrd ON hivrd.person_id = e.patient_id
               AND hivrd.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'CIEL' AND rm.code = 160082)
               AND hivrd.voided = 0
               AND e.encounter_id = hivrd.encounter_id
  -- Date of laboratory test should be in obs_group_id of RPR test construct
  LEFT JOIN
  obs rprd ON rprd.person_id = e.patient_id
              AND rprd.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'PIH' AND rm.code = 3267)
              AND rprd.voided = 0
              AND e.encounter_id = rprd.encounter_id
              AND rprd.obs_group_id IN (SELECT obs_id
                                        FROM
                                          obs
                                        WHERE
                                          concept_id = (SELECT concept_id
                                                        FROM
                                                          report_mapping rm
                                                        WHERE
                                                          rm.source = 'PIH' AND rm.code = 11523)
                                          AND voided = 0)
  -- Rapid Plasma Reagin value should be in obs_group_id of RPR test construct
  LEFT JOIN
  obs rpr ON rpr.person_id = e.patient_id
             AND rpr.concept_id = (SELECT concept_id
                                   FROM
                                     report_mapping rm
                                   WHERE
                                     rm.source = 'PIH' AND rm.code = 1478)
             AND rpr.voided = 0
             AND e.encounter_id = rpr.encounter_id
             AND rpr.obs_group_id IN (SELECT obs_id
                                      FROM
                                        obs
                                      WHERE
                                        concept_id = (SELECT concept_id
                                                      FROM
                                                        report_mapping rm
                                                      WHERE
                                                        rm.source = 'PIH' AND rm.code = 11523)
                                        AND voided = 0)
  -- Date of test results should be in obs_group_id of RPR test construct
  LEFT JOIN
  obs rprrd ON rprrd.person_id = e.patient_id
               AND rprrd.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 10783)
               AND rprrd.voided = 0
               AND e.encounter_id = rprrd.encounter_id
               AND rprrd.obs_group_id IN (SELECT obs_id
                                          FROM
                                            obs
                                          WHERE
                                            concept_id = (SELECT concept_id
                                                          FROM
                                                            report_mapping rm
                                                          WHERE
                                                            rm.source = 'PIH' AND rm.code = 11523)
                                            AND voided = 0)
-- Date of Hepatitis B test construct (should be in obs_gid of Hepatitis B test construct)
LEFT JOIN
  obs hepbd ON hepbd.person_id = e.patient_id
               AND hepbd.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 3267)
               AND hepbd.voided = 0
               AND e.encounter_id = hepbd.encounter_id
               AND hepbd.obs_group_id IN (SELECT obs_id
                                          FROM
                                            obs
                                          WHERE
                                            concept_id = (SELECT concept_id
                                                          FROM
                                                            report_mapping rm
                                                          WHERE
                                                            rm.source = 'PIH' AND rm.code = 11576)
                                            AND voided = 0)
-- Hep B test results
LEFT JOIN
obs hepbr ON hepbr.person_id = e.patient_id
             AND hepbr.concept_id = (SELECT concept_id
                                   FROM
                                     report_mapping rm
                                   WHERE
                                     rm.source = 'CIEL' AND rm.code = 1322)
             AND hepbr.voided = 0
             AND e.encounter_id = hepbr.encounter_id
             AND hepbr.obs_group_id IN (SELECT obs_id
                                      FROM
                                        obs
                                      WHERE
                                        concept_id = (SELECT concept_id
                                                      FROM
                                                        report_mapping rm
                                                      WHERE
                                                        rm.source = 'PIH' AND rm.code = 11576)
                                        AND voided = 0)
LEFT JOIN
  obs hepbrd ON hepbrd.person_id = e.patient_id
               AND hepbrd.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 10783)
               AND hepbrd.voided = 0
               AND e.encounter_id = hepbrd.encounter_id
               AND hepbrd.obs_group_id IN (SELECT obs_id
                                          FROM
                                            obs
                                          WHERE
                                            concept_id = (SELECT concept_id
                                                          FROM
                                                            report_mapping rm
                                                          WHERE
                                                            rm.source = 'PIH' AND rm.code = 11576)
                                            AND voided = 0)
  -- Date of post-test counseling
  LEFT JOIN
  obs postd ON postd.person_id = e.patient_id
               AND postd.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 11525)
               AND postd.voided = 0
               AND e.encounter_id = postd.encounter_id
  -- Tuberculosis evaluation (if yes, we get the obs_date)
  LEFT JOIN
  obs tbd ON tbd.person_id = e.patient_id
             AND tbd.concept_id = (SELECT concept_id
                                   FROM
                                     report_mapping rm
                                   WHERE
                                     rm.source = 'PIH' AND rm.code = 11541)
             AND tbd.voided = 0
             AND e.encounter_id = tbd.encounter_id
  -- Tuberculosis symptom present
  LEFT JOIN
  (SELECT
     person_id,
     encounter_id,
     GROUP_CONCAT(name
                  SEPARATOR ', ') AS tb_result
   FROM
     concept_name cn
     JOIN obs otb ON cn.concept_id = otb.value_coded
                     AND locale = 'fr'
                     AND concept_name_type = 'FULLY_SPECIFIED'
                     AND cn.voided = 0
                     AND otb.concept_id = (SELECT concept_id
                                           FROM
                                             report_mapping rm
                                           WHERE
                                             rm.source = 'PIH' AND rm.code = 11563)
   GROUP BY otb.encounter_id) tb_evaluation ON tb_evaluation.person_id = e.patient_id
                                               AND e.encounter_id = tb_evaluation.encounter_id
  -- RPR drug start date
  LEFT JOIN
  obs rxrpr ON rxrpr.person_id = e.patient_id
               AND rxrpr.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 11536)
               AND rxrpr.voided = 0
               AND e.encounter_id = rxrpr.encounter_id
  -- RPR drug end date
  LEFT JOIN
  obs rxrprd ON rxrprd.person_id = e.patient_id
                AND rxrprd.concept_id = (SELECT concept_id
                                         FROM
                                           report_mapping rm
                                         WHERE
                                           rm.source = 'PIH' AND rm.code = 11537)
                AND rxrprd.voided = 0
                AND e.encounter_id = rxrprd.encounter_id
  -- Date referred to HIV service
  LEFT JOIN
  obs rspec ON rspec.person_id = e.patient_id
               AND rspec.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 11538)
               AND rspec.voided = 0
               AND e.encounter_id = rspec.encounter_id
  -- Start date of HIV drug for blood exposure
  LEFT JOIN
  obs pres ON pres.person_id = e.patient_id
              AND pres.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'PIH' AND rm.code = 11539)
              AND pres.voided = 0
              AND e.encounter_id = pres.encounter_id
  -- Start date of HIV drug for sexual assault
  LEFT JOIN
  obs preas ON preas.person_id = e.patient_id
               AND preas.concept_id = (SELECT concept_id
                                       FROM
                                         report_mapping rm
                                       WHERE
                                         rm.source = 'PIH' AND rm.code = 11540)
               AND preas.voided = 0
               AND e.encounter_id = preas.encounter_id
  -- Clinical management plan comment
  LEFT JOIN
  obs cmnt ON cmnt.person_id = e.patient_id
              AND cmnt.concept_id = (SELECT concept_id
                                     FROM
                                       report_mapping rm
                                     WHERE
                                       rm.source = 'CIEL' AND rm.code = 162749)
              AND cmnt.voided = 0
              AND e.encounter_id = cmnt.encounter_id
ORDER BY e.encounter_datetime;
