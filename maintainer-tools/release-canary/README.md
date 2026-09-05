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
   `release-candidate` tag they currently point at (a same-commit scheduled
   rebuild could have already overwritten it - GitHub rebuilds daily even
   without new commits), the workflow looks up the exact `build.yml` run
   that produced the tested digest and reads hwe/surface's digest straight
   out of *that same run's* job logs. If one of them failed or isn't found
   in that run, its `:latest` is simply left untouched - it doesn't block
   promoting the ones that did succeed. Once there's a canary per variant,
   this should take 3 separate tested image/digest pairs instead - see the
   comment in `promote.yml`.
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
rights to trigger workflows on `L0g0ff/KompassOS`.

## Not yet verified

This has not been run end-to-end (no real hour-long boot + systemd user
timer + kdialog session-bus test yet). Things worth checking once you try
it for real:
- that `systemctl --user` units reliably reach the graphical session's
  D-Bus so `kdialog` actually shows a dialog instead of failing silently
- that `gh auth status` inside a timer-triggered unit still finds your
  credentials (env/credential helper differences between an interactive
  shell and a systemd user unit)
