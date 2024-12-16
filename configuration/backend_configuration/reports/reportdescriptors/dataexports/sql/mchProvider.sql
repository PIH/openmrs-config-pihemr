CALL initialize_global_metadata();

SELECT
  pid.patient_id,
  p.identifier                                 "provider_identifier",
  pr.name                                      "provider_role",
  CONCAT(pn.given_name, ' ', pn.family_name)   "provider_name",
  CONCAT(pnc.given_name, ' ', pnc.family_name) "patient_name",
  pid.identifier                               "patient_identifier",
  (SELECT pa.value
   FROM
     person_attribute pa
   WHERE
     person_attribute_type_id = (SELECT person_attribute_type_id
                                 FROM
                                   person_attribute_type
                                 WHERE
                                   name = 'Telephone Number')
     AND pa.person_id = pid.patient_id) AS     'patient_tel_number'
FROM provider p
  INNER JOIN providermanagement_provider_role pr ON p.provider_role_id = pr.provider_role_id AND
                                                    pr.uuid = '9a4b44b2-8a9f-11e8-9a94-a6cf71072f73'
  -- Nurse Accompagnateur

  -- pn = Provider
  LEFT OUTER JOIN person_name pn
    ON pn.person_name_id =
       (SELECT person_name_id
        FROM person_name pn2
        WHERE pn2.person_id = p.person_id
              AND pn2.voided = 0
        ORDER BY pn2.preferred DESC, pn2.date_created DESC
        LIMIT 1)
  INNER JOIN relationship r
    ON r.person_a = p.person_id
       AND r.voided = 0
       AND r.end_date IS NULL
       AND relationship =
           (SELECT relationship_type_id
            FROM relationship_type
            WHERE uuid = '9a4b3eea-8a9f-11e8-9a94-a6cf71072f73')
  -- Nurse accompagnateur relationship

  INNER JOIN patient_program pp
    ON pp.patient_id = r.person_b
       AND pp.voided = 0
       AND pp.program_id =
           (SELECT program_id
            FROM program
            WHERE uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73')

  LEFT OUTER JOIN person_name pnc ON pnc.person_name_id =
                                     (SELECT person_name_id
                                      FROM person_name pnc2
                                      WHERE pnc2.person_id = r.person_b AND pnc2.voided = 0
                                      ORDER BY pnc2.preferred DESC, pnc2.date_created DESC
                                      LIMIT 1)
  -- patient id
  LEFT OUTER JOIN patient_identifier pid
    ON pid.patient_identifier_id = (SELECT pid2.patient_identifier_id
                                    FROM patient_identifier pid2
                                    WHERE pid2.patient_id = r.person_b
                                          AND pid2.identifier_type = @zlId -- ZL EMR
                                    ORDER BY pid2.preferred DESC, pid2.date_created DESC
                                    LIMIT 1)
  -- patient state
  LEFT OUTER JOIN patient_state ps ON ps.patient_state_id = (SELECT patient_state_id
                                                             FROM patient_state
                                                             WHERE patient_program_id = pp.patient_program_id AND
                                                                   end_date IS NULL
                                                             ORDER BY patient_program_id
                                                             LIMIT 0, 1)
  LEFT OUTER JOIN program_workflow_state pws ON pws.program_workflow_state_id = ps.state AND pws.retired = 0

  LEFT OUTER JOIN program_workflow pw ON pw.program_workflow_id = pws.program_workflow_id AND pw.retired = 0
  -- CHW Present
  LEFT OUTER JOIN obs o ON o.obs_id = (SELECT obs_id
                                       FROM obs o2
                                       WHERE o2.person_id = pp.patient_id
                                             AND o2.concept_id = (SELECT concept_id
                                                                  FROM report_mapping rm
                                                                  WHERE rm.source = 'CIEL' AND rm.code = '155')

                                       ORDER BY o2.obs_datetime DESC
                                       LIMIT 1);
