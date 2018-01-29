wingpanel_dep = dependency('wingpanel-2.0')

libpantheon_sound_control_widgets = static_library (
    meson.project_name() + '-widgets',
    [
        'Widgets/MaxWidthLabel.vala',
        'Widgets/VolumeMeter.vala',
        'Widgets/ChannelView.vala',
        'Widgets/DeviceChannelList.vala'
    ],
    dependencies: [
        pantheon_sound_control_dep,
        dependency('granite'),
        dependency('gtk+-3.0')
    ],
    install: false
)

shared_module(
    'sound-devices-indicator',
    [
        'Indicator.vala',
        'Widgets/IndicatorIcon.vala',
        'Widgets/IndicatorView.vala',
        'Widgets/ClientView.vala',
        'Widgets/ClientList.vala',
        'Widgets/PlugChannelList.vala',
        'Widgets/ChannelRadioButton.vala',
        'Widgets/DeviceView.vala',
        'Widgets/DeviceList.vala'
    ],
    dependencies: [
        pantheon_sound_control_dep,
        wingpanel_dep,
        dependency('libwnck-3.0')
    ],
    link_with: [
        libpantheon_sound_control_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    'sound-devices-plug',
    [
        'SwitchboardPlug.vala',
        'Widgets/DeviceSettingsView.vala',
        'Widgets/DeviceSettingsPage.vala',
        'Widgets/DeviceSettingsListRow.vala',
        'Widgets/DeviceSettingsList.vala',
        'Widgets/PlugSettingsRow.vala',
        'Widgets/PlugSettingsList.vala'
    ],
    dependencies: [
        pantheon_sound_control_dep,
        switchboard_dep,
        dependency('granite'),
        dependency('libwnck-3.0')
    ],
    link_with: [
        libpantheon_sound_control_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : switchboard_dep.get_pkgconfig_variable('plugsdir')
)
