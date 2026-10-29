import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:bok_mai_mobile/core/constants/map_config.dart';
import 'package:bok_mai_mobile/core/constants/cloudinary_config.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_item.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_provider.dart';
import 'package:bok_mai_mobile/data/services/face_blur_service.dart';
import 'package:bok_mai_mobile/data/services/place_search_service.dart';
import 'package:bok_mai_mobile/data/services/voice_report_drafter.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/report/screens/location_picker_screen.dart';
import 'package:bok_mai_mobile/features/report/screens/voice_report_screen.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.editing, this.initialStory});

  /// ถ้าส่งมา = โหมดแก้ไขรายงานเดิม (แก้ได้เฉพาะข้อความ หมวดหมู่ และความเร่งด่วน)
  final IncidentModel? editing;

  /// เรื่องที่ผู้ใช้เล่าไว้ (เช่นจากแชตผู้ช่วย AI) ให้ AI ร่างฟอร์มทันทีที่เปิด
  final String? initialStory;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryNoteController = TextEditingController();

  /// ที่อยู่เกิดเหตุ: กรอกให้อัตโนมัติจากจุดที่ปักหมุด แก้เองได้
  final _locationController = TextEditingController();

  /// ที่อยู่ล่าสุดที่ระบบกรอกให้ ถ้าผู้ใช้แก้เองแล้วจะไม่เขียนทับ
  String _autoAddress = '';
  bool _lookingUpAddress = false;

  IncidentCategory _selectedCategory = IncidentCategory.road;

  /// ความเร่งด่วนเบื้องต้นจาก AI (ผู้แจ้งไม่ได้เลือกเอง เจ้าหน้าที่เป็นผู้ตัดสินลำดับความสำคัญจริง)
  IncidentUrgency _selectedUrgency = IncidentUrgency.medium;

  /// ข้อความ (หัวข้อ+รายละเอียด) ที่ AI ประเมินความเร่งด่วนไปแล้ว ถ้าข้อความเปลี่ยนจะประเมินใหม่ตอนส่ง
  String? _urgencyAssessedFor;

  /// จุดเกิดเหตุที่จะส่ง: เริ่มจาก GPS แล้วผู้ใช้ปรับเองบนแผนที่ได้
  LatLng? _pickedPoint;
  bool _locating = false;
  final List<_Photo> _photos = [];
  final ImagePicker _picker = ImagePicker();

  bool _drafting = false;

  /// ช่องเล่าปัญหาแบบแชต (พิมพ์ หรือข้อความที่ถอดจากเสียงจะขึ้นที่นี่)
  final _storyController = TextEditingController();

  /// ข้อความล่าสุดที่ผู้ใช้เล่า และคำตอบว่าร่างอะไรให้ (แสดงเป็นบับเบิลแชต)
  String? _lastStory;
  String? _draftReply;
  bool _draftReplyFromAi = false;

  /// เบลอใบหน้าอัตโนมัติ (PDPA) เปิดไว้เสมอบนมือถือ บนเว็บใช้ไม่ได้ (ML Kit ไม่รองรับ)
  bool _isAutoBlurEnabled = FaceBlurService.isSupported;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleController.text = e.title;
      _descController.text = e.description;
      _locationController.text = e.locationAddress;
      _categoryNoteController.text = e.categoryNote;
      _selectedCategory = e.category;
      _selectedUrgency = e.urgency;
      _urgencyAssessedFor = _storyKey();
    } else {
      _useCurrentLocation(silent: true);
      final story = widget.initialStory?.trim() ?? '';
      if (story.isNotEmpty) {
        _drafting = true;
        _lastStory = story;
        _draftFrom(story);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryNoteController.dispose();
    _storyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final photo = _Photo(picked, await picked.readAsBytes());
      if (!mounted) return;
      setState(() => _photos.add(photo));
      if (_isAutoBlurEnabled) await _blur(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')));
      }
    }
  }

  /// เบลอใบหน้าในรูป (บนเครื่อง) แล้วแสดงรูปที่เบลอแล้วเป็นตัวอย่าง
  Future<void> _blur(_Photo photo) async {
    if (photo.blurred != null || photo.blurring) return;
    setState(() {
      photo.blurring = true;
      photo.error = null;
    });
    try {
      final result = await FaceBlurService().blurFaces(photo.file);
      photo.blurred = result.bytes;
      photo.faceCount = result.faceCount;
    } catch (e) {
      debugPrint('เบลอใบหน้าไม่สำเร็จ: $e');
      photo.error = 'เบลอไม่สำเร็จ';
    } finally {
      if (mounted) setState(() => photo.blurring = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// เปิดหน้า Voice-to-Report พูดจบแล้วส่งข้อความกลับมาให้ AI ร่างฟอร์มนี้
  Future<void> _openVoicePage() async {
    if (_drafting) return;
    final story = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const VoiceReportScreen(returnStory: true),
      ),
    );
    if (story == null || story.trim().isEmpty || !mounted) return;
    _storyController.text = story.trim();
    await _sendStory();
  }

  /// ส่งเรื่องที่เล่า (พิมพ์หรือพูด) ให้ AI ร่างฟอร์ม เหมือนส่งข้อความในแชต
  Future<void> _sendStory() async {
    final text = _storyController.text.trim();
    if (text.isEmpty || _drafting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _drafting = true;
      _lastStory = text;
      _draftReply = null;
      _storyController.clear();
    });
    await _draftFrom(text);
  }

  /// ให้ AI ร่างฟอร์มจากข้อความ (เสียงที่ถอดแล้ว หรือที่พิมพ์) ผู้ใช้ตรวจแก้ได้ก่อนส่ง
  Future<void> _draftFrom(String transcript) async {
    try {
      final draft = await ref
          .read(voiceReportDrafterProvider)
          .draft(transcript);
      if (!mounted) return;
      final category =
          draft.category == IncidentCategory.other &&
              draft.categoryNote.isNotEmpty
          ? 'อื่นๆ: ${draft.categoryNote}'
          : IncidentModel.labelFor(draft.category);
      setState(() {
        _titleController.text = draft.title;
        _descController.text = draft.description;
        _selectedCategory = draft.category;
        _categoryNoteController.text = draft.categoryNote;
        _selectedUrgency = draft.urgency;
        _draftReplyFromAi = draft.aiDrafted;
        _urgencyAssessedFor = _storyKey();
        _draftReply = draft.aiDrafted
            ? 'ร่างให้แล้ว: ${draft.title} ($category)'
            : 'ใช้ AI ไม่ได้ตอนนี้ โปรดตรวจหัวข้อและหมวดหมู่';
      });
    } catch (e) {
      // ร่างไม่ได้ก็เก็บข้อความที่เล่าไว้ในช่องรายละเอียด ไม่ให้เสียข้อความผู้ใช้
      if (!mounted) return;
      setState(() {
        _descController.text = transcript;
        _draftReplyFromAi = false;
        _draftReply = 'ร่างไม่สำเร็จ ใส่ข้อความไว้ในรายละเอียดแล้ว';
      });
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  bool _submitting = false;

  /// พิกัดปัจจุบันจาก GPS หรือ null ถ้าไม่ได้สิทธิ์/ปิด GPS
  Future<LatLng?> _gpsPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// ใช้ตำแหน่ง GPS ปัจจุบันเป็นจุดเกิดเหตุ ([silent] = ตอนเปิดฟอร์ม ไม่ทับจุดที่ผู้ใช้เลือกเองแล้ว)
  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _locating = true);
    final point = await _gpsPosition();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null && (!silent || _pickedPoint == null))
        _pickedPoint = point;
    });
    if (point != null && _pickedPoint == point) _fillAddress(point);
    if (!silent) {
      _showMessage(
        point == null
            ? 'หาตำแหน่งปัจจุบันไม่ได้ โปรดเปิด GPS หรือเลือกจุดบนแผนที่เอง'
            : 'อัปเดตพิกัด GPS ปัจจุบันแล้ว',
      );
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _pickedPoint ?? MapConfig.defaultCenter,
          onLocateMe: _gpsPosition,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _pickedPoint = picked);
    _fillAddress(picked);
  }

  /// แปลงพิกัดที่เลือกเป็นที่อยู่ แล้วกรอกให้ (ไม่ทับที่อยู่ที่ผู้ใช้พิมพ์เอง)
  Future<void> _fillAddress(LatLng point) async {
    final current = _locationController.text.trim();
    if (current.isNotEmpty && current != _autoAddress) return;
    setState(() => _lookingUpAddress = true);
    final address = await PlaceSearchService().reverse(point);
    if (!mounted) return;
    setState(() {
      _lookingUpAddress = false;
      // ระหว่างรอ ผู้ใช้อาจพิมพ์เองแล้ว หรือเลือกจุดใหม่ไปแล้ว
      final now = _locationController.text.trim();
      if (address != null &&
          _pickedPoint == point &&
          (now.isEmpty || now == _autoAddress)) {
        _locationController.text = address;
        _autoAddress = address;
      }
    });
  }

  String _storyKey() =>
      '${_titleController.text.trim()}\n${_descController.text.trim()}';

  /// AI คัดกรองความเร่งด่วนเบื้องต้นด้วยเกณฑ์เดียวกันทุกเรื่อง (ประเมินใหม่เมื่อข้อความเปลี่ยน)
  /// ถ้า AI ใช้ไม่ได้ ระบบเดาจากคำสำคัญแทน เจ้าหน้าที่ปรับลำดับความสำคัญจริงได้ภายหลัง
  Future<IncidentUrgency> _screenUrgency({bool online = true}) async {
    final key = _storyKey();
    if (key == _urgencyAssessedFor) return _selectedUrgency;
    try {
      final drafter = online
          ? ref.read(voiceReportDrafterProvider)
          : const KeywordReportDrafter();
      final draft = await drafter.draft(
        'หัวข้อ: ${_titleController.text.trim()}\nรายละเอียด: ${_descController.text.trim()}',
      );
      _selectedUrgency = draft.urgency;
      _urgencyAssessedFor = key;
    } catch (_) {
      // คัดกรองไม่ได้ก็ใช้ค่าเดิม เจ้าหน้าที่ตัดสินอยู่แล้ว
    }
    return _selectedUrgency;
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    if (!ref.read(firebaseReadyProvider) ||
        ref.read(authStateProvider).valueOrNull == null) {
      _showMessage(
        'แก้ไขได้เมื่อเชื่อมต่อ Firebase และเข้าสู่ระบบแล้วเท่านั้น',
      );
      return;
    }
    setState(() => _submitting = true);
    final urgency = await _screenUrgency();
    try {
      await ref
          .read(incidentRepositoryProvider)
          .updateIssue(
            widget.editing!.copyWith(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory,
              categoryNote: _categoryNoteController.text.trim(),
              urgency: urgency,
              locationAddress: _locationController.text.trim(),
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        'แก้ไขไม่สำเร็จ (แก้ได้เฉพาะเรื่องที่รอดำเนินการและไม่มีคนกด +1 ร่วม): $e',
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    _showMessage('บันทึกการแก้ไขแล้ว');
  }

  Future<void> _submitReport() async {
    if (_isEdit) return _saveEdit();
    if (!_formKey.currentState!.validate() || _submitting) return;
    // PDPA: เปิดเบลอไว้ ต้องเบลอสำเร็จทุกรูปก่อน ห้ามส่งรูปที่ยังไม่เบลอขึ้นไปเงียบๆ
    if (_isAutoBlurEnabled && _photos.isNotEmpty) {
      if (_photos.any((p) => p.blurring)) {
        _showMessage('กำลังเบลอใบหน้าในรูป รอสักครู่แล้วกดส่งอีกครั้ง');
        return;
      }
      if (_photos.any((p) => p.blurred == null)) {
        _showMessage(
          'มีรูปที่เบลอใบหน้าไม่สำเร็จ ลบรูปนั้นหรือถ่ายใหม่ก่อนส่ง',
        );
        return;
      }
    }
    setState(() => _submitting = true);

    final online = await hasNetwork();
    final urgency = await _screenUrgency(online: online);
    final position =
        _pickedPoint ?? await _gpsPosition() ?? MapConfig.defaultCenter;
    final firebaseReady = ref.read(firebaseReadyProvider);

    // รูปที่จะส่ง: ฉบับเบลอใบหน้าถ้าเปิดเบลอไว้ (สูงสุด 5 รูปตาม firestore.rules)
    var images = <Uint8List>[
      for (final p in _photos.take(5))
        _isAutoBlurEnabled && p.blurred != null ? p.blurred! : p.original,
    ];
    String? imageWarning;
    if (images.isNotEmpty && firebaseReady && !CloudinaryConfig.isConfigured) {
      images = [];
      imageWarning =
          'ส่งรายงานแล้ว แต่ยังไม่ได้ตั้งค่า Cloudinary จึงไม่ได้แนบรูป';
    }

    final draft = IncidentModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      categoryNote: _categoryNoteController.text.trim(),
      status: IncidentStatus.pending,
      urgency: urgency,
      locationAddress: _locationController.text.trim(),
      latitude: position.latitude,
      longitude: position.longitude,
      imageUrls: const [],
      upvoteCount: 1,
      hasUpvoted: true,
      createdAt: DateTime.now(),
    );

    if (!firebaseReady) {
      // โหมดข้อมูลจำลอง (Firebase ไม่พร้อม)
      ref
          .read(incidentFeedProvider.notifier)
          .addLocal(
            draft.copyWith(id: 'inc-${DateTime.now().millisecondsSinceEpoch}'),
          );
      if (!mounted) return;
      Navigator.pop(context);
      _showResult('ส่งรายงานปัญหาสำเร็จ!', AppColors.statusResolved);
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      setState(() => _submitting = false);
      _showMessage('ต้องเข้าสู่ระบบก่อนส่งรายงาน');
      return;
    }

    // ทุกรายงานเข้ากล่องรอส่งก่อน แล้วส่งทันทีถ้ามีเน็ต (ส่งไม่ได้ก็รอส่งเองเมื่อออนไลน์)
    final outbox = ref.read(outboxProvider.notifier);
    final item = OutboxItem(
      id: ref.read(incidentRepositoryProvider).newIssueId(),
      uid: uid,
      createdAt: DateTime.now(),
      report: draft,
      images: images,
    );
    try {
      await outbox.enqueue(item);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('บันทึกรายงานไม่สำเร็จ: $e');
      return;
    }
    if (online) await outbox.flush();
    final sent = !ref.read(outboxProvider).any((i) => i.id == item.id);

    if (!mounted) return;
    Navigator.pop(context);
    if (sent) {
      _showResult(
        imageWarning ?? 'ส่งรายงานปัญหาสำเร็จ! เจ้าหน้าที่กำลังรับเรื่อง',
        AppColors.statusResolved,
      );
    } else {
      _showResult(
        outbox.persistent
            ? 'ยังไม่มีอินเทอร์เน็ต บันทึกรายงานไว้แล้ว จะส่งให้อัตโนมัติเมื่อกลับมาออนไลน์'
            : 'ยังไม่มีอินเทอร์เน็ต บันทึกรายงานไว้แล้ว จะส่งเมื่อออนไลน์ (อย่าเพิ่งปิดแท็บนี้)',
        AppColors.statusPending,
      );
    }
  }

  void _showResult(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _chatBubble(
    ThemeData theme,
    String text, {
    required bool fromUser,
    bool fromAi = false,
  }) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: fromUser
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(fromUser ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(
              fromUser ? AppRadius.xs : AppRadius.lg,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!fromUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fromAi ? Icons.auto_awesome_rounded : Icons.rule_rounded,
                    size: 14,
                    color: fromAi ? AppColors.primary : AppColors.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fromAi ? 'AI ร่างให้' : 'ร่างจากคำสำคัญ (ไม่ใช่ AI)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fromAi ? AppColors.primary : AppColors.outline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fromUser ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แถบ Voice-to-Report แบบแชต: บับเบิลเรื่องที่เล่า + คำตอบของ AI + ช่องพิมพ์ที่มีไมค์และปุ่มส่ง
  Widget _aiDraftChat(ThemeData theme) {
    final reply = _draftReply;
    return Card(
      color: AppColors.primaryContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Voice-to-Report',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'พูดหรือพิมพ์เล่าปัญหา AI ช่วยกรอกฟอร์มให้',
              style: theme.textTheme.bodySmall,
            ),
            if (_lastStory != null) ...[
              const SizedBox(height: 12),
              _chatBubble(theme, _lastStory!, fromUser: true),
              if (_drafting)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('กำลังร่าง...', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                )
              else if (reply != null)
                _chatBubble(
                  theme,
                  reply,
                  fromUser: false,
                  fromAi: _draftReplyFromAi,
                ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _storyController,
                    enabled: !_drafting,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendStory(),
                    decoration: InputDecoration(
                      hintText: 'เล่าปัญหาที่พบ...',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      isDense: true,
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
                // ปุ่มหลักคือไมค์ (Voice-to-Report) ถ้าพิมพ์ข้อความไว้ ปุ่มเปลี่ยนเป็นส่ง เหมือนแอปแชต
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _storyController,
                  builder: (context, value, _) {
                    final typed = value.text.trim().isNotEmpty;
                    return IconButton.filled(
                      tooltip: typed ? 'ส่งให้ AI ร่าง' : 'กดแล้วพูดเล่าปัญหา',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                      ),
                      onPressed: _drafting
                          ? null
                          : (typed ? _sendStory : _openVoicePage),
                      icon: Icon(
                        typed ? Icons.send_rounded : Icons.mic_rounded,
                        size: 26,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// แถบสถานะใต้รูป: กำลังเบลอ / เบลอกี่หน้า / ไม่พบใบหน้า / เบลอไม่สำเร็จ
  Widget _blurStatus(_Photo photo) {
    final (text, color) = photo.blurring
        ? ('กำลังเบลอ...', Colors.black54)
        : photo.error != null
        ? (photo.error!, AppColors.error)
        : photo.faceCount > 0
        ? ('เบลอ ${photo.faceCount} หน้า', AppColors.statusResolved)
        : ('ไม่พบใบหน้า', Colors.black54);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// แผนที่ย่อแสดงจุดที่จะส่ง กดเพื่อเลือกจุดเองบนแผนที่เต็มจอ
  Widget _locationPreview(ThemeData theme) {
    final point = _pickedPoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 160,
            child: point == null
                ? ColoredBox(
                    color: AppColors.surfaceContainerHigh,
                    child: Center(
                      child: _locating
                          ? const CircularProgressIndicator()
                          : const Text('ยังไม่ได้เลือกตำแหน่ง'),
                    ),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        // เปลี่ยน key เมื่อจุดเปลี่ยน เพื่อให้แผนที่ย่อเลื่อนไปที่จุดใหม่
                        key: ValueKey(point),
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: MapConfig.tileUrl,
                            userAgentPackageName:
                                MapConfig.userAgentPackageName,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 40,
                                height: 40,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 40,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(onTap: _pickOnMap),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (point != null) ...[
          const SizedBox(height: 4),
          Text(
            'GPS: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : () => _useCurrentLocation(),
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('ตำแหน่งปัจจุบัน'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.edit_location_alt_rounded),
                label: const Text('เลือกบนแผนที่'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขรายงาน' : 'แจ้งปัญหาสาธารณะ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
              // Voice-to-Report: เล่าปัญหาแบบแชต (พิมพ์หรือพูด) ให้ AI ร่างฟอร์ม
              _aiDraftChat(theme),
              const SizedBox(height: 20),

              // Image Picker Section
              Text('ภาพถ่ายปัญหา', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Add Camera Button
                    InkWell(
                      onTap: () => _pickImage(ImageSource.camera),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 4),
                            Text('ถ่ายรูปสด', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Add Gallery Button
                    InkWell(
                      onTap: () => _pickImage(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: AppColors.secondary,
                            ),
                            SizedBox(height: 4),
                            Text('คลังภาพ', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Selected Images Thumbnails
                    ..._photos.map(
                      (photo) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Image.memory(
                                _isAutoBlurEnabled && photo.blurred != null
                                    ? photo.blurred!
                                    : photo.original,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (_isAutoBlurEnabled)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: _blurStatus(photo),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _photos.remove(photo);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // PDPA Auto-blur Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('เบลอใบหน้าคนในรูปอัตโนมัติ'),
                subtitle: FaceBlurService.isSupported
                    ? null
                    : const Text('ใช้ได้ในแอปมือถือเท่านั้น'),
                value: _isAutoBlurEnabled,
                activeColor: AppColors.primary,
                onChanged: FaceBlurService.isSupported
                    ? (val) {
                        setState(() => _isAutoBlurEnabled = val);
                        if (val) {
                          for (final p in _photos) {
                            _blur(p);
                          }
                        }
                      }
                    : null,
              ),
              const Divider(height: 24),
            ],

            // Category Selection
            Text('หมวดหมู่ปัญหา *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<IncidentCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: IncidentCategory.values.map((cat) {
                String label;
                switch (cat) {
                  case IncidentCategory.electricity:
                    label = '⚡ ไฟฟ้า / ไฟส่องสว่าง';
                    break;
                  case IncidentCategory.water:
                    label = '💧 น้ำประปา / น้ำท่วมขัง';
                    break;
                  case IncidentCategory.road:
                    label = '🛣️ ถนน / ทางเท้า / สะพาน';
                    break;
                  case IncidentCategory.waste:
                    label = '🗑️ ขยะ / สิ่งปฏิกูล';
                    break;
                  case IncidentCategory.drainage:
                    label = '🌊 ท่อระบายน้ำ / กลิ่นเหม็น';
                    break;
                  case IncidentCategory.other:
                    label = '📌 อื่นๆ';
                    break;
                }
                return DropdownMenuItem(value: cat, child: Text(label));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            if (_selectedCategory == IncidentCategory.other) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryNoteController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'ระบุหมวดหมู่ปัญหา *',
                  hintText: 'เช่น ต้นไม้ล้ม, สัตว์จรจัด, ป้ายจราจรชำรุด',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (val) {
                  if (_selectedCategory == IncidentCategory.other &&
                      (val == null || val.trim().isEmpty)) {
                    return 'โปรดระบุหมวดหมู่ปัญหา';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            const Divider(height: 32),

            // Incident Title: สั้น บรรทัดเดียว ใช้เป็นชื่อเรื่องในฟีดและรายการแอดมิน
            Text('หัวข้อปัญหา *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.title_rounded),
                hintText: 'เช่น ฝาท่อแตก, เสาไฟดับ',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'โปรดระบุหัวข้อปัญหา';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Incident Description: เล่ารายละเอียดยาวได้ แยกจากหัวข้อ
            Text('รายละเอียด *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'จุดสังเกต ความเสียหาย หรือผลกระทบ',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'โปรดระบุรายละเอียดปัญหา';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location
            Text('ตำแหน่งที่เกิดเหตุ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                ),
                hintText: _lookingUpAddress
                    ? 'กำลังหาที่อยู่จากแผนที่...'
                    : 'ที่อยู่หรือจุดสังเกต',
                suffixIcon: _lookingUpAddress
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 8),
              _locationPreview(theme),
            ],
            const SizedBox(height: 32),

            // Submit Button
            FilledButton.icon(
              onPressed: _submitting ? null : _submitReport,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              icon: Icon(_isEdit ? Icons.save_rounded : Icons.send_rounded),
              label: Text(
                _isEdit ? 'บันทึกการแก้ไข' : 'ส่งรายงานปัญหา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// รูปที่ผู้แจ้งเลือก: เก็บทั้งต้นฉบับและฉบับเบลอใบหน้า อัปโหลดตามสวิตช์เบลอ
class _Photo {
  _Photo(this.file, this.original);

  final XFile file;
  final Uint8List original;
  Uint8List? blurred;
  int faceCount = 0;
  bool blurring = false;
  String? error;
}
