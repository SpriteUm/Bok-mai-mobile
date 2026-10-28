import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/admin/screens/admin_web_dashboard_screen.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _demoAdminMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final user = firebaseReady ? ref.watch(authStateProvider).valueOrNull : null;
    // ใช้ Firebase: สิทธิ์ admin มาจาก Custom Claim / ไม่ใช้: สลับโหมดสาธิตได้
    final isAdminMode = firebaseReady
        ? (ref.watch(isAdminProvider).valueOrNull ?? false)
        : _demoAdminMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('บัญชีผู้ใช้และสิทธิ์'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isAdminMode
                        ? AppColors.primary
                        : AppColors.secondaryContainer,
                    child: Icon(
                      isAdminMode
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_rounded,
                      size: 36,
                      color: isAdminMode ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? (user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : (user.email ?? 'ผู้ใช้'))
                              : (isAdminMode ? 'เจ้าหน้าที่เทศบาล (Admin)' : 'ประชาชนผู้แจ้งเหตุ'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAdminMode
                              ? 'สิทธิ์: เจ้าหน้าที่ (Admin) จัดการสถานะงาน'
                              : 'สิทธิ์: แจ้งปัญหา, กด +1 ติดตาม, ประเมินงาน',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Role Switcher Card (เฉพาะโหมดสาธิต)
          if (!firebaseReady) Card(
            color: AppColors.primaryContainer.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'จำลองสลับบทบาท (Demo Role Switcher)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สลับเป็นมุมมองเจ้าหน้าที่เทศบาลเพื่อดูภาพรวมและทดลองอัปเดตสถานะงาน',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เปิดใช้งานโหมดเจ้าหน้าที่เทศบาล (Admin)'),
                    subtitle: Text(isAdminMode ? 'สถานะ: โหมดเจ้าหน้าที่' : 'สถานะ: โหมดประชาชน'),
                    value: _demoAdminMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _demoAdminMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shortcut to Web Dashboard
          if (isAdminMode)
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminWebDashboardScreen()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text(
                'เปิดเข้าสู่ Admin Dashboard Portal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 24),

          if (user != null) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('ออกจากระบบ'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 24),
          ],

          // App Settings & Info
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('นโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)'),
            subtitle: Text('ข้อมูลใบหน้าและป้ายทะเบียนถูกเบลอก่อนส่ง'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('เวอร์ชันแอป'),
            subtitle: Text('Bok Mai v1.0.0 (Flutter + Firebase + Gemini)'),
          ),
        ],
      ),
    );
  }
}

