#!/bin/bash

# The goal of this script is to lay out the steps and commands necessary to load all concepts from PIH-EMR MDS packages into OCL

PROJECT_NAME=oclexport
SDK_DIR=~/openmrs/$PROJECT_NAME
CODE_DIR=$SDK_DIR/code

setup_sdk() {
  rm -fR $SDK_DIR
  ~/environments/mysql/recreate-db.sh mysql56 $PROJECT_NAME
  mvn openmrs-sdk:setup \
      -DserverId=$PROJECT_NAME \
      -Ddistro=org.openmrs.distro:pihemr:2.0.0-SNAPSHOT \
      -DjavaHome=/usr/lib/jvm/java-8-openjdk-amd64 \
      -Dpih.config=mirebalais,mirebalais-humci \
      -Ddebug=5000 \
      -DdbDriver=com.mysql.cj.jdbc.Driver \
      -DdbUri=jdbc\:mysql\://localhost\:3308/${PROJECT_NAME}?autoReconnect\=true\&useUnicode\=true\&characterEncoding\=UTF-8\&sessionVariables\=default_storage_engine%3DInnoDB \
      -DdbUser=root \
      -DdbPassword=root \
      -DdbReset=true \
      -DbatchAnswers="8080"
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
  wget -O /dev/null -o /dev/null http://localhost:8080/openmrs
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
  ~/environments/mysql/export-db.sh mysql56 $PROJECT_NAME $SDK_DIR/$PROJECT_NAME.sql
}

# TODO: Here, we need to ensure there is an OpenBoxes source in the PIH organization

export_concepts_to_json() {
  pushd $CODE_DIR
  rm -fR ocl_omrs
  cp -a ~/code/github/openconceptlab/ocl_omrs/ .
  #git clone https://github.com/OpenConceptLab/ocl_omrs.git
  popd
  pushd $CODE_DIR/ocl_omrs
  sed -i "s/db_column='precise'//g" omrs/models.py
  cp $SDK_DIR/$PROJECT_NAME.sql local/
  export USE_GOLD_MAPPINGS=1
  ./sql-to-json.sh local/$PROJECT_NAME.sql PIH PIH staging
  popd
}

setup_sdk
install_config
run_sdk
export_openmrs_db
export_concepts_to_json
