# Application releases

The community and enterprise application images share a version and source
commit, but are separate builds with separate license labels. The community
image uses `GLOSSIA_EDITION=core`; the enterprise image includes `ee/`.

## On merge

1. A push to `main` affecting application image inputs runs the **App** workflow,
   including build and test checks for both editions. Translation-only
   checkpoints remain excluded to avoid restarting active translation work.
2. After those checks succeed, **Publish Production Images** checks out that
   exact commit with complete history. Pull request runs, forks, failed checks,
   and runs superseded by a newer `main` commit cannot publish.
3. `prepare-app-release.sh` uses `app/cliff.toml` to detect unreleased
   Conventional Commits and calculate the next `app-vX.Y.Z` tag. This follows
   Tuist's component-specific server release pattern: serialize detection through
   publication, use local PR links rather than per-commit GitHub API requests,
   and pin the release tag to the built commit. CLI and SDK tags are independent.
4. Both editions are built and pushed to the GitHub Container Registry. Their
   Mix release version and container version label use the calculated version.
5. Only after **both** image builds succeed does the workflow create the app's
   GitHub Release, with generated notes, both image references, and the source
   commit. It does not write a changelog commit or push to `main`.

The first app release is `app-v0.1.0`. Features bump the minor version, fixes
bump the patch version, and breaking changes follow git-cliff's semantic-version
rules. Documentation, refactoring, performance, styling, and test commits also
participate. Routine `chore:`, `ci:`, and `build:` commits do not create a version
unless they declare a breaking change. Maintenance builds still update the main
and commit tags, preserving the latest released app version inside the image;
they do not update stable version tags or `latest` aliases.

Release inputs include `app/`, `ee/`, the embedded CLI and browser SDK, and the
root license files. Unrelated Babel and infrastructure commits do not create app
releases. Skipped/pending merges are covered cumulatively by the next run.

## Image tags

All images use `ghcr.io/glossia/glossia`. For example, release `app-v1.2.3`
publishes:

| Tag | Edition | Purpose |
| --- | --- | --- |
| `1.2.3-community` | Community | Versioned Apache-2.0 release |
| `1.2.3-enterprise` | Enterprise | Versioned source-available enterprise release |
| `latest-community` | Community | Most recently released community version |
| `latest-enterprise` | Enterprise | Most recently released enterprise version |
| `main-community` | Community | Most recently published checked main build |
| `main-enterprise` | Enterprise | Most recently published checked main build |
| `<commit>-community` | Community | Specific source commit |
| `<commit>-enterprise` | Enterprise | Specific source commit |

Unsuffixed `1.2.3`, `latest`, `main`, and `<commit>` tags are community-only
compatibility aliases. Numbered `main-<run>-<commit>` tags are retained with
community and enterprise variants. No enterprise image receives an unsuffixed
tag. For reproducibility, pin an image digest rather than a mutable alias.

The public Helm chart defaults to community via `main`. Glossia's production
Flux policy explicitly watches `main-enterprise`. Enterprise production use
requires the written agreement described in [`ee/LICENSE.md`](../ee/LICENSE.md).
App releases use `app-v*`, CLI releases use `cli-v*`, and SDK releases use
`sdk-v*`. App releases do not replace the repository-wide latest release, which
is also used by other components.

## Failure and retry behavior

Release runs are serialized with `cancel-in-progress: false`; they must not be
manually cancelled halfway through publication. If one image build fails, no
app GitHub Release is created. One edition's image tags may already have been
pushed: registries cannot atomically update two independent images. Fix the
failure and rerun the failed jobs before treating the version as released.
If release creation itself fails, rerun that job with the preserved release-note
artifact. Tags are always attached to the tested source commit, never whichever
commit happens to be at `main` when the release finishes.

## Local checks

With the repository's git-cliff version, Git, jq, and Node.js available:

```sh
node --test .github/tests/*.test.cjs
```

The release tests create disposable repositories and run the real git-cliff
configuration and shell scripts. They cover independent tags, initial releases,
patch/minor/breaking bumps, enterprise-only changes, embedded components,
maintenance commits, cumulative merges, repeated runs, and image-tag isolation.
Do not dispatch a production release simply to test the automation.
