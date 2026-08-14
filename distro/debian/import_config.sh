#!/bin/bash

#Create dirs for unzipping resources
rm -rf ./target/frontend
mkdir ./target/frontend
rm -rf ./target/frontend_zl
mkdir ./target/frontend_zl
rm -rf ./target/configuration
mkdir ./target/configuration
rm -rf ./target/configuration_zl
mkdir ./target/configuration_zl
rm -rf ./target/configuration_pihsl
mkdir ./target/configuration_pihsl
rm -rf ./target/configuration_ces
mkdir ./target/configuration_ces
rm -rf ./target/configuration_pihliberia
mkdir ./target/configuration_pihliberia

#retrive config and frontend from maven

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-frontend-pihemr:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-frontend-zl:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-config-pihemr:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-config-zl:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-config-pihsl:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-config-ces:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy \
-Dartifact=org.pih.openmrs:openmrs-config-pihliberia:LATEST:zip \
-DoutputDirectory=./target/ -Dmdep.useBaseVersion=true

#unzip maven resources


unzip -o ./target/"openmrs-frontend-pihemr"* -d ./target/frontend/
unzip -o ./target/"openmrs-frontend-zl"* -d ./target/frontend_zl/
unzip -o ./target/"openmrs-config-pihemr"* -d ./target/configuration/
unzip -o ./target/"openmrs-config-zl"* -d ./target/configuration_zl/
unzip -o ./target/"openmrs-config-pihsl"* -d ./target/configuration_pihsl/
unzip -o ./target/"openmrs-config-ces"* -d ./target/configuration_ces/
unzip -o ./target/"openmrs-config-pihliberia"* -d ./target/configuration_pihliberia/