# Custom Kernel Patches

This directory contains additional kernel patches that are applied **after**
the Gentoo kernel patches during the MocaccinoOS kernel build.

## How it works

The `prepare.sh` script (run during the build) automatically applies any
`*.patch` files found here. Patches are applied in alphabetical order,
so use numbered prefixes to control the sequence:

```
0001-fix-something.patch
0002-add-feature.patch
0003-another-fix.patch
```

## Patch format

Patches must be in unified diff format (`diff -u` or `git format-patch`)
and apply with `patch -p1` from inside the kernel source tree.

## What happens on failure

If a patch fails to apply, the build **continues** with a warning — it does
not stop. Check the build log for messages like:

```
Applying custom patch: 0001-foo.patch
Warning: Failed to apply 0001-foo.patch, continuing...
```

A `.rej` file will be left in the kernel tree so you can inspect what
failed.

## Gentoo patches vs. custom patches

- **Gentoo patches** are fetched automatically by `fetch-gentoo-patches.sh`
  from the Gentoo linux-patches repository.
- **Custom patches** in this directory are yours — they are applied on top
  of the Gentoo set.

