class WebAudioSupport {
  static bool get isSupported => false;

  static void playTone(double frequency, double volume) {
    // No-op on non-web platforms.
  }

  static void speak(String text, double volume) {
    // No-op on non-web platforms.
  }

  static void cancelSpeech() {
    // No-op on non-web platforms.
  }
}
