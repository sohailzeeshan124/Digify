import 'package:digify/services/gemini_api_service.dart';

class ChatBotRepository {
  final GeminiApiService api = GeminiApiService();

  Future<String> askchatbot(String message) {
    return api.sendMessage(message);
  }
}
