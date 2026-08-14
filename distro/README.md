# PIH EMR Distribution

This module defines the base PIH EMR OpenMRS distribution — a specific OpenMRS war, module set, and OWA set — using the [OpenMRS SDK Maven plugin](https://wiki.openmrs.org/display/docs/OpenMRS+SDK). It's published as `org.pih.openmrs:pihemr-distro` and consumed as the parent distro by every country-specific `xxx-emr` repo (`lesotho-emr`, `ces-emr`, `pihsl-emr`, `pihliberia-emr`, `zl-emr`), each of which layers its own content and frontend on top at its own distro-assembly time.

## How it works

Component versions are defined as Maven properties in `pom.xml`, inherited from the [`pihcore`](https://github.com/PIH/openmrs-module-pihcore) parent module's own version properties. During the Maven build (`mvn clean package`), these properties are interpolated into `openmrs-distro.properties`, and the `openmrs-sdk-maven-plugin`'s `build-distro` goal resolves the resulting war/module/OWA set into `target/distro/`. Only the resulting jar (containing the resolved `openmrs-distro.properties`) is published — there's no bundled zip artifact.

Unlike a country-specific distro (e.g. `lesotho-distro`), this module has no parent distro or content/frontend of its own to layer — it's the root of that chain, so it doesn't declare any `content.*`/`spa.*` entries in `openmrs-distro.properties`.

## Updating component versions

To update a component version, change the corresponding property in `pom.xml` (or let the scheduled `update-versions.yml` workflow do it automatically) and rebuild:

```bash
mvn clean package
```

## Debian package

`debian/` contains the packaging scripts (`build.sh`, `publish.sh`) and control files used to build and publish a `.deb` package of the raw OpenMRS war/module/OWA set (no content) to the PIH EMR Debian repository, for hosts still provisioned via Puppet rather than Docker. See `.github/workflows/build-and-deploy.yml`'s `deploy-debian` job for how this runs in CI.

## Release

Releases follow semantic versioning and run via the `release.yml` GitHub Actions workflow (a thin caller into `openmrs-contrib-distro-tools`'s reusable `release.yml`), which runs `mvn release:prepare release:perform -Prelease` across the whole reactor (`content/` + `distro/`) from the root `pom.xml`.
