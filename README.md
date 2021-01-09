# desktop

This repository contains installable "apps" that we refer internally as "layers" to install common suite of packages needed to bootstrap a pure and simple OS.

A User, should be able then to install KDE by calling `luet install layers/KDE` and nothing else. That package should bring all the necessary components to make the "app" work as expected. The user shouldn't be exposed to the typical OS architecture of bringing with it dozens of dependencies. 

Think at it like Android apps: Install and uninstall should be as simple as installing an app.