import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:bok_mai_mobile/core/constants/ai_config.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/features/report/screens/report_form_screen.dart';

const _systemPrompt = '''
คุณคือ "ผู้ช่วยบอกไม" ผู้ช่วย AI ในแอปแจ้งปัญหาสาธารณะของเมืองในประเทศไทย
หน้าที่: ให้คำปรึกษาเรื่องปัญหาสาธารณะ เช่น ไฟฟ้า ประปา ถนน ขยะ ท่อระบายน้ำ น้ำท่วม ต้นไม้ล้ม สัตว์จรจัด
- ประเมินความอันตรายเบื้องต้น และบอกวิธีป้องกันตัวที่ปลอดภัย
- แนะนำหน่วยงานที่เกี่ยวข้อง เช่น การไฟฟ้านครหลวง 1130, การไฟฟ้าส่วนภูมิภาค 1129, การประปานครหลวง 1125,
  การประปาส่วนภูมิภาค 1662, กทม. 1555, ตำรวจ 191, ดับเพลิง 199, เจ็บป่วยฉุกเฉิน 1669
- ถ้ามีอันตรายต่อชีวิต (ไฟฟ้ารั่ว ไฟไหม้ มีคนบาดเจ็บ) ให้บอกให้โทรเบอร์ฉุกเฉินก่อนเสมอ
- ถ้าผู้ใช้เล่าปัญหาที่เกิดขึ้นจริงและควรแจ้งเจ้าหน้าที่ ให้ปิดท้ายคำตอบด้วยบรรทัด [[REPORT]] หนึ่งครั้ง
  แอปจะแสดงปุ่ม "แจ้งปัญหานี้" ที่ร่างฟอร์มให้อัตโนมัติ จึงไม่ต้องอธิบายขั้นตอนแจ้งในแอปทีละข้อ ให้บอกสั้นๆ ว่ากดปุ่มด้านล่างได้
  (ถ้าผู้ใช้แค่ถามความรู้ทั่วไป ไม่ได้เล่าปัญหาที่เจอ ห้ามใส่ [[REPORT]])
- ถ้าผู้ใช้ถามวิธีแจ้งในแอป: กดปุ่ม "แจ้งปัญหา" ถ่ายรูป เลือกหมวด ระดับความเร่งด่วน และปักหมุดตำแหน่งบนแผนที่
- คุณไม่สามารถส่งเรื่อง ดูสถานะเรื่อง หรือติดต่อเจ้าหน้าที่แทนผู้ใช้ได้ อย่าอ้างว่าทำแล้ว
- ถ้าไม่แน่ใจข้อมูล (เช่น เบอร์โทรท้องถิ่น) ให้บอกตรงๆ ว่าไม่แน่ใจ
- ตอบเป็นภาษาไทย กระชับ เป็นข้อความธรรมดา ไม่ใช้ Markdown (ห้ามใช้ ** หรือ #) ใช้ขีด - นำหน้าข้อได้
- คำถามที่ไม่เกี่ยวกับปัญหาสาธารณะ ให้ตอบสั้นๆ อย่างสุภาพแล้วชวนกลับมาที่เรื่องปัญหาในชุมชน
''';

const _suggestions = [
  'ไฟฟ้ารั่วที่เสาไฟหน้าบ้าน ควรทำอย่างไร',
  'น้ำท่วมขังในซอยหลายวันแล้ว แจ้งใครได้บ้าง',
  'ฝาท่อแตกกลางถนน อันตรายแค่ไหน',
  'แจ้งปัญหาในแอปต้องทำอย่างไร',
];

/// AI ใส่ตัวนี้ท้ายคำตอบเมื่อผู้ใช้เล่าปัญหาที่ควรแจ้ง (ตัดออกก่อนแสดง)
const _reportMarker = '[[REPORT]]';

/// ตัด marker (รวมถึงส่วนที่ stream มาไม่ครบ เช่น "[[REP") ออกจากข้อความที่จะแสดง
String _visibleText(String raw) => raw
    .replaceAll(_reportMarker, '')
    .replaceAll(RegExp(r'\[\[[A-Z]*\]?$'), '')
    .replaceAll('**', '')
    .trimRight();

class _Message {
  _Message(this.fromUser, this.raw, {this.isError = false});

  final bool fromUser;

  /// ข้อความดิบจาก AI (อาจมี marker)
  String raw;
  final bool isError;

  /// เรื่องที่ผู้ใช้เล่า ใช้ร่างฟอร์มเมื่อกด "แจ้งปัญหานี้" (null = ไม่แสดงปุ่ม)
  String? reportStory;

  String get text => fromUser ? raw : _visibleText(raw);
}

