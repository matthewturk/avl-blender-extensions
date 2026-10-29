# AVL Blender Extensions

A Blender extension repository for the extensions listed in `repos.txt`:

- [Script Runner](https://github.com/matthewturk/blender-script-runner)
- [Adaptive Viewport Clipping](https://github.com/matthewturk/blender-viewport-clipping)
- [AVL GeoViz](https://github.com/matthewturk/blender-avl-geoviz)

## Adding it to Blender

1. Preferences > Get Extensions > Repositories (the drop-down at the top
   right) > **+** > Add Remote Repository.
2. URL: `https://matthewturk.github.io/avl-blender-extensions/index.json`
3. Make sure **Allow Online Access** is on (Preferences > System > Network).

The extensions then show up under Get Extensions, install with the right
build for your platform, and update like the ones from extensions.blender.org.
Turn on "Check for Updates on Startup" for the repository to be told about new
releases.

The index is also browsable at
<https://matthewturk.github.io/avl-blender-extensions/>; dragging a link from
that page into Blender installs it.

## How it works

`scripts/build_index.sh` downloads the `.zip` assets of each repo's latest
GitHub release, runs `blender --command extension server-generate` on them,
and points each `archive_url` at the release asset. Only `index.json` and
`index.html` are published to GitHub Pages; the zips stay on the release
pages (Pages rejects files over 100 MB, and the AVL GeoViz builds are bigger).

The `Publish index` workflow runs daily, on pushes to `main`, and from the
Actions tab ("Run workflow"), so a new release appears within a day, or right
away if you run it by hand. To add an extension, add its repo to `repos.txt`;
its releases need the built zip attached (as the release workflows in these
repos do). A repo with no release yet is skipped.

To have a release show up immediately, an extension's release workflow can
send a `repository_dispatch` of type `extension-released` to this repo. That
needs a token with access to this repo, stored as a secret in the extension's
repo, e.g. with `peter-evans/repository-dispatch@v3`.

Building locally:

```bash
scripts/build_index.sh /path/to/blender site
python3 -m http.server -d site 8000   # then add http://localhost:8000/index.json
```

## Setup (once)

Settings > Pages > Build and deployment > Source: **GitHub Actions**.
