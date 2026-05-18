import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/routes/app_pages.dart';
import 'src/constants/app_colors.dart';
import 'src/constants/app_translations.dart';
import 'src/rust/rust_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  RustBridge.initialize();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitle('app_name'.tr);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_name'.tr,
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        textTheme: GoogleFonts.notoSansScTextTheme(const TextTheme(
          titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: Color(0xFF595959)),
        )),
        primaryTextTheme: GoogleFonts.notoSansScTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textDark,
          iconTheme: IconThemeData(color: AppColors.primary),
          shape: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
      ),
    );
  }
}
