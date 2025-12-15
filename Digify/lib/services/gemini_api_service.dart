import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  final String _apiKey = "";

  final String _url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";

  Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse("$_url$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": userMessage}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Error: ${response.body}";
    }
  }
}
