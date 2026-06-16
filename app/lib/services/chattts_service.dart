import 'package:http/http.dart' as http;

/// ChatTTS service via a self-hosted HTTP API.
///
/// Deploy ChatTTS as a lightweight server (e.g., FastAPI + ChatTTS on a
/// local machine or cloud instance). The Flutter app sends text, receives
/// audio bytes.
///
/// To self-host:
///   1. pip install ChatTTS fastapi uvicorn
///   2. Run a FastAPI server that accepts POST /tts with {"text": "..."}
///      and returns audio/wav bytes.
///   3. Set CHATTTS_BASE_URL to your server's address.
class ChatTTSService {
  final String baseUrl;

  ChatTTSService({this.baseUrl = ''});

  Future<List<int>?> synthesize(String text) async {
    if (baseUrl.isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: '{"text": ${_jsonEscape(text)}}',
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static String _jsonEscape(String s) {
    return '"${s.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }
}
