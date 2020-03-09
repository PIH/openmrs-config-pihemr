

### PIH EMR Configuration

This repository provides standard configuration that is shared across all instances of the PIH-EMR. In addition to this, 
each country-level distro has it's own configuration repository that can override and supplement the customization
provided here.

The configuration distro projects are as follows:

|Site|Repo  |
|---|---|
|CES|https://github.com/PIH/openmrs-config-ces|
|Liberia|https://github.com/PIH/openmrs-config-pihliberia|
|SES|https://github.com/PIH/openmrs-config-ses|
|Sierra Leone|https://github.com/PIH/openmrs-config-pihsl|
|ZL|https://github.com/PIH/openmrs-config-zl|


These configurations are merged and packaged using the OpenMRS Packager Maven Plugin 
(https://github.com/openmrs/openmrs-contrib-packager-maven-plugin). The full documentation for using the plug-in to 
build a site-specific deployment configuration can be found at the above link.  

As part of our build, the latest configuration artifacts for each country are deployed to sonatype and 
can be found here:

https://oss.sonatype.org/#nexus-search;quick~org.pih.openmrs

#### Configurable elements

We are in the process of moving all of our configuration out of code (generally in the PIH Core and
Mirebalais modules) into these new config projects.  Below is a list of what is currently configured here, but we
expect this to continue to grow in the near future.

##### PIH Config

PIH Config json files (which determine what components are turned on for each server, among other things) are
found in the country-specific config projects in the 'configuration/pih' directory. Which "config" files are
activated depends on the "pih.config" property defined in the runtime properties file for your specific server.

For example, if you set pih.config as follows in your runtime.properties file:

```
pih.config=mirebalais,mirebalais-humci
```

Then the following two config files will be used

```
pih-config-mirebalais.json
pih-config-mirebalais-humci.json
```

Note that the files will be loaded left to right, with latter config files overridding earlier ones.

Unfortunately, these files currently aren't "hot reloadable", but will be reloaded upon restarting the server.

(Components are defined in [pihcore/.../config/Components.java](https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/config/Components.java). Based on these component selections (and often some other criteria) CALF ([mirebalais/.../CustomAppLoaderFactory.java](https://github.com/PIH/openmrs-module-mirebalais/blob/master/api/src/main/java/org/openmrs/module/mirebalais/apploader/CustomAppLoaderFactory.java)) loads apps and forms. Apps are defined in [mirebalais/.../CustomAppLoaderConstants.java](https://github.com/PIH/openmrs-module-mirebalais/blob/master/api/src/main/java/org/openmrs/module/mirebalais/apploader/CustomAppLoaderConstants.java). )


##### Address

(Note that we haven't migrated all existing implementations to use this method, but that shouldn't stop up from 
configuring new implementations using this method)

There are two parts to address configuration.

First there is the Address Hierarchy module configuration, which manages the address hierarchy
data in MySQL. This is done by adding
[AddressHierarchy config files](https://wiki.openmrs.org/display/docs/Address+Hierarchy+Advanced+Features) (see "Activator Loading of Address Configuration & Entries") to the
`configuration/addresshierarchy/` directory in the config repository for your distribution.

Then there's the RegistrationApp configuration with respect to addresses. The two settings of note
here are the shortcut field and the manual (i.e., free-text) fields. These are configured in the
addressConfig tree in your PIH config file (found in 
`configuration/pih` directory of the config project for your distribution). These options are handled by 
[mirebalais/.../PatientRegistrationApp](https://github.com/PIH/openmrs-module-mirebalais/blob/8a565656ff335cd28dcb310c0b1c4de3dcd4d62f/api/src/main/java/org/openmrs/module/mirebalais/apploader/apps/PatientRegistrationApp.java).
If you don’t provide this configuration, this file provides defaults.


##### Concepts

Concepts installed via Metadata Sharing Package (the majority of the concepts) are now packaged within the
config.  The installer will install all metadata sharing packages found in the "/configuration/pih/concepts"
package.  Generally, we have consolidated our metadata so that most packages are installed on all servers.  
Country-specific concepts are deployed in country-specific packages like "Mexico_Concepts", "Liberia_Concepts", etc.  
These country-specific packages are found in the country-specific distro repositories.

Adding a new package to the distro should be as easy as adding a new MDS package to the "/configuration/pih
/concepts" directory.  To upgrade an existing package it should be enough to generate a new version of the MDS
package and replace it within the "/configuration/pih/concepts" directory.  Upon startup, the PIH EMR will scan
that directory and compare all packages against their installed versions, and install/update as necessary.

(Note that concepts installed via Metadata Deploy are still installed in the PIH Core module.  We will likely move
these over to the PIH Config when we switch from using MDD and MDS to Iniz to install concepts.)


##### Forms

All forms are now packages within the PIH Config.  Any form suitable to be shared across implementations can 
be found "/configuration/pih/htmlforms" directory of this project.  Country-specific forms can be found in the
same directory in the site-specific repositories.  If a form with the same name is found in both this repository
and the country-specific repository, the country-specific format "wins".

The xml files that  represent forms are parsed by the HTML FormEntry Module. Check out the
[HTML/DSL Reference](https://wiki.openmrs.org/display/docs/HTML+Form+Entry+Module+HTML+Reference).

See this [example of a check-in form](https://github.com/PIH/openmrs-module-pihcore/blob/master/omod/src/main/webapp/resources/htmlforms/haiti/checkin.xml). 

Note that these forms are also "hot reloadable".  On an existing server, if you install or update a 
version of a form, the next time someone opens a new instance of that form, the latest version of the 
form will be loaded. (Note that due to particularities of the form loading process, when an existing
form instance is loaded in "edit" mode, the new version is not "hot reloaded").

Also note that although we do not yet use this feature, variable substitution is available within forms.  You
can define a variable within the constants.yml in the top-level project and then use it within multiple forms.
(Will provide pointers to some examples once we start to do this.)

(The application logic that specifies when to display forms, and which form files to use, is still in code and found 
in [CALF](https://github.com/PIH/openmrs-module-mirebalais/blob/master/api/src/main/java/org/openmrs/module/mirebalais/apploader/CustomAppLoaderFactory.java)) 

Note that this application logic often depends both on which components are enabled and which location tags are enabled
at the active location.  Location Tags are currently still setup in code in [openmrs-module-pihcore/api/src/main/java/org/openmrs/module/pihcore/setup/LocationTagSetup.java](https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/setup/LocationTagSetup.java).



