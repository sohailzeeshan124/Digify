import 'package:digify/modal_classes/chat_bot.dart';
import 'package:digify/repositories/chat_bot_repository.dart';
import 'package:flutter/material.dart';

class ChatBotViewModel extends ChangeNotifier {
  final ChatBotRepository repository = ChatBotRepository();

  List<ChatBotModel> messages = [];
  bool isLoading = false;

  void sendMessage(String text) async {
    messages.add(ChatBotModel(
      id: DateTime.now().toString(),
      text: text,
      userId: "",
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    isLoading = true;
    notifyListeners();

    final reply = await repository.askchatbot(text);

    messages.add(ChatBotModel(
      id: DateTime.now().toString(),
      text: reply,
      userId: "",
      timestamp: DateTime.now(),
    ));

    isLoading = false;
    notifyListeners();
  }
}
