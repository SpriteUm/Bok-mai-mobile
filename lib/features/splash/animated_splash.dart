import 'package:flutter/material.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';

/// หน้าเปิดแอป: โลโก้เด้งขึ้นมา ตามด้วยชื่อแอป แล้วจางหายเข้าสู่ [child]
/// [child] ถูกสร้างไว้ด้านล่างตั้งแต่แรก การล็อกอิน/โหลดข้อมูลจึงเริ่มระหว่างเล่น animation
/// พื้นหลังขาวเหมือน splash ของระบบ เพื่อให้ต่อกันเนียน
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // เริ่มที่ขนาดเดียวกับโลโก้ใน splash ของระบบ (128dp กลางจอ) แล้วย่อ-เด้ง-กลับที่
  late final _logoScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.82,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.82,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 30,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
  ]).animate(_controller);
  late final _textIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
  );
  late final _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.82, 1, curve: Curves.easeIn),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ผู้ใช้ปิด animation ในระบบ: ข้าม splash
    if (MediaQuery.disableAnimationsOf(context) && !_done) {
      _controller.value = 1;
      _done = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: 1 - _exit.value,
              child: Material(
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // โลโก้อยู่กลางจอพอดีเหมือน splash ของระบบ ตอนออกขยายนิดหน่อย
                    Transform.scale(
                      scale: _logoScale.value * (1 + 0.15 * _exit.value),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        width: 128,
                      ),
                    ),
                    // ชื่อแอปวางใต้โลโก้ ไม่ดันโลโก้ให้เลื่อน
                    Transform.translate(
                      offset: Offset(0, 120 + 16 * (1 - _textIn.value)),
                      child: Opacity(
                        opacity: _textIn.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bok Mai',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'บอกไหม · แจ้งปัญหาในเมืองของคุณ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
