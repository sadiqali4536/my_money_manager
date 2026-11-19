import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/controllers/app_lock_controller.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/utils/financial_controller.dart';
import 'app/data/database/hive_database_helper.dart';
import 'app/features/main_navigation/main_navigation_screen.dart';

import 'app/features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Local Vault Storage
  await HiveDatabaseHelper.instance.init();

  // Register Global Controllers
  Get.put(FinancialController());
  Get.put(AppLockController());

  runApp(const MyMoneyManagerApp());
}

class MyMoneyManagerApp extends StatelessWidget {
  const MyMoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'my money manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
