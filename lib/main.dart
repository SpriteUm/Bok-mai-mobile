import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_web_dashboard_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/navigation/screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  final firebaseReady = await initFirebase();
  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const BokMaiApp(),
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
      home: const AuthGate(),
    );
  }
}

/// ถ้า Firebase พร้อม: ต้องล็อกอินก่อน และเฉพาะ admin (Custom Claim) บนเว็บจอกว้างที่เข้า Dashboard
/// ถ้า Firebase ไม่พร้อม: รันด้วยข้อมูลจำลองเหมือนเดิม
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firebaseReadyProvider)) {
      // โหมดข้อมูลจำลอง: เว็บจอกว้างเข้า Dashboard เหมือนเดิม
      return const _AppHome(isAdmin: false, demoWideWeb: true);
    }

    return ref.watch(authStateProvider).when(
          loading: () => const _Splash(),
          error: (e, _) => Scaffold(body: Center(child: Text('เกิดข้อผิดพลาด: $e'))),
          data: (user) {
            if (user == null) return const LoginScreen();
            ref.watch(ensureProfileProvider);
            return ref.watch(isAdminProvider).when(
                  loading: () => const _Splash(),
                  error: (_, _) => const _AppHome(isAdmin: false),
                  data: (isAdmin) => _AppHome(isAdmin: isAdmin),
                );
          },
        );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AppHome extends StatelessWidget {
  const _AppHome({required this.isAdmin, this.demoWideWeb = false});

  final bool isAdmin;
  final bool demoWideWeb;

  @override
  Widget build(BuildContext context) {
    // admin ล็อกอินแล้วเข้า Admin Dashboard ทันที (สลับไปมุมมองผู้ใช้ได้จากปุ่มบนแถบด้านบน)
    if (isAdmin) return const AdminWebDashboardScreen();

    if (demoWideWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (kIsWeb && constraints.maxWidth >= 1024) {
            return const AdminWebDashboardScreen();
          }
          return const MainNavigationShell();
        },
      );
    }
    return const MainNavigationShell();
  }
}
