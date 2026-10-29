import 'package:flutter/material.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/data/services/speech_service.dart';
import 'package:bok_mai_mobile/features/report/screens/report_form_screen.dart';

/// หน้า Voice-to-Report: เปิดมาเริ่มฟังทันที พูดจบแล้วพาไปหน้าฟอร์มที่ AI ร่างให้
///
/// [returnStory] = true เมื่อเปิดจากหน้าฟอร์มอยู่แล้ว จะส่งข้อความกลับแทนการเปิดฟอร์มใหม่
class VoiceReportScreen extends StatefulWidget {
  const VoiceReportScreen({super.key, this.returnStory = false});

  final bool returnStory;

  @override
  State<VoiceReportScreen> createState() => _VoiceReportScreenState();
}

class _VoiceReportScreenState extends State<VoiceReportScreen> {
  final _speech = SpeechService();
  final _typeController = TextEditingController();
  String _transcript = '';
  bool _listening = false;
  bool _finished = false;
  bool _typing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _speech.cancel();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _transcript = '';
      _error = null;
      _finished = false;
    });
    final started = await _speech.start(
      onResult: (text) {
        if (mounted) setState(() => _transcript = text);
      },
      onDone: _onDone,
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() {
      _listening = started;
      if (!started)
        _error = 'ใช้ไมโครโฟนไม่ได้ โปรดอนุญาตสิทธิ์ไมค์ หรือพิมพ์เล่าปัญหาแทน';
    });
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
    } else {
      await _start();
    }
  }

  void _onDone() {
    if (!mounted || !_listening) return;
    setState(() => _listening = false);
    final text = _transcript.trim();
    if (text.isEmpty) {
      setState(() => _error = 'ไม่ได้ยินเสียงพูด กดไมค์แล้วลองพูดใหม่อีกครั้ง');
      return;
    }
    _finish(text);
  }

  /// ส่งเรื่องที่เล่าไปให้ฟอร์ม (AI จะร่างหัวข้อ/หมวด/ความเร่งด่วนให้ที่หน้าฟอร์ม)
  void _finish(String story) {
    if (_finished) return;
    _finished = true;
    if (widget.returnStory) {
      Navigator.pop(context, story);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportFormScreen(initialStory: story),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Voice-to-Report')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                _listening
                    ? 'กำลังฟัง... เล่าปัญหาที่พบได้เลย'
                    : 'กดไมค์แล้วพูดเล่าปัญหาที่พบ',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'เช่น "ต้นไม้ล้มขวางถนนหน้าซอยฉลองกรุง 41 มีสายไฟพาดอยู่"\n'
                'พูดจบแล้ว AI จะร่างแบบฟอร์มให้ ตรวจแก้ได้ก่อนส่ง',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              _MicButton(listening: _listening, onPressed: _toggle),
              const SizedBox(height: 32),
              // ข้อความที่ถอดจากเสียง ขึ้นสดระหว่างพูด
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  _transcript.isEmpty
                      ? (_error ?? 'คำที่พูดจะขึ้นตรงนี้')
                      : _transcript,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _transcript.isEmpty
                        ? (_error != null ? AppColors.error : AppColors.outline)
                        : AppColors.onSurface,
                  ),
                ),
              ),
              if (_listening && _transcript.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _speech.stop,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('พูดจบแล้ว ไปที่แบบฟอร์ม'),
                ),
              ],
              const Spacer(),
              if (_typing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _typeController,
                        autofocus: true,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) _finish(v.trim());
                        },
                        decoration: InputDecoration(
                          hintText: 'พิมพ์เล่าปัญหาที่พบ...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'ไปที่แบบฟอร์ม',
                      onPressed: () {
                        final v = _typeController.text.trim();
                        if (v.isNotEmpty) _finish(v);
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () {
                    _speech.cancel();
                    setState(() {
                      _listening = false;
                      _typing = true;
                    });
                  },
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('พูดไม่สะดวก? พิมพ์แทน'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onPressed});

  final bool listening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = listening ? AppColors.error : AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(listening ? 18 : 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: listening ? 0.15 : 0.08),
      ),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 112,
            height: 112,
            child: Icon(
              listening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
