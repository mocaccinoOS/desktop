# [![Packages](https://packages.mocaccino.org/badge/mocaccino-desktop-stable.svg "List of packages")](https://packages.mocaccino.org/mocaccino-desktop) :computer: mocaccinoOS Desktop repository

This repository contains the package definitions used to build the MocaccinoOS Desktop distribution. Packages are organized to produce reproducible binary builds while remaining compatible with the Gentoo ecosystem.

Unlike traditional Linux distributions that expose users to hundreds of low-level packages and dependencies, MocaccinoOS groups related runtime components into **layers**. A layer represents a complete, installable software stack that provides everything required for a specific purpose.

For example, installing the KDE Plasma desktop is as simple as:

```bash
luet install layers/plasma
```

The `layers/plasma` package pulls in all required runtime components, libraries, services, and applications needed to provide a fully functional Plasma desktop. Users do not need to understand or manually manage the underlying dependency tree.

The goal is to make software installation and removal as straightforward as installing an application on Android: install a layer, use it, and remove it when it is no longer needed.

This philosophy differs significantly from the approach taken by [Mocaccino Micro](https://github.com/mocaccinoOS/mocaccino-micro), which follows a Linux From Scratch (LFS) model where packages are built and managed individually in a traditional package hierarchy.

For MocaccinoOS Desktop, binary packages are delivered as complete, reproducible artifacts, enabling low-friction, over-the-air (OTA)-style updates while preserving the flexibility of the Gentoo ecosystem.


## Why is MocaccinoOS Desktop different?

MocaccinoOS Desktop is designed around the idea that installing and maintaining software should be simple. Instead of exposing users to hundreds of individual packages and their dependencies, software is delivered as complete layers or applications that include everything required to run, or share common runtime layers where appropriate (for example, GTK-based desktop environments such as MATE and GNOME).

This approach significantly reduces the complexity of package management while enabling low-friction, OTA-style system updates. Users can focus on the software they want to use rather than the dependencies required to make it work.

From a developer's perspective, MocaccinoOS Desktop provides a flexible and reproducible package build system powered by Luet. Package definitions can be developed and tested locally using Docker, or built at scale using Kubernetes, making it easy to iterate on changes while producing consistent binary packages.


## Documentation

- [Ops guide](https://www.mocaccino.org/docs/desktop/development/)
- [Luet docs](https://luet-lab.github.io/docs/)

## Repository layout

Luet does not enforce a specific repository structure, so the MocaccinoOS Desktop packages are organized into the following directories:

* `packages/images` – Container images and other external images consumed during package builds.
* `packages/apps` – End-user applications that can be installed individually.
* `packages/layers` – Layer packages that provide complete runtime environments or software stacks (for example, desktop environments).
* `packages/meta` – Meta-packages that group multiple related packages under a single installable package.
* `packages/virtual` – Virtual packages used to satisfy dependencies without providing installable content themselves.
* `packages/mocaccino` – MocaccinoOS-specific packages, including branding, configuration, and distribution integration.

## Package structure

Each package is stored in its own directory and contains the metadata and build instructions required by Luet. A typical package looks like this:

```text
packages/apps/firefox/
├── build.yaml
├── definition.yaml
└── finalizer.yaml
```

The most common files are:

* `definition.yaml` – Defines the package metadata, version, dependencies, labels, and other package information.
* `build.yaml` – Describes how the package is built and assembled.
* `finalizer.yaml` *(optional)* – Executes actions after installation, such as updating caches, generating configuration, or performing other system integration tasks.

Depending on the package, additional files and directories may be present, such as patches, configuration files, helper scripts, or build assets.
