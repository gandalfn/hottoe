# Pantheon Sound Control

![Screenshot](data/indicator.png?raw=true)

![Screenshot](data/switchboard.png?raw=true)

## Building and Installation

You'll need the following dependencies:

    libglib2.0-dev
    libgranite-dev
    libgtk-3-dev
    libwingpanel-2.0-dev
    libswitchboard-2.0-dev
    libwnck-3-dev
    libgee-0.8-dev
    libpulse-dev
    meson
    valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
