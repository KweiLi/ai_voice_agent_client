import 'package:ai_voice_agent/conversation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Conversation(
        key: Key('conversation'),
      ),
    );
  }
}
