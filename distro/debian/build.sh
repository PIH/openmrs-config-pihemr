#!/usr/bin/env sh

BUILD_NUMBER=$(date +%Y%m%d%H%M%S)

DISTRO_DIR=${project.build.directory}/distro/web
PACKAGE_DIR=${project.build.directory}/debian/package

perl -pi -e "s/pihemr \([^)]+\)/pihemr (1.0.${BUILD_NUMBER}-1)/" ${PACKAGE_DIR}/debian/changelog

cp ${DISTRO_DIR}/openmrs_core/openmrs.war ${PACKAGE_DIR}/openmrs.war

mkdir -p ${PACKAGE_DIR}/home/tomcat/.OpenMRS/modules/
cp ${DISTRO_DIR}/openmrs_modules/* ${PACKAGE_DIR}/home/tomcat/.OpenMRS/modules/

mkdir -p ${PACKAGE_DIR}/home/tomcat/.OpenMRS/owa/
cp ${DISTRO_DIR}/openmrs_owas/* ${PACKAGE_DIR}/home/tomcat/.OpenMRS/owa/
rename 's/\.owa$/.zip/' ${PACKAGE_DIR}/home/tomcat/.OpenMRS/owa/*.owa

cd ${PACKAGE_DIR} && debuild --no-tgz-check -i -us -uc -b
