import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(l10n?.language ?? 'Language', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButton<Locale>(
              value: locale ?? const Locale('en'),
              items: [
                DropdownMenuItem(value: const Locale('en'), child: Text(l10n?.langEnglish ?? 'English')),
                DropdownMenuItem(value: const Locale('fr'), child: Text(l10n?.langFrench ?? 'Français')),
                DropdownMenuItem(value: const Locale('es'), child: Text(l10n?.langSpanish ?? 'Español')),
                DropdownMenuItem(value: const Locale('de'), child: Text(l10n?.langGerman ?? 'Deutsch')),
                DropdownMenuItem(value: const Locale('ar'), child: Text(l10n?.langArabic ?? 'العربية')),
              ],
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
