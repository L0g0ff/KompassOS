# release-canary

Maintainer-only tooling for the `release-candidate` promotion flow. This
directory is **not** part of the image build - it's not referenced from
`files/` or any recipe, and only needs to exist on the one machine doing the
canary testing. Nobody else gets this timer just by running
`:release-candidate`; it only runs where someone has manually installed it
below.

## What it does

1. Recipes push `release-candidate` instead of `latest` (see `alt-tags` in
   `recipes/recipe-dx-*.yml`).
2. You rebase your own machine onto `:release-candidate`.
3. `release-canary.timer` fires once, 1 hour after boot. If the booted
   deployment is a `release-candidate` build, `check-and-promote.sh` asks
   (via `kdialog`) whether to promote it.
4. On yes, it triggers `.github/workflows/promote.yml` with the exact image
   and digest that's been running for the last hour - not whatever
   `:release-candidate` happens to point at when the workflow runs, so a
   newer RC landing in the meantime can't get promoted by accident.
5. There's currently only a canary machine for the nvidia variant, so
   approving also promotes hwe and surface. Instead of trusting whichever
   `release-candidate` tag they currently point at (a scheduled rebuild
   could have already overwritten it - GitHub rebuilds daily even without
   new commits), the workflow matches them by build date: all 3 variants
   build in the same matrix run, so they share the
   `<date>-release-candidate-<os_version>` tag blue-build stamps on each
   build, which (unlike the bare `release-candidate` tag) isn't overwritten
   by the next day's rebuild. That tag only has day granularity though, so
   2 builds on the same day (schedule + a push both landed on 2026-09-05 in
   practice) would collide on it - the workflow also checks the sibling's
   actual `Created` timestamp is within 30 minutes of the tested build's,
   and refuses to promote it otherwise. If one of them failed to build that
   day, or its date-tagged build turns out to be a different same-day
   build, its `:latest` is simply left untouched - it doesn't block
   promoting the ones that did succeed. Once there's a canary per variant,
   this should take 3 separate tested image/digest pairs instead - see the
   comment in `promote.yml`.

   (Earlier version of this matched by git commit instead: broken, because
   the `org.opencontainers.image.revision` label on these images turns out
   to be inherited from the *base* image, not set from this repo's own
   commits - found by actually triggering promotion for real and watching
   it fail to find a match.)
6. Other users pulling `:latest` get that build after the workflow finishes.

## Install (once, on the canary machine)

```
mkdir -p ~/.local/bin ~/.config/systemd/user
cp check-and-promote.sh ~/.local/bin/
cp release-canary.service release-canary.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now release-canary.timer
```

Requires `jq`, `kdialog`, and an authenticated `gh` (`gh auth login`) with
rights to trigger workflows on `L0g0ff/KompassOS`. If `gh` (or anything
else the script calls) is installed somewhere not on `systemd --user`'s
default PATH - e.g. via linuxbrew, as on the canary machine right now -
the script has to add that directory to `PATH` itself; unit files don't
inherit an interactive shell's PATH.

## Verified end-to-end

Manually triggered via `systemctl --user start release-canary.service`
(bypassing the 1-hour timer) on 2026-09-05: the kdialog prompt showed up
correctly over the `systemd --user` D-Bus session, `gh workflow run` fired
`promote.yml` for real, and the tested nvidia digest was promoted to
`:latest`. First attempt failed with exit 127 (`gh` not on PATH, see
above) - fixed and re-verified.
