import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/i18n_helper.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/i18n/system_locale_service.dart';
import 'package:zephyr/page/font_setting/view/font_setting_page.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/page/setting/global/widgets.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class AppearanceSettingPage extends StatelessWidget {
  const AppearanceSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;

    return SettingPageShell(
      title: t.settings.appearance,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.appearance,
            icon: Icons.palette_outlined,
          ),
          _languageTile(context, state, cubit),
          _systemTheme(state, cubit),
          _dynamicColor(state, cubit),
          if (!state.dynamicColor) changeThemeColor(context),
          _comicReadTopContainer(state, cubit),
          _isAMOLED(state, cubit),
          _fontSettings(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _languageTile(
    BuildContext context,
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    final labels = {
      null: t.settings.followSystemLanguage,
      for (final appLocale in AppLocale.values)
        I18nHelper.toFlutterLocale(appLocale): I18nHelper.displayName(
          appLocale,
        ),
    };

    final currentValue = state.localeFollowsSystem ? null : state.locale;
    final currentLabel = labels[currentValue]!;

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(t.settings.language),
      subtitle: Text(t.settings.languageSubtitle),
      trailing: FluentDropdown<Locale?>(
        value: currentValue,
        displayValue: currentLabel,
        items: labels,
        onChanged: (value) async {
          if (value == currentValue) return;
          if (value == null) {
            final systemInfo = await SystemLocaleService.getInfo();
            await cubit.setSystemLocale(systemInfo.locale);
          } else {
            await cubit.setLocale(value, followsSystem: false);
          }
          if (context.mounted) {
            showInfoToast(t.settings.languageChangedRestartHint);
          }
        },
      ),
    );
  }

  Widget _systemTheme(GlobalSettingState state, GlobalSettingCubit cubit) {
    final themeItems = <ThemeMode, String>{
      ThemeMode.system: t.common.followSystem,
      ThemeMode.light: t.common.lightMode,
      ThemeMode.dark: t.common.darkMode,
    };

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(t.settings.theme),
      subtitle: Text(t.settings.themeSubtitle),
      trailing: FluentDropdown<ThemeMode>(
        value: state.themeMode,
        displayValue: themeItems[state.themeMode]!,
        items: themeItems,
        onChanged: (ThemeMode value) {
          cubit.updateState((current) => current.copyWith(themeMode: value));
        },
      ),
    );
  }

  Widget _dynamicColor(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.color_lens_outlined),
      title: Text(t.settings.dynamicColor),
      subtitle: Text(t.settings.dynamicColorSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.dynamicColor,
      onChanged: (bool value) {
        cubit.updateState((current) => current.copyWith(dynamicColor: value));
      },
    );
  }

  Widget _fontSettings(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.font_download_outlined),
      title: Text(t.settings.fontSettings),
      subtitle: Text(t.settings.fontSettingsSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FontSettingPage()));
      },
    );
  }

  Widget _isAMOLED(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.contrast_outlined),
      title: Text(t.settings.amoled),
      subtitle: Text(t.settings.amoledSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.isAMOLED,
      onChanged: (bool value) {
        cubit.updateState((current) => current.copyWith(isAMOLED: value));
      },
    );
  }

  Widget _comicReadTopContainer(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.smartphone_outlined),
      title: Text(t.settings.notchAdaptation),
      subtitle: Text(t.settings.notchAdaptationSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.readSetting.comicReadTopContainer,
      onChanged: (bool value) {
        cubit.updateReadSetting(
          (current) => current.copyWith(comicReadTopContainer: value),
        );
      },
    );
  }
}
