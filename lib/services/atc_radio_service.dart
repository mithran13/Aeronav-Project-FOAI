import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'web_audio_support.dart'
    if (dart.library.js_interop) 'web_audio_support_web.dart';

class AtcChannelInfo {
  final String frequency;
  final String name;
  final String location;

  const AtcChannelInfo({
    required this.frequency,
    required this.name,
    required this.location,
  });
}

class AtcRadioService extends ChangeNotifier {
  static const List<AtcChannelInfo> availableChannels = [
    AtcChannelInfo(
      frequency: '118.10 MHz',
      name: 'MAA Tower',
      location: 'Chennai, India',
    ),
    AtcChannelInfo(
      frequency: '124.75 MHz',
      name: 'Chennai Approach',
      location: 'Chennai FIR',
    ),
    AtcChannelInfo(
      frequency: '119.10 MHz',
      name: 'DEL Tower',
      location: 'New Delhi, India',
    ),
    AtcChannelInfo(
      frequency: '132.50 MHz',
      name: 'Delhi Radar',
      location: 'Delhi FIR',
    ),
    AtcChannelInfo(
      frequency: '118.30 MHz',
      name: 'Tokyo Tower',
      location: 'Tokyo Haneda',
    ),
    AtcChannelInfo(
      frequency: '121.50 MHz',
      name: 'Emergency Guard',
      location: 'Global VHF',
    ),
  ];

  bool _isRadioOn = false;
  int _selectedChannelIndex = 0;
  double _volume = 0.8;
  Timer? _waveformTimer;
  Timer? _chatterTimer;
  final Random _random = Random();

  // High-frequency 120ms ValueNotifier for localized 60 FPS equalizer updates
  final ValueNotifier<List<double>> waveformNotifier = ValueNotifier(
    List.filled(8, 0.1),
  );
  String _currentTransmission = 'ATC RADIO OFF — TUNE FREQUENCY';

  bool get isRadioOn => _isRadioOn;
  int get selectedChannelIndex => _selectedChannelIndex;
  AtcChannelInfo get currentChannel => availableChannels[_selectedChannelIndex];
  double get volume => _volume;
  String get currentTransmission => _currentTransmission;

  static const List<String> _atcDialogues = [
    'AeroNav 452 heavy, cleared for ILS Runway 07 Left, wind 090 at 12 knots.',
    'Chennai Control, Indigo 612 climbing to Flight Level 320, passing FL210.',
    'Speedbird 101, contact Delhi Radar on 132.50, good day.',
    'Air India 302, descend to 4,000 feet, QNH 1013, report field in sight.',
    'Japan Air 840, hold short of Runway 16 Right at taxiway Bravo 4.',
    'Emirates 541, turn right heading 280, vectoring for ILS approach.',
    'AeroNav 882, squawk 4721, radar contact 40 miles south of Chennai VOR.',
    'All aircraft on frequency, bird activity reported near threshold 25 Right.',
  ];

  void toggleRadio() {
    _isRadioOn = !_isRadioOn;
    if (_isRadioOn) {
      _startRadioSim();
    } else {
      _stopRadioSim();
    }
    notifyListeners();
  }

  void selectChannel(int index) {
    if (index >= 0 && index < availableChannels.length) {
      _selectedChannelIndex = index;
      if (_isRadioOn) {
        final tuneText =
            'Tuned to ${currentChannel.name}, ${currentChannel.frequency}';
        _currentTransmission =
            'TUNED TO ${currentChannel.frequency} — ${currentChannel.name.toUpperCase()}';
        _speakTransmission(tuneText);
      }
      notifyListeners();
    }
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _playMicBeep() {
    if (kIsWeb) {
      WebAudioSupport.playTone(880, _volume);
    }
  }

  void _speakTransmission(String text) {
    _playMicBeep();
    if (kIsWeb) {
      WebAudioSupport.speak(text, _volume);
    }
  }

  void _startRadioSim() {
    final startMsg =
        'Tuned to ${currentChannel.name}, ${currentChannel.frequency}';
    _currentTransmission =
        'TUNED TO ${currentChannel.frequency} — STANDBY FOR TRANSMISSION';
    _speakTransmission(startMsg);

    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!_isRadioOn) return;
      waveformNotifier.value = List.generate(
        8,
        (_) => 0.15 + _random.nextDouble() * 0.85 * _volume,
      );
    });

    _chatterTimer?.cancel();
    _chatterTimer = Timer.periodic(const Duration(seconds: 8), (t) {
      if (!_isRadioOn) return;
      _currentTransmission =
          _atcDialogues[_random.nextInt(_atcDialogues.length)];
      _speakTransmission(_currentTransmission);
      notifyListeners();
    });
  }

  void _stopRadioSim() {
    _waveformTimer?.cancel();
    _chatterTimer?.cancel();
    waveformNotifier.value = List.filled(8, 0.1);
    _currentTransmission = 'ATC RADIO OFF — TUNE FREQUENCY';

    if (kIsWeb) {
      WebAudioSupport.cancelSpeech();
    }
  }

  @override
  void dispose() {
    _stopRadioSim();
    waveformNotifier.dispose();
    super.dispose();
  }
}
