# Clipped
Search and paste from your clipboard history.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.davidmhewitt.clipped)

![Clipped Screenshot](https://github.com/davidmhewitt/clipped/raw/master/data/com.github.davidmhewitt.clipped.screenshot.png)

## Building, Testing, and Installation

You'll need the following dependencies to build:
* meson
* libgtk-3-dev
* valac
* libsqlite3-dev
* libgee-0.8-dev

## How To Build

```bash
git clone https://github.com/davidmhewitt/clipped
cd clipped
meson build --prefix=/usr && cd build 
ninja install
```

## Run

```bash
com.github.davidmhewitt.clipped
```