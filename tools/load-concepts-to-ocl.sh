#!/bin/bash

# The goal of this script is to lay out the steps and commands necessary to load all concepts from PIH-EMR MDS packages into OCL
# This follows the steps laid out here:  https://wiki.openmrs.org/display/projects/Migrating+to+OCL%3A+PIH+Use+Case
# Ideally, this script would be able to be run via automation.
# One should be able to uncomment all steps at the bottom of the file, and execute this from start to finish
# In the event that issues are encountered, each step can be run piecemeal to step through components of the process
# Dependencies:  mvn, git, docker, jq, curl

if [ -z "$OCL_API_TOKEN" ]
then
      echo "You must have an OCL_API_TOKEN environment variable defined"
fi

PROJECT_NAME=oclexport
MYSQL_DOCKER_CONTAINER_NAME=mysql-oclexport
MYSQL_DOCKER_CONTAINER_PORT=3309
SDK_TOMCAT_PORT=8080
SDK_DEBUG_PORT=5000
OCL_API_URL=https://api.staging.openconceptlab.org

SDK_DIR=~/openmrs/$PROJECT_NAME
CODE_DIR=$SDK_DIR/code

setup_mysql_docker_container() {
  docker stop $MYSQL_DOCKER_CONTAINER_NAME || true
  sleep 5
  docker rm -v $MYSQL_DOCKER_CONTAINER_NAME || true
  sleep 5
  docker run \
    --name $MYSQL_DOCKER_CONTAINER_NAME \
    -d \
    -p $MYSQL_DOCKER_CONTAINER_PORT:3306 \
    -e MYSQL_ROOT_PASSWORD=root \
    mysql:5.6 \
    --character-set-server=utf8 \
    --collation-server=utf8_general_ci \
    --max_allowed_packet=1G \
    --innodb-buffer-pool-size=2G
  sleep 5
}

setup_mysql_db() {
  docker exec -i ${MYSQL_DOCKER_CONTAINER_NAME} sh -c "exec mysql -u root -proot -e 'drop database if exists ${PROJECT_NAME};'"
  sleep 5
  docker exec -i ${MYSQL_DOCKER_CONTAINER_NAME} sh -c "exec mysql -u root -proot -e 'create database ${PROJECT_NAME} default charset utf8;'"
}

setup_sdk() {
  rm -fR $SDK_DIR
  mvn openmrs-sdk:setup \
      -DserverId=$PROJECT_NAME \
      -Ddistro=org.openmrs.distro:pihemr:2.0.0-SNAPSHOT \
      -DjavaHome=/usr/lib/jvm/java-8-openjdk-amd64 \
      -Dpih.config=mirebalais,mirebalais-humci \
      -DdbDriver=com.mysql.cj.jdbc.Driver \
      -DdbUri=jdbc\:mysql\://localhost\:${MYSQL_DOCKER_CONTAINER_PORT}/${PROJECT_NAME}?autoReconnect\=true\&useUnicode\=true\&characterEncoding\=UTF-8\&sessionVariables\=default_storage_engine%3DInnoDB \
      -DdbUser=root \
      -Ddebug=${SDK_DEBUG_PORT} \
      -DdbPassword=root \
      -DdbReset=true \
      -DbatchAnswers="${SDK_TOMCAT_PORT}"
}

install_config() {
  # Create a configuration that contains all of the MDS packages
  rm -fR $CODE_DIR && mkdir $CODE_DIR && pushd $CODE_DIR
  git clone https://github.com/PIH/openmrs-config-pihemr.git
  git clone https://github.com/PIH/openmrs-config-zl.git
  git clone https://github.com/PIH/openmrs-config-pihliberia.git && cp openmrs-config-pihliberia/configuration/pih/concepts/*.zip openmrs-config-pihemr/configuration/pih/concepts
  git clone https://github.com/PIH/openmrs-config-pihsl.git && cp openmrs-config-pihsl/configuration/pih/concepts/*.zip openmrs-config-pihemr/configuration/pih/concepts
  git clone https://github.com/PIH/openmrs-config-ces.git && cp openmrs-config-ces/configuration/pih/concepts/*.zip openmrs-config-pihemr/configuration/pih/concepts
  popd
  pushd $CODE_DIR/openmrs-config-zl && ./install.sh $PROJECT_NAME && popd
}

run_sdk() {
  mvn openmrs-sdk:run -DserverId=$PROJECT_NAME -DMAVEN_OPTS="-Xmx4g -Xms1g" &
  echo $! > $SDK_DIR/mvn.pid
  sleep 10
  wget -O /dev/null -o /dev/null http://localhost:${SDK_TOMCAT_PORT}/openmrs
  sleep 10
  echo "Waiting for OpenMRS startup message..."
  tail -f ~/openmrs/oclexport/openmrs.log 2>&1 | grep -q "Distribution startup complete"
  RETURN_CODE=$?
  if [[ $RETURN_CODE != 0 ]]; then
      echo "OpenMRS started.  Return code: $RETURN_CODE"
  fi
  echo "Killing SDK process"
  pkill -F $SDK_DIR/mvn.pid
}

export_openmrs_db() {
  docker exec ${MYSQL_DOCKER_CONTAINER_NAME} mysqldump -u root --password=root --routines ${PROJECT_NAME} > ${SDK_DIR}/${PROJECT_NAME}.sql
}

