wingpanel_dep = dependency('wingpanel-2.0')

shared_module(
    'sound-devices',
    [
        'Indicator.vala',
        'Widgets/MaxWidthLabel.vala',
        'Widgets/ChannelRadioButton.vala',
        'Widgets/PlugChannelList.vala',
        'Widgets/ClientView.vala',
        'Widgets/ClientList.vala',
        'Widgets/VolumeMeter.vala',
        'Widgets/ChannelView.vala',
        'Widgets/DeviceChannelList.vala',
        'Widgets/DeviceView.vala',
        'Widgets/DeviceList.vala',
        'Widgets/DeviceSettingsPage.vala',
        'Widgets/DeviceSettingsListRow.vala',
        'Widgets/DeviceSettingsList.vala',
        'Widgets/DisplayWidget.vala',
        'Widgets/MainView.vala'
    ],
    dependencies: [
        pantheon_sound_control_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libwnck-3.0'),
        wingpanel_dep
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

