import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/features/admin/providers/role_provider.dart';

/// หน้าจัดการสิทธิ์ผู้ใช้ (เฉพาะ admin) เปิด/ปิดสิทธิ์ admin ให้ผู้ใช้แต่ละคน
class RoleManagementScreen extends ConsumerWidget {
  const RoleManagementScreen({super.key});

  Future<void> _toggle(
    BuildContext context,
    AppUser user,
    bool makeAdmin,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await setAdminRole(user.uid, isAdmin: makeAdmin);
      messenger.showSnackBar(
        SnackBar(
          content: Text(makeAdmin
              ? 'ตั้ง ${_label(user)} เป็น Admin แล้ว'
              : 'ถอนสิทธิ์ Admin ของ ${_label(user)} แล้ว'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('เปลี่ยนสิทธิ์ไม่สำเร็จ: $e')));
    }
  }

  String _label(AppUser u) =>
      u.displayName.isNotEmpty ? u.displayName : (u.email.isNotEmpty ? u.email : u.uid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    final adminIds = ref.watch(adminIdsProvider).valueOrNull ?? const <String>{};
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการสิทธิ์ผู้ใช้')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('อ่านรายชื่อผู้ใช้ไม่ได้: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('ยังไม่มีผู้ใช้ในระบบ'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'เปิดสวิตช์เพื่อให้ผู้ใช้เป็น Admin (จัดการสถานะเรื่องร้องทุกข์ได้) '
                    'ผู้ใช้ต้องออกจากระบบแล้วเข้าใหม่ สิทธิ์จึงมีผล',
                  ),
                );
              }
              final user = list[index - 1];
              final isAdmin = adminIds.contains(user.uid);
              final isMe = user.uid == myUid;
              return SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor:
                      isAdmin ? AppColors.primary : AppColors.secondaryContainer,
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                    color: isAdmin ? Colors.white : AppColors.secondary,
                  ),
                ),
                title: Text(_label(user)),
                subtitle: Text(
                  [
                    if (user.email.isNotEmpty && user.email != _label(user)) user.email,
                    isAdmin ? 'Admin' : 'ผู้ใช้ทั่วไป',
                    if (isMe) '(คุณ)',
                  ].join(' · '),
                ),
                value: isAdmin,
                // ไม่ให้ถอนสิทธิ์ตัวเอง กันไม่มี admin เหลือ
                onChanged: isMe ? null : (v) => _toggle(context, user, v),
              );
            },
          );
        },
      ),
    );
  }
}
