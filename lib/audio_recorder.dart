import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType

import 'platform/audio_recorder_platform.dart';

class Recorder extends StatefulWidget {
  final void Function(String path) onStop;
  final void Function(String aiAudioPath)? onAIResponse;

  const Recorder({super.key, required this.onStop, required this.onAIResponse});

  @override
  State<Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<Recorder> with AudioRecorderMixin {
  int _recordDuration = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  // Amplitude? _amplitude;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    // _amplitudeSub = _audioRecorder
    //     .onAmplitudeChanged(const Duration(milliseconds: 300))
    //     .listen((amp) {
    //   setState(() => _amplitude = amp);
    // });

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.wav;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(encoder: encoder, numChannels: 1);

        // Record to file
        await recordFile(_audioRecorder, config);

        // Record to stream
        // await recordStream(_audioRecorder, config);

        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // Future<void> _stop() async {
  //   final path = await _audioRecorder.stop();

  //   if (path != null) {
  //     widget.onStop(path);

  //     downloadWebData(path);
  //   }
  // }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      widget.onStop(path);

      // Step 1: Load the blob from the recorded audio URL
      final request = await html.HttpRequest.request(
        path,
        responseType: 'blob',
      );
      final blob = request.response as html.Blob;

      // Step 2: Read the blob into bytes using FileReader
      final completer = Completer<Uint8List>();
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(result);
        } else if (result is ByteBuffer) {
          completer.complete(Uint8List.view(result));
        } else {
          completer.completeError(
            'Failed to read audio blob. Type: ${result.runtimeType}',
          );
        }
      });

      reader.readAsArrayBuffer(blob);
      final audioBytes = await completer.future;

      // Step 3: Send the bytes to your backend as multipart/form-data
      final postUri = Uri.parse('http://localhost:8000/voice-respond');
      final multipartRequest =
          http.MultipartRequest('POST', postUri)
            ..headers['accept'] = 'audio/wav'
            ..files.add(
              http.MultipartFile.fromBytes(
                'audio',
                audioBytes,
                filename: 'recorded.wav',
                contentType: MediaType('audio', 'wav'),
              ),
            );

      try {
        final response = await multipartRequest.send();
        print("✅ Request sent. Status: ${response.statusCode}");

        if (response.statusCode == 200) {
          final responseBytes = await response.stream.toBytes();
          print('✅ Received ${responseBytes.length} bytes from server.');

          // Step 4: Create a Blob from the response and play/download
          final responseBlob = html.Blob([responseBytes], 'audio/wav');
          final responseUrl = html.Url.createObjectUrlFromBlob(responseBlob);
          widget.onAIResponse?.call(responseUrl);
          // Auto-play response
          final audioElement =
              html.AudioElement()
                ..src = responseUrl
                ..autoplay = true;
          html.document.body!.append(audioElement);

          // Optional: download the response
          final anchor =
              html.AnchorElement(href: responseUrl)
                ..setAttribute('download', 'response.wav')
                ..click();
        } else {
          print('Audio POST failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print("❌ Upload failed: $e");
      }
    }
  }

  Future<void> _pause() => _audioRecorder.pause();

  Future<void> _resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(encoder);

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${e.name}');
        }
      }
    }

    return isSupported;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            // if (_amplitude != null) ...[
            //   const SizedBox(height: 40),
            //   Text('Current: ${_amplitude?.current ?? 0.0}'),
            //   Text('Max: ${_amplitude?.max ?? 0.0}'),
            // ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withValues(alpha: 0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withValues(alpha: 0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}
