import 'package:speech_to_text/speech_to_text.dart';

/// ครอบ speech_to_text สำหรับฟังเสียงพูดภาษาไทย
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  bool get isListening => _speech.isListening;

  /// คืน false ถ้าไม่ได้สิทธิ์ไมค์หรืออุปกรณ์/เบราว์เซอร์ไม่รองรับ
  Future<bool> start({
    required void Function(String text) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    _ready = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') onDone();
      },
      onError: (e) => onError(e.errorMsg),
    );
    if (!_ready) return false;

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'th_TH',
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      ),
      onResult: (r) => onResult(r.recognizedWords),
    );
    return true;
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();
}
