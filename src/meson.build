wingpanel_dep = dependency('wingpanel-2.0')

libsuka_hottoe_widgets = static_library (
    meson.project_name() + '.widgets',
    [
        'Widgets/MaxWidthLabel.vala',
        'Widgets/Icon.vala',
        'Widgets/PortIcon.vala',
        'Widgets/DeviceIcon.vala',
        'Widgets/ClientIcon.vala',
        'Widgets/VolumeMeter.vala',
        'Widgets/ChannelView.vala',
        'Widgets/DeviceChannelList.vala',
        'Services/Notification.vala',
        'Services/SoundNotification.vala',
        'Services/DesktopNotification.vala'
    ],
    dependencies: [
        suka_hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libcanberra'),
        dependency('libcanberra-gtk'),
        dependency('libwnck-3.0')
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: false
)

shared_module(
    meson.project_name() + '.indicator',
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
        suka_hottoe_dep,
        wingpanel_dep,
        dependency('libwnck-3.0')
    ],
    link_with: [
        libsuka_hottoe_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name() + '.plug',
    [
        'SwitchboardPlug.vala',
        'Widgets/DeviceSettingsView.vala',
        'Widgets/DeviceSettingsPage.vala',
        'Widgets/DeviceSettingsListRow.vala',
        'Widgets/DeviceSettingsList.vala',
        'Widgets/PlugSettingsRow.vala',
        'Widgets/PlugSettingsList.vala',
        'Widgets/PlugChooser.vala',
        'Widgets/PlugChooserRow.vala'
    ],
    dependencies: [
        suka_hottoe_dep,
        switchboard_dep,
        dependency('granite'),
        dependency('libwnck-3.0')
    ],
    link_with: [
        libsuka_hottoe_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'hardware')
)
