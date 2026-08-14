# pihemr content/distro migration design

> Branch: `UHM-9473`. Companion reading: `config-repo-content-distro-migration-playbook.md`
> (`~/environments/claude/`), which this design follows for the `content/` half of the work.

## Context

`openmrs-config-pihemr` is the root of the PIH-EMR family. Unlike the five repos the playbook
already tracks (`ces-emr`, `pihliberia-emr`, `pihsl-emr`, `zl-emr`, and the reference
`lesotho-emr`), it has no parent distro or parent content package above it — it *is* the parent
those five repos depend on (`org.openmrs.distro:pihemr` and `org.pih.openmrs:pihemr-content`).

Today this repo is split across two places:

- `openmrs-config-pihemr` itself already has a `content/` module producing `pihemr-content`, but
  via `openmrs-packager-maven-plugin`'s `generate-resource-filters`/`create-content-package` goals
  (flattening the root `constants.yml` into `content.properties` at build time), not the plain
  `maven-resources-plugin` + hand-written `content.properties` approach the playbook establishes.
  `configuration/` still has an unsplit `frontend/` subdirectory instead of
  `frontend_configuration/`/`backend_configuration/`.
- `openmrs-distro-pihemr` is a **separate GitHub repo** that publishes `org.openmrs.distro:pihemr`
  (jar), with `<parent>org.openmrs.module:pihcore</parent>` for its ~40 `omod.*` version
  properties. It has no GHA-based Maven deploy or Docker publish — CI there only builds an
  unrelated `partnersinhealth/debian-build` tool image. The actual `org.openmrs.distro:pihemr`
  publish and the Debian-package build/publish (`debian/build.sh` + `debian/publish.sh`, pushing to
  `https://openmrs.jfrog.io/artifactory/deb-pih/pool`) both currently run outside this codebase
  (Bamboo), which is why no workflow file shows them.

This work merges both into one `openmrs-config-pihemr` repo (renamed `pihemr`) as `content/` +
`distro/` sibling modules, matching the target pattern, and brings the Debian publish and the
`mvn release`/PR-verify automation into GHA as first-class, reusable steps.

## Goals

1. `content/` fully converted to the playbook's target shape (drop
   `openmrs-packager-maven-plugin`, hand-written `content/content.properties`,
   `frontend_configuration`/`backend_configuration` split).
2. New `distro/` module replaces `openmrs-distro-pihemr`, publishing
   `org.pih.openmrs:pihemr-distro` (jar only).
3. Repo renamed `openmrs-config-pihemr` → `pihemr`; root artifactId → `pihemr`.
4. Root/content/distro all share one version line, bumped to `3.0.0-SNAPSHOT` to signal the
   architecture change.
5. CI: Docker + Sonatype publish via the existing `openmrs-contrib-distro-tools` reusable
   `build-and-deploy.yml`, **plus** a ported Debian build/publish job (was Bamboo-only), **plus**
   PR verification and release automation via two *new* reusable workflows in
   `openmrs-contrib-distro-tools` (`verify.yml`, `release.yml`) that this repo calls into.
6. `update-versions.yml` added, matching the five children.

## Non-goals (explicit follow-ups, not built on this branch)

- Updating `lesotho-emr`/`ces-emr`/`pihsl-emr`/`pihliberia-emr`/`zl-emr`'s `distro/pom.xml`
  `parentGroup`/`parentArtifact`/`parentVersion` properties to
  `org.pih.openmrs`/`pihemr-distro`/`3.0.0-SNAPSHOT`. Separate PRs per repo, only mergeable once
  this repo actually publishes those coordinates.
- Adding the new reusable `verify.yml`/`release.yml` thin-callers to those same five repos.
- Retiring/archiving `openmrs-distro-pihemr` — only once all five children have cut over.
- Any Puppet/Bamboo coordinate updates on live hosts, and anything in `mirebalais-puppet` —
  per the playbook's standing rule, this is the repo owner's own process, not investigated or
  touched here. Flagged risk: once the packager-plugin-produced root zip and
  `openmrs-distro-pihemr`'s jar stop being published under their old coordinates, any
  un-repointed live consumer keeps building against an increasingly stale artifact rather than
  failing loudly.
- The stray local `pihemr-distro-spike` folder is noise (per the playbook's own note on such
  folders), not a real consumer — no action needed.
- Deciding the fate of `openmrs-distro-pihemr`'s `deploy-debian-build-docker.yml`
  (`partnersinhealth/debian-build` image publish) — flagged for likely removal once the new
  Debian job installs its own build tools directly, but confirm nothing else still pulls that
  image before deleting it.

## Repo rename

