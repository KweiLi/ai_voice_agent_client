import 'package:ai_voice_agent/audio_player.dart';
import 'package:ai_voice_agent/audio_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Conversation extends StatefulWidget {
  const Conversation({super.key});

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  // String? audioPath;
  List<Map<String, dynamic>> audioMessages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child:
                audioMessages.isEmpty
                    ? Center(
                      child: Text(
                        'Start conversation',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 12,
                      ),
                      child: ListView.builder(
                        itemCount: audioMessages.length,
                        itemBuilder: (context, index) {
                          final message = audioMessages[index];
                          final isAI = message['isAI'] as bool;
                          final path = message['path'] as String;

                          final double playerWidth =
                              MediaQuery.of(context).size.width / 3;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child:
                                (message['isLoading'] == true)
                                    ? Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        height: 60,
                                        width: playerWidth,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),

                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.6,
                                                ),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "AI is thinking...",
                                              style: TextStyle(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    : AudioPlayer(
                                      source: path,
                                      isAI: isAI,
                                      onDelete: () {
                                        setState(() {
                                          audioMessages.removeAt(index);
                                        });
                                      },
                                    ),
                          );
                        },
                      ),
                    ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 100,
              child: Recorder(
                onStop: (path) {
                  if (kDebugMode) print('Recorded file path: $path');
                  setState(() {
                    // audioPath = path;
                    // showPlayer = true;
                    // audioMessages.add({'path': path, 'isAI': false});
                    audioMessages.add({'path': path, 'isAI': false});
                    // Add a loading placeholder for the AI response
                    audioMessages.add({
                      'path': '',
                      'isAI': true,
                      'isLoading': true,
                    });
                  });
                },
                onAIResponse: (aiPath) {
                  if (kDebugMode) print('AI response audio path: $aiPath');
                  setState(() {
                    // audioMessages.add({'path': aiPath, 'isAI': true});
                    final index = audioMessages.indexWhere(
                      (msg) => msg['isAI'] == true && msg['isLoading'] == true,
                    );
                    if (index != -1) {
                      audioMessages[index] = {
                        'path': aiPath,
                        'isAI': true,
                        'isLoading': false,
                      };
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