delete_existing_from_ocl() {
  echo "Deleting the PIH source"
  curl --silent -H "Authorization: Token $OCL_API_TOKEN" --request DELETE $OCL_API_URL/orgs/PIH/sources/PIH/?async=true > ${SDK_DIR}/delete_pih_source.json
  echo "Deleting the PIH collection"
  curl --silent -H "Authorization: Token $OCL_API_TOKEN" --request DELETE $OCL_API_URL/orgs/PIH/collections/PIH/?async=true > ${SDK_DIR}/delete_pih_collection.json
  echo "Deleting the OpenBoxes source"
  curl --silent -H "Authorization: Token $OCL_API_TOKEN" --request DELETE $OCL_API_URL/orgs/PIH/sources/OpenBoxes/?async=true > ${SDK_DIR}/delete_openboxes_source.json
  wait_for_task_completion ${SDK_DIR}/delete_pih_collection.json
  wait_for_task_completion ${SDK_DIR}/delete_pih_source.json
  wait_for_task_completion ${SDK_DIR}/delete_openboxes_source.json
}

create_openboxes_source_in_ocl() {
  curl --silent \
      -H "Authorization: Token $OCL_API_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --request POST \
      --data '{"id":"OpenBoxes","short_code":"OpenBoxes","name":"OpenBoxes","full_name":"OpenBoxes","description":"OpenBoxes Product Code for Drug Mappings","source_type":"reference","default_locale":"en","supported_locales":"en"}' \
      $OCL_API_URL/orgs/PIH/sources/
  echo "OpenBoxes Source Created"
}

export_concepts_to_json() {
  pushd ${CODE_DIR}
  rm -fR ocl_omrs
  git clone https://github.com/OpenConceptLab/ocl_omrs.git
  popd
  pushd ${CODE_DIR}/ocl_omrs

  # For OpenMRS 2.5, we do not name the allow_decimal as precise, remove this
  sed -i "s/db_column='precise'//g" omrs/models.py
  # Add custom source mappings
  TO_REPLACE="# Added for AMPATH dictionary import"
  DISPENSE_STATUS=",{'owner_type': 'org', 'owner_id': 'HL7', 'omrs_id': 'HL7-MedicationDispenseStatus','ocl_id': 'HL7-MedicationDispenseStatus'}"
  OPENBOXES=",{'omrs_id': 'OpenBoxes', 'ocl_id': 'OpenBoxes', 'owner_type': 'org', 'owner_id': 'PIH'}"
  sed -i "s/${TO_REPLACE}/${DISPENSE_STATUS}${OPENBOXES}/g" omrs/management/commands/__init__.py

  cp ${SDK_DIR}/${PROJECT_NAME}.sql local/
  export USE_GOLD_MAPPINGS=1
  ./sql-to-json.sh local/${PROJECT_NAME}.sql PIH PIH staging
  popd
}

wait_for_task_completion() {
    TASK_ID=$(jq -r '.task' $1)
    echo "Waiting for task completion $1: $TASK_ID"
    STATUS=UNKNOWN
    while [[ "$STATUS" != "SUCCESS" ]]
    do
      STATUS=$(curl --silent -H "Authorization: Token $OCL_API_TOKEN" --request GET $OCL_API_URL/tasks/$TASK_ID/ | jq -r '.state')
      echo "Task $TASK_ID Status: $STATUS"
      if [ "$STATUS" != "SUCCESS" ]; then
        sleep 10
      fi
    done
    DATA=$(curl --silent -H "Authorization: Token $OCL_API_TOKEN" --request GET $OCL_API_URL/tasks/$TASK_ID/)
    echo $DATA | jq
}

create_pih_source_in_ocl() {
  curl --silent \
      -H "Authorization: Token $OCL_API_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --request POST \
      --data '{"id":"PIH","short_code":"PIH","name":"PIH","full_name":"Partners In Health","description":"Partners In Health Dictionary","custom_validation_schema":"OpenMRS","default_locale":"en","supported_locales":"en,es,fr,ht"}' \
      $OCL_API_URL/orgs/PIH/sources/
  echo "PIH Source Created"
}

bulk_import_into_ocl() {
  curl --silent \
      -H "Authorization: Token $OCL_API_TOKEN" \
      -H 'Content-Type: multipart/form-data' \
      --request POST \
      -F update_if_exists=true \
      -F file=@"$CODE_DIR/ocl_omrs/local/oclexport.json;type=application/json"  \
      $OCL_API_URL/importers/bulk-import-parallel-inline/custom-queue/ > ${SDK_DIR}/bulk_import.json
  wait_for_task_completion ${SDK_DIR}/bulk_import.json
}

create_pih_collection_in_ocl() {
  curl --silent \
      -H "Authorization: Token $OCL_API_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --request POST \
      --data '{ "id":"PIH","short_code":"PIH","name":"PIH","full_name":"PIH","preferred_source":"CIEL","collection_type":"Dictionary","custom_validation_schema":"OpenMRS","supported_locales":"en,es,fr,ht","extras":{"source":"/orgs/PIH/sources/PIH/"} }' \
      $OCL_API_URL/orgs/PIH/collections/ > ${SDK_DIR}/create_collection.json
  echo "PIH Collection Created"
}

make_pih_references() {
  curl --silent \
      -H "Authorization: Token $OCL_API_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --request PUT \
      --data '{"data": { "uri":"/orgs/PIH/sources/PIH/", "concepts":"*", "mappings":"*"} }' \
      $OCL_API_URL/orgs/PIH/collections/PIH/references/ > ${SDK_DIR}/make_references.json
  wait_for_task_completion ${SDK_DIR}/make_references.json
}

#setup_mysql_docker_container
#setup_mysql_db
#setup_sdk
#install_config
#run_sdk
#export_openmrs_db
#delete_existing_from_ocl
#create_openboxes_source_in_ocl
#export_concepts_to_json
#create_pih_source_in_ocl
#bulk_import_into_ocl
#create_pih_collection_in_ocl
#make_pih_references