`openmrs-config-pihemr` → `pihemr` on GitHub. Root `pom.xml`: artifactId `openmrs-config-pihemr` →
`pihemr`, groupId stays `org.pih.openmrs`, `<name>`/`<description>`/`<url>`/`<scm>` updated to
match. Local remote and any bookmarks need updating after the GitHub-side rename.

## Versioning

Root version: `1.12.0-SNAPSHOT` → `3.0.0-SNAPSHOT`.

- `content/pom.xml` (`pihemr-content`): no version override, inherits root's `3.0.0-SNAPSHOT`
  automatically — same as `lesotho-content` inheriting `lesotho-emr`'s version.
- `distro/pom.xml` (`pihemr-distro`): keeps `<parent>org.openmrs.module:pihcore</parent>` (that's
  how it inherits the `omod.*`/`war.openmrs` version properties used by `openmrs-distro.properties`
  filtering), but explicitly overrides `<groupId>org.pih.openmrs</groupId>` and
  `<version>3.0.0-SNAPSHOT</version>` rather than inheriting pihcore's own groupId/version. It's
  still listed under the root's `<modules>` for reactor purposes — a module's reactor membership
  and its Maven `<parent>` are independent, so this isn't unusual.

## `content/` conversion

Per the playbook, mechanically:

- Drop `openmrs-packager-maven-plugin` from both the root `pom.xml` (including the
  `constants.properties` build filter) and `content/pom.xml`.
- `content/pom.xml` gains the plain `maven-resources-plugin` (filter `content.properties`,
  `process-resources` phase — not `generate-resources`, per the pihliberia learning about the
  plugin's real default binding) + `maven-assembly-plugin` (existing `assembly.xml` is already
  correct — it just zips `${project.build.directory}/package/**`).
- Hand-write `content/content.properties` by flattening the root `constants.yml`'s ~700 lines into
  dotted `var.*` keys. This is mechanical, not exploratory: the current build's
  `content/target/package/content.properties` already shows almost exactly the target output,
  since today's build performs this flattening automatically — the task is to capture that output
  as a tracked, hand-owned file instead of a build-time artifact, and then delete `constants.yml`.
- **No "hunt down constants missing from the repo's own file" step applies.** That playbook step
  exists because a child's `${...}` placeholders can silently depend on a *parent* content
  package's `content.properties` under the old merge-based model. `pihemr` has no parent content
  package — it's the top of the chain — so every constant used anywhere in its own
  `configuration/**` already has to live in its own file today, and will continue to.
- Split `configuration/` into `content/configuration/frontend_configuration/` (today's root-level
  `configuration/frontend/*`: `base-config.json`, `config.json`, `pih-logo.png`) and
  `content/configuration/backend_configuration/` (every other subdirectory), via `git mv`. Note the
  whole `configuration/` tree also moves from the repo root into `content/configuration/` as part
  of this — today's `create-content-package` goal reads `../configuration` (parent dir) from
  inside `content/`; the plain-resources approach expects it already inside `content/`, matching
  every migrated repo.
