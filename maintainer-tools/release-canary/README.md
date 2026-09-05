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
   `release-candidate` tag they currently point at (a later rebuild could
   have already overwritten it - build.yml can run several times a day),
   the workflow checks each sibling's current `release-candidate` was
   `Created` within 5 minutes of the tested build - all 3 variants build in
   the same matrix run and get pushed within seconds of each other, so a
   close match is a strong signal without needing any of git commit,
   build date, or GitHub's run history. If a sibling's build failed, or its
   current tag turns out to be from an unrelated, later build, its
   `:latest` is simply left untouched - it doesn't block promoting the ones
   that did succeed. Once there's a canary per variant, this should take 3
   separate tested image/digest pairs instead - see the comment in
   `promote.yml`.

   Promotion itself uses `crane tag`, not `skopeo copy`: a registry tag is
   just a pointer to an existing digest, and crane updates that pointer
   directly without touching any content. This matters because
   `release-candidate` is a multi-arch OCI index (an amd64 manifest plus a
   build attestation) - `skopeo copy --all` was tried first and re-encoded
   the layers during copy, changing the digest and breaking the signature;
   `--preserve-digests` was tried next and refused to write the index at
   all. With `crane tag`, `:latest` ends up as the exact same digest as
   `release-candidate` (verified: same digest, same index structure, valid
   `cosign verify`), so they show up grouped together in the registry UI
   instead of `:latest` sitting there as a separate, unlabelled entry.

   (Two earlier, abandoned approaches are preserved in git history for
   context: matching by git commit was broken because
   `org.opencontainers.image.revision` on these images is inherited from
   the *base* image, not set from this repo's own commits; matching by a
   `<date>-release-candidate-<os_version>` tag name broke down as soon as 2
   builds landed on the same day, which happens in practice.)
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

After several more iterations on the sibling-matching logic and the
`crane tag` switch (see `promote.yml`'s comments and git history), all 3
variants were promoted together in one run and independently confirmed:
`:latest` and `:release-candidate` resolve to the identical digest for
hwe, hwe-nvidia, and surface, and `cosign verify` passes for all three.
