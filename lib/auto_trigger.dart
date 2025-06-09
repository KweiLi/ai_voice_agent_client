import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:record/record.dart';

class VoiceTriggerWidget extends StatefulWidget {
  @override
  _VoiceTriggerWidgetState createState() => _VoiceTriggerWidgetState();
}

class _VoiceTriggerWidgetState extends State<VoiceTriggerWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  // final Record _recorder = Record();
  bool _isListening = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    _speech.listen(
      onResult: (result) {
        final recognized = result.recognizedWords.toLowerCase();
        if (recognized.contains('hi mrf') && !_isRecording) {
          // _startRecording();
        }
      },
      listenMode: stt.ListenMode.dictation,
    );
    setState(() => _isListening = true);
  }

  // Future<void> _startRecording() async {
  //   if (await _recorder.hasPermission()) {
  //     await _recorder.start();
  //     setState(() => _isRecording = true);
  //     print('Recording started');
  //   }
  // }

  // Future<void> _stopRecording() async {
  //   final path = await _recorder.stop();
  //   print('Recording saved at: $path');
  //   setState(() => _isRecording = false);
  // }

  // @override
  // void dispose() {
  //   _speech.stop();
  //   _recorder.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_isRecording ? "Recording..." : "Say 'Hi MRF' to start"),
        if (_isRecording)
          ElevatedButton(onPressed: () {}, child: Text("Stop Recording")),
      ],
    );
  }
}
