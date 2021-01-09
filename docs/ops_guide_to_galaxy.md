# ~~hitchhiker's~~ Ops guide to the galaxy

This document has the objective to address several questions that starts with "How do I ... ?"


# How do I revbump a package? (and when it's actually needed?)

By convention, we have chosen to increment the version of a package after the `+`, following [semver](https://semver.org/) notation.

That means, if a package version is at `1.0.0`, it's revbump version would be `1.0.0+1`, and a subsequent one would be for example `1.0.0+2`.

## When I do need to revbump a package?

A Package revbump is necessary when you apply changes to `build.yaml`, although, it's not always necessary, but just in few cases:

- When you change `steps` in the `build.yaml`
- When you change `prelude` in the `build.yaml`

## What about packages depending on it?

Always by convention, we have chosen to revbump __manually__ those. Luet does support tracking automatically new package versions, but we want to make this transparent in the Git repository, so reverting changes introduced by mistakes it's easier, and so we also rely on the caching mechanism of Luet.

If we don't revbump reverse dependencies our CI would skip such changes, because we enforced this by policy.

## How do I do that?

Until https://github.com/mocaccinoOS/desktop/issues/7 is delivered, it is a manual process.

# How do I add a useflag to a Portage package? 

# How do I try my changes?

# How do I update provides list, and what are they?

# How do I add a package?

# How do I know that a package belongs to a Layer?