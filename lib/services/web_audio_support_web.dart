import 'package:web/web.dart' as web;

class WebAudioSupport {
  static bool get isSupported => true;

  static void playTone(double frequency, double volume) {
    try {
      final ctx = web.AudioContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = frequency;
      gain.gain.value = 0.12 * volume.clamp(0.0, 1.0);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.08);
    } catch (_) {}
  }

  static void speak(String text, double volume) {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.rate = 1.1;
      utterance.pitch = 0.95;
      utterance.volume = volume.clamp(0.0, 1.0);
      synth.speak(utterance);
    } catch (_) {}
  }

  static void cancelSpeech() {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();
    } catch (_) {}
  }
}
