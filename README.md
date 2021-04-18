# :computer: mocaccinoOS Desktop repository

This repository contains installable "apps" that we refer internally as "layers" to install common suite of packages needed to bootstrap a pure and simple OS.

A User, should be able then to install the Plasma desktop by calling `luet install layers/plasma` and nothing else. That package should bring all the necessary components to make the "app" work as expected. The user shouldn't be exposed to the typical OS architecture of bringing with it dozens of dependencies. 

Think at it like Android apps: Install and uninstall should be as simple as that.

This approach is completely different from [Mocaccino Micro](https://github.com/mocaccinoOS/mocaccino-micro), which is a LFS and all packages are compiled 1:1. 

In this repository, updates are OTA-alike, with less friction as possible.

## Why MOS is different?

For the user, MOS Desktop is a pure and simple OS. We target to deliver an unique approach on package installation and upgrades. Applications should bundle all the required dependencies in order to run, or alternatively share common layers that are used between them (for example think about MATE, GNOME, and all software that depends on GTK). This allows users to have OTA-alike updates, without having to struggle with all packages dependencies.

From a developer standpoint, MOS takes a unique approach on package building, allowing developers to iterate locally changes to the packages very easily, thanks to the Luet flexible backend approach. You can use Docker to build packages locally, or Kubernetes to build them in your cluster

## Documentation

- [Ops guide](https://www.mocaccino.org/docs/desktop/development/)
- [Luet docs](https://luet-lab.github.io/docs/)

## Repository layout

As Luet doesn't impose any specific repository layout, we decided to split packages in the following directories:

- `packages/images`: External images that are consumed by other packages
- `packages/apps`: Contains all installable applications by end-users
- `packages/layers`: Contains all installable layers by end-users
- `packages/meta`: Contains meta packages, used to group multiple packages
- `packages/virtual`: Virtual packages which are used to provide dependencies for other packages
- `packages/mocaccino`: Packages used for branding, or MOS setup
