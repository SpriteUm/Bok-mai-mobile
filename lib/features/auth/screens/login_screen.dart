import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/auth/session_timeout.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้สมัครแล้ว';
      case 'weak-password':
        return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
      case 'operation-not-allowed':
        return 'ยังไม่ได้เปิดวิธีเข้าสู่ระบบนี้ใน Firebase Console '
            '(Authentication → Sign-in method)';
      case 'account-exists-with-different-credential':
        return 'อีเมลนี้สมัครด้วยรหัสผ่านไว้แล้ว ให้เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน';
      case 'popup-blocked':
        return 'เบราว์เซอร์บล็อกหน้าต่างเข้าสู่ระบบ โปรดอนุญาตป๊อปอัปแล้วลองใหม่';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      default:
        return 'เข้าสู่ระบบไม่สำเร็จ (${e.code})';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = FirebaseAuth.instance;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final name = _nameController.text.trim();
        await cred.user!.updateDisplayName(name);
        try {
          // เจ้าของสร้าง users/{uid} ของตัวเองได้ตาม firestore.rules
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'displayName': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } on FirebaseException catch (e) {
          // สมัครสำเร็จแล้ว แค่สร้างเอกสารโปรไฟล์ไม่ได้ ไม่ขวางการใช้งาน
          debugPrint('สร้าง users/{uid} ไม่สำเร็จ: ${e.code}');
        }
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// เข้าสู่ระบบด้วย Google (OAuth ผ่าน Firebase Auth) ครั้งแรกจะสร้างบัญชีให้อัตโนมัติ
  /// โปรไฟล์ users/{uid} สร้างโดย ensureProfileProvider โดยใช้ชื่อจากบัญชี Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      // ผู้ใช้ปิดหน้าต่างเลือกบัญชีเอง ไม่ต้องแสดงข้อผิดพลาด
      const cancelled = {'popup-closed-by-user', 'cancelled-popup-request', 'web-context-canceled', 'canceled'};
      if (mounted && !cancelled.contains(e.code)) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 96,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primary,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, _) {
                      if (!ref.watch(sessionExpiredProvider)) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: AppColors.statusPending),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text('หมดเวลาการใช้งานเพราะไม่ได้เปิดแอปนาน กรุณาเข้าสู่ระบบใหม่'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'อีเมล'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'กรุณากรอกอีเมลให้ถูกต้อง'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null,
                    textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: (_) => _isSignUp || _busy ? null : _submit(),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่านอีกครั้ง';
                        if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                        return null;
                      },
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('หรือ', style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    label: const Text('ดำเนินการต่อด้วย Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                              _confirmController.clear();
                            }),
                    child: Text(
                      _isSignUp
                          ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                          : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
