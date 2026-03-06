import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/lang.dart';

enum PomodoroStatus { stopped, running, paused }

class PomodoroTimer extends StatefulWidget {
  final VoidCallback onLanguageChanged;
  const PomodoroTimer({super.key, required this.onLanguageChanged});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 1.5;

    final paint = Paint()
      ..color = color.withOpacity((1.0 - progress).clamp(0.0, 1.0) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(
      center,
      (size.width / 2) + (maxRadius - size.width / 2) * progress,
      paint,
    );
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  int _focusTimeSeconds = 25 * 60;
  int _breakTimeSeconds = 5 * 60;

  int _remainingSeconds = 25 * 60;
  PomodoroStatus _status = PomodoroStatus.stopped;
  bool _isFocusMode = true;
  Timer? _timer;
  DateTime? _pausedTime;
  String? _customSoundPath;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutCubic,
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusTimeSeconds = (prefs.getInt('pomo_focus_minutes') ?? 25) * 60;
      _breakTimeSeconds = (prefs.getInt('pomo_break_minutes') ?? 5) * 60;
      AppLang.isSpanish = prefs.getBool('pomo_is_spanish') ?? false;
      _customSoundPath = prefs.getString('pomo_custom_sound');

      if (_status == PomodoroStatus.stopped) {
        _remainingSeconds = _isFocusMode
            ? _focusTimeSeconds
            : _breakTimeSeconds;
      }
    });
  }

  Future<void> _saveSettings(
    int focusMin,
    int breakMin,
    bool isSpanish,
    String? soundPath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomo_focus_minutes', focusMin);
    await prefs.setInt('pomo_break_minutes', breakMin);
    await prefs.setBool('pomo_is_spanish', isSpanish);
    if (soundPath != null) {
      await prefs.setString('pomo_custom_sound', soundPath);
    } else {
      await prefs.remove('pomo_custom_sound');
    }
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_status == PomodoroStatus.running && _pausedTime == null) {
        _pausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_status == PomodoroStatus.running && _pausedTime != null) {
        final elapsedSeconds = DateTime.now()
            .difference(_pausedTime!)
            .inSeconds;
        setState(() {
          _remainingSeconds -= elapsedSeconds;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _timer?.cancel();
            _playAlarmAndToggle();
          }
        });
        _pausedTime = null;
      }
    }
  }

  void _playAlarmAndToggle() async {
    try {
      if (_customSoundPath != null && File(_customSoundPath!).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(_customSoundPath!));
      } else {
        await _audioPlayer.play(AssetSource('audio/chime.mp3'));
      }
    } catch (e) {
      debugPrint("Audio play error: $e");
    }

    // Stop breathing, trigger ripple wave animation
    _breathController.stop();
    _pulseController.reset();
    _pulseController.forward();

    _toggleMode();
  }

  void _startTimer() {
    setState(() {
      _status = PomodoroStatus.running;
    });
    _breathController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _playAlarmAndToggle();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _status = PomodoroStatus.paused;
      _pausedTime = null;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _status = PomodoroStatus.stopped;
      _remainingSeconds = _isFocusMode ? _focusTimeSeconds : _breakTimeSeconds;
      _pausedTime = null;
    });
  }

  void _toggleMode() {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _isFocusMode = !_isFocusMode;
      _status = PomodoroStatus.stopped;
      _remainingSeconds = _isFocusMode ? _focusTimeSeconds : _breakTimeSeconds;
      _pausedTime = null;
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    if (minutes < 0) minutes = 0;
    if (seconds < 0) seconds = 0;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    int total = _isFocusMode ? _focusTimeSeconds : _breakTimeSeconds;
    double progress = _remainingSeconds / total;
    return progress < 0 ? 0 : progress;
  }

  Future<String?> _pickSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  void _showSettings() {
    int tempFocus = _focusTimeSeconds ~/ 60;
    int tempBreak = _breakTimeSeconds ~/ 60;
    bool tempSpanish = AppLang.isSpanish;
    String? tempSound = _customSoundPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLang.settingsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Language Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLang.languageSetting,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        DropdownButton<bool>(
                          value: tempSpanish,
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Español'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => tempSpanish = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),

                    // Sound Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLang.selectSound,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              tempSound != null
                                  ? AppLang.customSound
                                  : AppLang.defaultSound,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            String? path = await _pickSound();
                            if (path != null) {
                              setSheetState(() => tempSound = path);
                            }
                          },
                          icon: const Icon(Icons.music_note, size: 20),
                          label: Text(tempSound != null ? 'Change' : 'Pick'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),

                    // Focus Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLang.focusDuration,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '$tempFocus ${AppLang.min}',
                          style: const TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempFocus.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) {
                        setSheetState(() => tempFocus = val.toInt());
                      },
                    ),
                    const SizedBox(height: 8),

                    // Break Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLang.breakDuration,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '$tempBreak ${AppLang.min}',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempBreak.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.tealAccent,
                      onChanged: (val) {
                        setSheetState(() => tempBreak = val.toInt());
                      },
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _saveSettings(
                          tempFocus,
                          tempBreak,
                          tempSpanish,
                          tempSound,
                        ).then((_) {
                          widget.onLanguageChanged();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLang.saveSettings,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final color = _isFocusMode ? Colors.deepPurpleAccent : Colors.tealAccent;

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breathing & Rippling Timer
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseAnimation,
                  _breathAnimation,
                ]),
                builder: (context, child) {
                  final breathScale = 1.0 + (_breathAnimation.value * 0.03);
                  return Transform.scale(
                    scale: breathScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Targeted Ripple Wave
                        CustomPaint(
                          painter: RipplePainter(_pulseAnimation.value, color),
                          size: const Size(250, 250),
                        ),

                        // Neon Glow Ring
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(
                                  0.3 + (_breathAnimation.value * 0.1),
                                ),
                                blurRadius: 30 + (_breathAnimation.value * 10),
                                spreadRadius: 5 + (_breathAnimation.value * 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 12,
                            backgroundColor: color.withOpacity(0.1),
                            color: color,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isFocusMode
                                  ? AppLang.focusPhase
                                  : AppLang.breakPhase,
                              style: TextStyle(
                                fontSize: 20,
                                letterSpacing: 4,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_status != PomodoroStatus.running)
                    FloatingActionButton(
                      onPressed: _startTimer,
                      backgroundColor: color,
                      child: const Icon(Icons.play_arrow, size: 32),
                    )
                  else
                    FloatingActionButton(
                      onPressed: _pauseTimer,
                      backgroundColor: Colors.amber,
                      child: const Icon(Icons.pause, size: 32),
                    ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    onPressed: _resetTimer,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.stop, size: 32),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: _toggleMode,
                    icon: Icon(
                      Icons.skip_next,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    iconSize: 32,
                    tooltip: 'Skip phase',
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.5)),
            onPressed: () {
              if (_status != PomodoroStatus.running) {
                _showSettings();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLang.currentLanguageName == 'Español'
                          ? 'Pausa el temporizador para cambiar ajustes'
                          : 'Pause timer to change settings',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
