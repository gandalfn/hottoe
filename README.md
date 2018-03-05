# Suka Hottoe

Suka Hottoe is an application which can control sound devices. The main functionality of this app is to detect a new plug sound device (HDMI cable for example) and associate easely a sound application on it. It purpose more or less the same fonctionnalities than pulseaudio pavucontrol app, but integrated to [elementary desktop](http://elementary.io).

It is composed of an indicator and a switchboard plug. The indicator applet detect new sound devices and new sound applications, and allows to associate any sound applications to particular device. The switchboard plug allow a more advanced configuration tool of each devices and each sound applications.

![Screenshot](data/indicator-screenshot.png?raw=true)

![Screenshot](data/switchboard-screenshot.png?raw=true)

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
    libcanberra-gtk-dev
    meson
    valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
