import 'package:flutter/material.dart';
// import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'features/home/pages/home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// import 'package:logging/logging.dart' as logging;
// Theme is now managed in SettingsProvider
import 'theme/theme_factory.dart';
import 'theme/palettes.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/mcp_provider.dart';
import 'core/providers/tts_provider.dart';
import 'core/providers/assistant_provider.dart';
import 'core/providers/update_provider.dart';
import 'core/providers/pwa_provider.dart';
import 'core/services/chat/chat_service.dart';
import 'core/services/mcp/mcp_tool_service.dart';
import 'utils/sandbox_path_resolver.dart';
import 'shared/widgets/snackbar.dart';
import 'shared/widgets/pwa_install_banner.dart';
import 'shared/widgets/offline_indicator.dart';
import 'shared/widgets/pwa_update_banner.dart';

final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();
bool _didCheckUpdates = false; // one-time update check flag
bool _didEnsureAssistants = false; // ensure defaults after l10n ready

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 只进行关键的系统UI设置
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 立即启动应用，其他初始化延后
  runApp(const MyApp());

  // 延迟所有非关键初始化
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SandboxPathResolver.init();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 最关键的Provider - 立即初始化
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // 次关键的Provider - 延迟初始化以优化启动速度
        ChangeNotifierProvider(create: (_) => UserProvider(), lazy: true),

        // 懒加载Provider - 延迟初始化以优化启动时间
        ChangeNotifierProvider(create: (_) => ChatProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ChatService(), lazy: true),
        ChangeNotifierProvider(create: (_) => McpToolService(), lazy: true),
        ChangeNotifierProvider(create: (_) => McpProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AssistantProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => TtsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UpdateProvider(), lazy: true),

        // PWA Provider - 仅在Web平台初始化
        if (kIsWeb)
          ChangeNotifierProvider(create: (_) => PWAProvider(), lazy: true),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          // One-time app update check after first build
          if (settings.showAppUpdates && !_didCheckUpdates) {
            _didCheckUpdates = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                context.read<UpdateProvider>().checkForUpdates();
              } catch (_) {}
            });
          }

          // 延迟初始化PWA服务 (仅Web平台)，改为延迟2秒初始化以优化启动速度
          if (kIsWeb) {
            Future.delayed(const Duration(seconds: 2), () {
              try {
                context.read<PWAProvider>().initialize();
              } catch (_) {}
            });
          }
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              // if (lightDynamic != null) {
              //   debugPrint('[DynamicColor] Light dynamic detected. primary=${lightDynamic.primary.value.toRadixString(16)} surface=${lightDynamic.surface.value.toRadixString(16)}');
              // } else {
              //   debugPrint('[DynamicColor] Light dynamic not available');
              // }
              // if (darkDynamic != null) {
              //   debugPrint('[DynamicColor] Dark dynamic detected. primary=${darkDynamic.primary.value.toRadixString(16)} surface=${darkDynamic.surface.value.toRadixString(16)}');
              // } else {
              //   debugPrint('[DynamicColor] Dark dynamic not available');
              // }
              final isAndroid =
                  Theme.of(context).platform == TargetPlatform.android;
              // Update dynamic color capability for settings UI (avoid notify during build)
              final dynSupported =
                  isAndroid && (lightDynamic != null || darkDynamic != null);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  settings.setDynamicColorSupported(dynSupported);
                } catch (_) {}
              });

              final useDyn = isAndroid && settings.useDynamicColor;
              final palette = ThemePalettes.byId(settings.themePaletteId);

              final light = buildLightThemeForScheme(
                palette.light,
                dynamicScheme: useDyn ? lightDynamic : null,
              );
              final dark = buildDarkThemeForScheme(
                palette.dark,
                dynamicScheme: useDyn ? darkDynamic : null,
              );
              // Log top-level colors likely used by widgets (card/bg/shadow approximations)
              // debugPrint('[Theme/App] Light scaffoldBg=${light.colorScheme.surface.value.toRadixString(16)} card≈${light.colorScheme.surface.value.toRadixString(16)} shadow=${light.colorScheme.shadow.value.toRadixString(16)}');
              // debugPrint('[Theme/App] Dark scaffoldBg=${dark.colorScheme.surface.value.toRadixString(16)} card≈${dark.colorScheme.surface.value.toRadixString(16)} shadow=${dark.colorScheme.shadow.value.toRadixString(16)}');
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Kelivo',
                // App UI language; null = follow system (respects iOS per-app language)
                locale: settings.appLocaleForMaterialApp,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: light,
                darkTheme: dark,
                themeMode: settings.themeMode,
                navigatorObservers: <NavigatorObserver>[routeObserver],
                home: const HomePage(),
                builder: (ctx, child) {
                  final bright = Theme.of(ctx).brightness;
                  final overlay = bright == Brightness.dark
                      ? const SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          statusBarIconBrightness: Brightness.light,
                          statusBarBrightness: Brightness.dark,
                          systemNavigationBarColor: Colors.transparent,
                          systemNavigationBarIconBrightness: Brightness.light,
                          systemNavigationBarDividerColor: Colors.transparent,
                          systemNavigationBarContrastEnforced: false,
                        )
                      : const SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          statusBarIconBrightness: Brightness.dark,
                          statusBarBrightness: Brightness.light,
                          systemNavigationBarColor: Colors.transparent,
                          systemNavigationBarIconBrightness: Brightness.dark,
                          systemNavigationBarDividerColor: Colors.transparent,
                          systemNavigationBarContrastEnforced: false,
                        );
                  // Ensure localized defaults (assistants and chat default title) after first frame
                  if (!_didEnsureAssistants) {
                    _didEnsureAssistants = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        ctx.read<AssistantProvider>().ensureDefaults(ctx);
                      } catch (_) {}
                      try {
                        ctx.read<ChatService>().setDefaultConversationTitle(
                          AppLocalizations.of(
                            ctx,
                          )!.chatServiceDefaultConversationTitle,
                        );
                      } catch (_) {}
                      try {
                        ctx.read<UserProvider>().setDefaultNameIfUnset(
                          AppLocalizations.of(ctx)!.userProviderDefaultUserName,
                        );
                      } catch (_) {}
                    });
                  }

                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: overlay,
                    child: AppSnackBarOverlay(
                      child: Stack(
                        children: [
                          child ?? const SizedBox.shrink(),
                          // PWA相关UI组件 (仅Web平台)
                          if (kIsWeb) ...[
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: OfflineIndicator(),
                            ),
                            const Positioned(
                              bottom: 80,
                              left: 0,
                              right: 0,
                              child: PWAInstallBanner(),
                            ),
                            const Positioned(
                              top: 80,
                              left: 0,
                              right: 0,
                              child: PWAUpdateBanner(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
