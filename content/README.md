# PIH-EMR OpenMRS Content Package

This module defines the shared [OpenMRS Initializer](https://github.com/mekomsolutions/openmrs-module-initializer) configuration used across every PIH EMR site. At build time, the contents of `configuration/` are assembled into a zip artifact published as `org.pih.openmrs:pihemr-content`.

Unlike a country-specific content package (e.g. `lesotho-content`, `ces-content`), this package has no parent content of its own to merge with — it *is* the shared base that every country-specific `xxx-content` package merges with when its own distribution is built.

## Configuration Structure

Configuration files live under two subdirectories:

| Directory | Purpose |
|---|---|
| `frontend_configuration/` | O3/SPA configuration (`config.json`, `base-config.json`, logo) loaded by the frontend at runtime |
| `backend_configuration/` | Everything else — appframework extensions, concept sources, encounter types, global properties, locations, message properties, OCL exports, order types, PIH-specific scripts/forms/reports, privileges, provider roles, roles, visit types |

## content.properties

`content.properties` provides the content package name and version (interpolated from the Maven project at build time), and defines every `var.*` constant referenced by `${...}` placeholders in `configuration/**` — concept/location/encounter-type UUIDs, global property values, and similar. Because this package has no parent content, every constant used anywhere in its own configuration must be defined here; there's no fallback package to inherit from.