/// แชตบอตปรึกษาปัญหาสาธารณะ (Gemini ผ่าน Firebase AI Logic)
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  ChatSession? _chat;
  bool _sending = false;

  /// สลับไปรุ่นสำรองแล้ว (รุ่นหลักโควตาหมด/คนใช้เยอะ) ใช้ต่อจนเริ่มบทสนทนาใหม่
  bool _useFallback = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ChatSession _session() => _chat ??= AiConfig.generativeModel(
    systemInstruction: Content.system(_systemPrompt),
    fallback: _useFallback,
  ).startChat(history: _history());

  /// ประวัติแชตที่ตอบสำเร็จแล้ว (ไม่รวมข้อความล่าสุดที่กำลังส่ง และข้อความ error)
  /// ใช้ต่อบทสนทนาเดิมเมื่อสร้างเซสชันใหม่ เช่นตอนสลับไปรุ่นสำรอง
  List<Content> _history() {
    final done = _messages.length >= 2
        ? _messages.sublist(0, _messages.length - 2)
        : const <_Message>[];
    return [
      for (final m in done)
        if (!m.isError && m.raw.isNotEmpty)
          Content(m.fromUser ? 'user' : 'model', [TextPart(m.raw)]),
    ];
  }

  void _reset() {
    setState(() {
      _messages.clear();
      _chat = null;
      _useFallback = false;
    });
  }

  Future<void> _streamReply(String text, _Message reply) async {
    await for (final chunk in _session().sendMessageStream(Content.text(text))) {
      final part = chunk.text;
      if (part == null || !mounted) continue;
      setState(() => reply.raw += part);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// แปลง error ที่พบบ่อยเป็นข้อความที่บอกสาเหตุได้
  static String _errorReason(Object e) {
    final msg = e.toString();
    if (msg.contains('App Check')) {
      return 'ผู้ช่วย AI ถูก App Check บล็อก (ผู้ดูแลต้องตั้งค่า App Check หรือกด Unenforce ให้ Firebase AI Logic)';
    }
    if (msg.contains('to be enabled in your Firebase project') ||
        msg.contains('SERVICE_DISABLED') ||
        msg.contains('has not been used')) {
      return 'ผู้ช่วย AI ยังไม่ถูกเปิดใช้ (ผู้ดูแลต้องเปิด Firebase AI Logic ใน Firebase Console)';
    }
    if (msg.contains('quota') ||
        msg.contains('RESOURCE_EXHAUSTED') ||
        msg.contains('429')) {
      return 'มีผู้ใช้ผู้ช่วย AI มากเกินโควตาฟรีในขณะนี้ โปรดลองใหม่ภายหลัง';
    }
    if (msg.contains('503') ||
        msg.contains('UNAVAILABLE') ||
        msg.contains('overloaded')) {
      return 'ระบบ AI มีผู้ใช้งานหนาแน่นชั่วคราว โปรดลองใหม่อีกครั้งในอีกสักครู่';
    }
    return 'ตอนนี้ผู้ช่วย AI ไม่พร้อมใช้งาน โปรดตรวจอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    final reply = _Message(false, '');
    setState(() {
      _sending = true;
      _messages
        ..add(_Message(true, text))
        ..add(reply);
    });
    _scrollToEnd();

    try {
      try {
        await _streamReply(text, reply);
      } catch (e) {
        if (_useFallback || reply.raw.isNotEmpty || !AiConfig.shouldFallback(e)) rethrow;
        debugPrint('AI chat: รุ่นหลักใช้ไม่ได้ สลับไปรุ่นสำรอง: $e');
        _useFallback = true;
        _chat = null;
        await _streamReply(text, reply);
      }
      if (reply.text.trim().isEmpty) throw StateError('empty response');
      if (reply.raw.contains(_reportMarker) && mounted) {
        // ร่างจากทุกข้อความที่ผู้ใช้เล่าในบทสนทนานี้ (รายละเอียดอาจกระจายหลายข้อความ)
        final story = _messages
            .where((m) => m.fromUser)
            .map((m) => m.raw)
            .join('\n');
        setState(() => reply.reportStory = story);
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      if (!mounted) return;
      setState(() {
        _messages
          ..remove(reply)
          ..add(_Message(false, _errorReason(e), isError: true));
        // ข้อความที่ล้มเหลวอาจค้างในประวัติแชต เริ่มเซสชันใหม่ให้ข้อความถัดไป
        _chat = null;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ช่วย AI'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'เริ่มบทสนทนาใหม่',
              onPressed: _sending ? null : _reset,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyState(theme)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _bubble(theme, _messages[i]),
                  ),
          ),
          _composer(theme),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.smart_toy_rounded, size: 56, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          'ปรึกษาปัญหาในชุมชน',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ถามได้ว่าปัญหาอันตรายแค่ไหน ควรรับมืออย่างไร หรือควรแจ้งหน่วยงานไหน',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed: () => _send(s),
              child: Text(s),
            ),
          ),
      ],
    );
  }

  Widget _bubble(ThemeData theme, _Message m) {
    final bg = m.fromUser
        ? AppColors.primary
        : m.isError
        ? AppColors.errorContainer
        : AppColors.surfaceContainerHigh;
    final fg = m.fromUser
        ? AppColors.onPrimary
        : m.isError
        ? AppColors.onErrorContainer
        : AppColors.onSurface;
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(
              m.fromUser ? AppRadius.lg : AppRadius.xs,
            ),
            bottomRight: Radius.circular(
              m.fromUser ? AppRadius.xs : AppRadius.lg,
            ),
          ),
        ),
        child: m.text.isEmpty
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    m.text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                  if (m.reportStory != null) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _openReport(m.reportStory!),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('แจ้งปัญหานี้'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// เปิดฟอร์มแจ้งปัญหา ให้ AI ร่างหัวข้อ/หมวด/ความเร่งด่วนจากเรื่องที่ผู้ใช้เล่า
  void _openReport(String story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportFormScreen(initialStory: story)),
    );
  }

  Widget _composer(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์คำถามเกี่ยวกับปัญหาในชุมชน...',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'ส่ง',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI อาจตอบผิดได้ · เหตุฉุกเฉินโทร 191 ตำรวจ · 199 ดับเพลิง · 1669 เจ็บป่วย',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
