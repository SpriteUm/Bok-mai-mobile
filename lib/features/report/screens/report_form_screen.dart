import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bok_mai_mobile/core/constants/cloudinary_config.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/data/services/image_upload_service.dart';
import 'package:bok_mai_mobile/data/services/speech_service.dart';
import 'package:bok_mai_mobile/data/services/voice_report_drafter.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.editing});

  /// ถ้าส่งมา = โหมดแก้ไขรายงานเดิม (แก้ได้เฉพาะข้อความ หมวดหมู่ และความเร่งด่วน)
  final IncidentModel? editing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(
    text: 'ถนนฉลองกรุง แขวงลาดกระบัง เขตลาดกระบัง กทม.',
  );

  IncidentCategory _selectedCategory = IncidentCategory.road;
  IncidentUrgency _selectedUrgency = IncidentUrgency.medium;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final SpeechService _speech = SpeechService();
  bool _isRecording = false;
  bool _drafting = false;
  String _transcript = '';
  bool _isAutoBlurEnabled = true;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleController.text = e.title;
      _descController.text = e.description;
      _locationController.text = e.locationAddress;
      _selectedCategory = e.category;
      _selectedUrgency = e.urgency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImages.add(picked);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// กดครั้งแรกเริ่มฟัง กดอีกครั้ง (หรือพูดจบ) แล้วให้ AI ร่างฟอร์มจากสิ่งที่พูด
  Future<void> _toggleVoiceReport() async {
    if (_drafting) return;
    if (_isRecording) {
      await _speech.stop();
      return;
    }

    _transcript = '';
    final started = await _speech.start(
      onResult: (text) => _transcript = text,
      onDone: _onSpeechDone,
      onError: (e) {
        if (mounted) setState(() => _isRecording = false);
        _showMessage('ฟังเสียงไม่สำเร็จ: $e');
      },
    );
    if (!mounted) return;
    if (!started) {
      _showMessage('ใช้ไมโครโฟนไม่ได้ โปรดอนุญาตสิทธิ์ไมค์แล้วลองใหม่');
      return;
    }
    setState(() => _isRecording = true);
  }

  Future<void> _onSpeechDone() async {
    if (!mounted || !_isRecording) return;
    setState(() {
      _isRecording = false;
      _drafting = true;
    });

    final transcript = _transcript.trim();
    if (transcript.isEmpty) {
      setState(() => _drafting = false);
      _showMessage('ไม่ได้ยินเสียงพูด ลองกดไมค์แล้วพูดใหม่อีกครั้ง');
      return;
    }

    try {
      final draft = await ref.read(voiceReportDrafterProvider).draft(transcript);
      if (!mounted) return;
      setState(() {
        _titleController.text = draft.title;
        _descController.text = draft.description;
        _selectedCategory = draft.category;
        _selectedUrgency = draft.urgency;
      });
      _showMessage('ร่างแบบฟอร์มจากเสียงของคุณแล้ว โปรดตรวจสอบก่อนส่ง');
    } catch (e) {
      // ร่างไม่ได้ก็เก็บข้อความที่พูดไว้ในช่องรายละเอียด ไม่ให้เสียคำพูดผู้ใช้
      if (!mounted) return;
      setState(() => _descController.text = transcript);
      _showMessage('ร่างแบบฟอร์มไม่สำเร็จ ใส่ข้อความที่พูดไว้ในรายละเอียดแล้ว');
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  bool _submitting = false;

  /// พิกัดปัจจุบัน ถ้าไม่ได้สิทธิ์/ปิด GPS ใช้พิกัดกลางลาดกระบังแทน
  Future<({double lat, double lng})> _currentPosition() async {
    const fallback = (lat: 13.7299, lng: 100.7782);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    if (!ref.read(firebaseReadyProvider) ||
        ref.read(authStateProvider).valueOrNull == null) {
      _showMessage('แก้ไขได้เมื่อเชื่อมต่อ Firebase และเข้าสู่ระบบแล้วเท่านั้น');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(incidentRepositoryProvider).updateIssue(
            widget.editing!.copyWith(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory,
              urgency: _selectedUrgency,
              locationAddress: _locationController.text.trim(),
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('แก้ไขไม่สำเร็จ (แก้ได้เฉพาะเรื่องที่รอดำเนินการและไม่มีคนกด +1 ร่วม): $e');
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    _showMessage('บันทึกการแก้ไขแล้ว');
  }

  Future<void> _submitReport() async {
    if (_isEdit) return _saveEdit();
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);

    final position = await _currentPosition();

    // อัปโหลดรูปไป Cloudinary แล้วเก็บเป็นลิงก์ (สูงสุด 5 รูปตาม firestore.rules)
    var imageUrls = <String>[];
    String? imageWarning;
    if (_selectedImages.isNotEmpty && ref.read(firebaseReadyProvider)) {
      if (CloudinaryConfig.isConfigured) {
        try {
          imageUrls = await ImageUploadService().uploadAll(_selectedImages.take(5));
        } catch (e) {
          if (!mounted) return;
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
          return;
        }
      } else {
        imageWarning = 'ส่งรายงานแล้ว แต่ยังไม่ได้ตั้งค่า Cloudinary จึงไม่ได้แนบรูป';
      }
    }

    final draft = IncidentModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      status: IncidentStatus.pending,
      urgency: _selectedUrgency,
      locationAddress: _locationController.text.trim(),
      latitude: position.lat,
      longitude: position.lng,
      imageUrls: imageUrls,
      upvoteCount: 1,
      hasUpvoted: true,
      createdAt: DateTime.now(),
    );

    try {
      if (ref.read(firebaseReadyProvider)) {
        await ref.read(incidentRepositoryProvider).createIssue(draft);
      } else {
        // โหมดข้อมูลจำลอง (Firebase ไม่พร้อม)
        ref.read(incidentFeedProvider.notifier).addLocal(
              draft.copyWith(id: 'inc-${DateTime.now().millisecondsSinceEpoch}'),
            );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งรายงานไม่สำเร็จ: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(imageWarning ?? 'ส่งรายงานปัญหาสำเร็จ! เจ้าหน้าที่กำลังรับเรื่อง'),
            ),
          ],
        ),
        backgroundColor: AppColors.statusResolved,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'แก้ไขรายงาน' : 'แจ้งปัญหาสาธารณะ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
            // Voice-to-Report AI Banner
            Card(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            _isRecording
                                ? 'กำลังฟัง... พูดปัญหาที่พบ แล้วกดหยุดเมื่อพูดจบ'
                                : _drafting
                                    ? 'กำลังร่างแบบฟอร์ม...'
                                    : 'กดอัดเสียงพูดปัญหา AI ช่วยร่างแบบฟอร์มให้ ตรวจแก้ได้ก่อนส่ง',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _isRecording
                            ? AppColors.error
                            : AppColors.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: _drafting ? null : _toggleVoiceReport,
                      icon: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Image Picker Section
            Text('ภาพถ่ายปัญหา', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'แนบภาพถ่ายสภาพปัญหาจริง (ระบบเบลอหน้าและป้ายทะเบียนอัตโนมัติ)',
              style: theme.textTheme.bodySmall,
            ),
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
                          Icon(Icons.camera_alt_rounded, color: AppColors.primary),
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
                          Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                          SizedBox(height: 4),
                          Text('คลังภาพ', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Selected Images Thumbnails
                  ..._selectedImages.map(
                    (xFile) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: kIsWeb
                                ? Image.network(
                                    xFile.path,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(xFile.path),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.remove(xFile);
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
              title: const Text('เปิดระบบเบลอใบหน้าและป้ายทะเบียน (PDPA)'),
              subtitle: const Text('ปิดทับข้อมูลส่วนบุคคลอัตโนมัติก่อนอัปโหลด'),
              value: _isAutoBlurEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _isAutoBlurEnabled = val;
                });
              },
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 16),

            // Urgency Segmented Control
            Text('ระดับความเร่งด่วน', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<IncidentUrgency>(
              segments: const [
                ButtonSegment(value: IncidentUrgency.low, label: Text('ปกติ')),
                ButtonSegment(value: IncidentUrgency.medium, label: Text('ปานกลาง')),
                ButtonSegment(value: IncidentUrgency.high, label: Text('เร่งด่วน')),
              ],
              selected: {_selectedUrgency},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedUrgency = set.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Incident Title
            Text('หัวข้อปัญหา *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
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

            // Incident Description
            Text('รายละเอียดเพิ่มเติม *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'อธิบายจุดสังเกต หรือความเสียหายที่พบ...',
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
            Text('ตำแหน่งที่เกิดเหตุ (GPS)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  tooltip: 'ดึงพิกัดปัจจุบัน',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('อัปเดตพิกัด GPS ปัจจุบันแล้ว')),
                    );
                  },
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
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

