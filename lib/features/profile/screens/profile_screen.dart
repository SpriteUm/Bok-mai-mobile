import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/admin/screens/admin_web_dashboard_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isAdminMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    backgroundColor: _isAdminMode
                        ? AppColors.primary
                        : AppColors.secondaryContainer,
                    child: Icon(
                      _isAdminMode
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_rounded,
                      size: 36,
                      color: _isAdminMode ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAdminMode ? 'เจ้าหน้าที่เทศบาล (Admin)' : 'ประชาชนผู้แจ้งเหตุ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAdminMode
                              ? 'สิทธิ์: จัดการสถานะงาน, แนบรูปหลักฐาน'
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

          // Role Switcher Card
          Card(
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
                    subtitle: Text(_isAdminMode ? 'สถานะ: โหมดเจ้าหน้าที่' : 'สถานะ: โหมดประชาชน'),
                    value: _isAdminMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isAdminMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shortcut to Web Dashboard
          if (_isAdminMode)
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

          // App Settings & Info
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('นโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)'),
            subtitle: Text('ข้อมูลใบหน้าและป้ายทะเบียนถูกเบลอก่อนส่ง'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('เวอร์ชันแอป'),
            subtitle: Text('Bok Mai v1.0.0 (Flutter + Supabase + Gemini)'),
          ),
        ],
      ),
    );
  }
}

