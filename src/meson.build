
vala_files = [
    'Application.vala',
    'Dialogs/EndSessionDialog.vala',
    'Dialogs/HelpDialog.vala',
    'Helpers/Inhibitor.vala',
    'Helpers/KeyboardLayoutHelper.vala',
    'Helpers/LocaleHelper.vala',
    'Helpers/LogHelper.vala',
    'MainWindow.vala',
    'Objects/Configuration.vala',
    'Objects/InstallOptions.vala',
    'Objects/Mount.vala',
    'Utils.vala',
    'Views/AbstractInstallerView.vala',
    'Views/CheckView.vala',
    'Views/DiskView.vala',
    'Views/EncryptView.vala',
    'Views/ErrorView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Views/PartitioningView.vala',
    'Views/ProgressView.vala',
    'Views/SuccessView.vala',
    'Views/TimezoneView.vala',
    'Views/TryInstallView.vala',
    'Views/UserView.vala',
    'Widgets/DecryptMenu.vala',
    'Widgets/DiskBar.vala',
    'Widgets/DiskGrid.vala',
    'Widgets/ErrorRevealer.vala',
    'Widgets/InstallTypeGrid.vala',
    'Widgets/LayoutWidget.vala',
    'Widgets/PartitionBar.vala',
    'Widgets/PartitionMenu.vala',
    'Widgets/Terminal.vala',
    'Widgets/Username.vala',
    'Widgets/VariantWidget.vala'
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))
configuration_data.set('PREFERRED_LANG_LIST', get_option('preferred_languages'))

config_file = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: configuration_data
)

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : dependencies,
           install: true)
