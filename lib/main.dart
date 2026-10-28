import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_web_dashboard_screen.dart';
import 'features/navigation/screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  await initFirebase();
  runApp(
    const ProviderScope(
      child: BokMaiApp(),
    ),
  );
}

class BokMaiApp extends StatelessWidget {
  const BokMaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bok Mai (บอกไหม)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LayoutBuilder(
        builder: (context, constraints) {
          // ถ้าเปิดบน Web Desktop จอกว้างเกิน 1024px ให้เข้าหน้า Admin Web Dashboard
          // ถ้าเปิดบน iPad / Tablet / Mobile ให้เข้าหน้าแอป Bok Mai Responsive (Navigation Rail / Bottom Bar)
          if (kIsWeb && constraints.maxWidth >= 1024) {
            return const AdminWebDashboardScreen();
          }
          return const MainNavigationShell();
        },
      ),
    );
  }
}