- Write `content/README.md` (doesn't exist today, unlike `lesotho-content`/`ces-content`)
  describing the two subdirectories.
- Update the root `README.md`'s ~15 hardcoded `configuration/...` links to include the
  `backend_configuration/`/`frontend_configuration/` segment, and its `github.com/PIH/openmrs-config-pihemr`
  links to `github.com/PIH/pihemr`.

## `distro/` module

New module, effectively `openmrs-distro-pihemr/pom.xml` relocated:

- `distro/pom.xml`: artifactId `pihemr` → `pihemr-distro`, groupId `org.openmrs.distro` →
  `org.pih.openmrs` (override), version → `3.0.0-SNAPSHOT` (override) as described above. Keeps
  the `maven-resources-plugin` (filter `openmrs-distro.properties`) and
  `openmrs-sdk-maven-plugin`'s `build-distro` execution unchanged — it builds the raw OpenMRS
  war+omods+owas with no content/frontend layering, exactly as today, since `pihemr` has no parent
  distro of its own to layer against.
- **Publishes the jar only** — no `maven-assembly-plugin`, no `assembly.xml`, no zip artifact, no
  `distro-zip` profile. `mvn deploy` publishes just `pihemr-distro-3.0.0-SNAPSHOT.jar`, matching
  what the five children actually consume (`<parentType>jar</parentType>`).
- The `distribution` profile (Debian packaging: copies `debian/**`, runs `build.sh`/`publish.sh`
  via `exec-maven-plugin`) is carried over into `distro/pom.xml` largely as-is — see CI below for
  how it gets invoked.
- `distro/openmrs-distro.properties`: carried over unchanged in content — no `content.*`/`spa.*`
  entries, since this is the top of the chain.
- `distro/debian/` (build.sh, publish.sh, `package/debian/**` control files, `Dockerfile`):
  relocated from the old repo's `debian/` unchanged, except `publish.sh` reads
  `DEBIAN_REPO_USER`/`DEBIAN_REPO_PASSWORD` directly from the environment instead of sourcing
  `~/.pihemr-debian-env` (GHA sets secrets as env vars, not a dotfile).
- `distro/README.md`: new, following the `lesotho-distro`/`README.md` shape.

## CI/CD

**`.github/workflows/build-and-deploy.yml`** (new, replaces `deploy.yml`): thin caller into
`openmrs-contrib-distro-tools`'s reusable `build-and-deploy.yml` (no `maven_profiles` input needed,
since there's no zip profile to activate), triggered on push to `master`. Preserves `deploy.yml`'s
five `repository_dispatch` steps (triggering `pihsl-emr`, `zl-emr`, `pihliberia-emr`, `ces-emr`,
`lesotho-emr` builds) as an additional job.

**New Debian job**, same workflow or a sibling `deploy-debian.yml`: `ubuntu-latest`,
`apt-get install devscripts build-essential lintian debhelper rename` directly (dropping the
`partnersinhealth/debian-build` Docker-image indirection — GHA installs these natively, one fewer
moving part), then `mvn -Pdistribution deploy --file distro/pom.xml` with
`DEBIAN_REPO_USER`/`DEBIAN_REPO_PASSWORD` as new GHA secrets.

**`.github/workflows/update-versions.yml`** (new): thin caller into the existing reusable
`update-versions.yml`, matching the five children.

**`.github/workflows/verify.yml`** and **`.github/workflows/release.yml`**: kept, but converted to
thin callers into two *new* reusable workflows added to `openmrs-contrib-distro-tools`:

- `openmrs-contrib-distro-tools/.github/workflows/verify.yml` (new): `workflow_call`, checkout,
  JDK 8/temurin with maven cache, `mvn clean verify --batch-mode --file pom.xml` — lifted from
  this repo's current `verify.yml` almost verbatim, generalized the same way `build-and-deploy.yml`
  already is.
- `openmrs-contrib-distro-tools/.github/workflows/release.yml` (new): `workflow_call`, checkout,
  JDK 8/temurin, git-config setup, `mvn -B release:prepare release:perform -Prelease --file pom.xml`,
  needs `SONATYPE_USERNAME`/`SONATYPE_PASSWORD`/`MAVEN_GPG_PASSPHRASE`/`MAVEN_GPG_KEY` secrets —
  lifted from this repo's current `release.yml` almost verbatim.
- Both get documented in that repo's README under its existing "CI: reusable workflows" section.
- This repo's own `verify.yml`/`release.yml` shrink to thin `uses:` callers, matching the
  `build-and-deploy.yml` pattern already established there.
- **Follow-up** (separate work, not this branch, per Non-goals): once these reusable workflows
  exist, add the same thin-caller `verify.yml`/`release.yml` to the five `xxx-emr` repos, which
  currently have neither.

**Not added**: `build-seeded-images.yml` — not needed for this repo.

## Companion-repo fallout

Checked and clean, per the playbook's standing step:

- `openmrs-module-pihcore`: no `generate-pihemr-config-constants` execution or
  `org.pih.openmrs:openmrs-config-pihemr:zip`/`pihemr-content:zip` dependency exists in
  `pom.xml`/`api/pom.xml` — this mechanism was only ever used by the child config repos referencing
  themselves, not the parent.
- No ETL project depends on `openmrs-config-pihemr`'s (or `pihemr`'s) compiled zip.
- Grepped every `pom.xml` under `~/code/github/pih/*` for `<artifactId>pihemr</artifactId>`: the
  only real consumers are `openmrs-distro-pihemr` itself and the five migrated children (via the
  `parentArtifact` property, not literal text) — plus the noise `pihemr-distro-spike` folder.

## Rollout sequence

1. Land the two new reusable workflows in `openmrs-contrib-distro-tools`.
2. Land this branch (`pihemr` rename, `content/` conversion, `distro/` module, CI) in what is today
   `openmrs-config-pihemr`.
3. Confirm `pihemr-distro`/`pihemr-content` publish successfully to Sonatype under the new
   coordinates and version.
4. Follow-up PRs against the five `xxx-emr` repos: bump `parentGroup`/`parentArtifact`/
   `parentVersion` to `org.pih.openmrs`/`pihemr-distro`/`3.0.0-SNAPSHOT`, and add the new
   `verify.yml`/`release.yml` thin callers.
5. Once all five have cut over and are confirmed building against the new coordinates, retire
   `openmrs-distro-pihemr`.
