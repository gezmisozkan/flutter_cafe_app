import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'common/services/remote_config_provider.dart';
import 'widgets/error_banner.dart';

class CafeApp extends ConsumerWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);
    final rc = ref.watch(appRemoteConfigProvider);

    return MaterialApp.router(
      title: 'Cafe Loyalty',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return Column(
          children: [
            // Error and connectivity banners
            const ErrorBanner(),
            // Maintenance banner
            if (rc.maintenance)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Maintenance mode — some features may be unavailable',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(appRemoteConfigProvider.notifier)
                              .refresh(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child!),
          ],
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
    );
  }
}
