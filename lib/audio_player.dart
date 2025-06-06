import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AudioPlayer extends StatefulWidget {
  /// Path from where to play recorded audio
  final String source;
  final bool isAI;

  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
  final VoidCallback onDelete;

  const AudioPlayer({
    super.key,
    required this.source,
    required this.onDelete,
    required this.isAI,
  });

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioPlayer> {
  // static const double _controlSize = 56;
  // static const double _deleteBtnSize = 24;

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;

  @override
  void initState() {
    _playerStateChangedSubscription = _audioPlayer.onPlayerComplete.listen((
      state,
    ) async {
      await stop();
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) => setState(() {
        _position = position;
      }),
    );
    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );

    _audioPlayer.setSource(_source);

    super.initState();
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final double playerWidth = MediaQuery.of(context).size.width / 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: widget.isAI ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: playerWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isAI
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.2), // fixed method
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), // fixed method
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),

              Row(
                children: <Widget>[
                  _buildControl(size: 36),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSlider()),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_audioPlayer.state == ap.PlayerState.playing) {
                        stop().then((value) => widget.onDelete());
                      } else {
                        widget.onDelete();
                      }
                    },
                  ),
                ],
              ),
              if (_duration != null && _position != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_formatDuration(_position!)} / ${_formatDuration(_duration!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildControl() {
  //   Icon icon;
  //   Color color;

  //   if (_audioPlayer.state == ap.PlayerState.playing) {
  //     icon = const Icon(Icons.pause, color: Colors.red, size: 30);
  //     color = Colors.red.withValues(alpha: 0.1);
  //   } else {
  //     final theme = Theme.of(context);
  //     icon = Icon(Icons.play_arrow, color: theme.primaryColor, size: 30);
  //     color = theme.primaryColor.withValues(alpha: 0.1);
  //   }

  //   return ClipOval(
  //     child: Material(
  //       color: color,
  //       child: InkWell(
  //         child: SizedBox(
  //           width: _controlSize,
  //           height: _controlSize,
  //           child: icon,
  //         ),
  //         onTap: () {
  //           if (_audioPlayer.state == ap.PlayerState.playing) {
  //             pause();
  //           } else {
  //             play();
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildSlider(double widgetWidth) {
  //   bool canSetValue = false;
  //   final duration = _duration;
  //   final position = _position;

  //   if (duration != null && position != null) {
  //     canSetValue = position.inMilliseconds > 0;
  //     canSetValue &= position.inMilliseconds < duration.inMilliseconds;
  //   }

  //   double width = widgetWidth - _controlSize - _deleteBtnSize;
  //   width -= _deleteBtnSize;

  //   return SizedBox(
  //     width: width,
  //     child: Slider(
  //       activeColor: Theme.of(context).primaryColor,
  //       inactiveColor: Theme.of(context).colorScheme.secondary,
  //       onChanged: (v) {
  //         if (duration != null) {
  //           final position = v * duration.inMilliseconds;
  //           _audioPlayer.seek(Duration(milliseconds: position.round()));
  //         }
  //       },
  //       value:
  //           canSetValue && duration != null && position != null
  //               ? position.inMilliseconds / duration.inMilliseconds
  //               : 0.0,
  //     ),
  //   );
  // }

  Widget _buildControl({double size = 56}) {
    final isPlaying = _audioPlayer.state == ap.PlayerState.playing;
    final icon = Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      color:
          isPlaying
              ? Colors.red
              : widget.isAI
              ? Colors.blue.withValues(alpha: 0.6)
              : Colors.green.withValues(alpha: 0.6),
      size: size * 0.6,
    );

    return ClipOval(
      child: Material(
        color: isPlaying ? Colors.white : Colors.white,
        child: InkWell(
          onTap: () {
            if (isPlaying) {
              pause();
            } else {
              play();
            }
          },
          child: SizedBox(width: size, height: size, child: icon),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    final duration = _duration;
    final position = _position;

    bool canSetValue =
        duration != null &&
        position != null &&
        position.inMilliseconds > 0 &&
        position.inMilliseconds < duration.inMilliseconds;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8,
        ), // Change size here
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 18,
        ), // Optional: ripple size
        thumbColor:
            widget.isAI
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.green.withValues(alpha: 0.6),
        activeTrackColor: widget.isAI ? Colors.blue : Colors.green,
        inactiveTrackColor: Colors.white,
      ),
      child: Slider(
        // activeColor: Theme.of(context).primaryColor,
        // activeColor: Colors.green.withValues(alpha: 0.6),
        // inactiveColor: Colors.white,
        onChanged: (v) {
          if (duration != null) {
            final newPosition = v * duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: newPosition.round()));
          }
        },
        value:
            canSetValue
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0,
      ),
    );
  }

  Future<void> play() => _audioPlayer.play(_source);

  Future<void> pause() async {
    await _audioPlayer.pause();
    setState(() {});
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    setState(() {});
  }

  Source get _source =>
      kIsWeb ? ap.UrlSource(widget.source) : ap.DeviceFileSource(widget.source);
}
