# Axmol Engine with [xmake](https://github.com/xmake-io/xmake) support

## A Multi-platform Engine for Mobile, Desktop and Xbox.

[Axmol Engine](https://axmol.dev) is an open-source, C++ multi-platform engine designed for mobile devices, desktop, and Xbox, well-suited for 2D game development. It was launched in November 2019 as a fork of Cocos2d-x v4.0.

Original repo [here](https://github.com/axmolengine/axmol/)

## What's done
Right now only Linux is supported and some parts of the codebase.
For now, the project is required to be used as submodule. I will convert it to xmake package for xmake-repo after supporting all options.

## What I want to achieve
As I understand, Axmol downloads some dependencies via Powershell and has other dependencies in the repository which I don't like.
I prefer having to download and build dependencies via package manager and have the project's source code alone in the repository.