/// Persisted shell mode — decides which experience the app shows after splash.
///
///   * partner — the backend gave us a content URL once; we show the WebView.
///   * native  — backend declined; we show the local Volcano Boom game.
///   * unknown — first launch, we have not yet asked the backend.
enum ShellMode {
  partner,
  native,
  unknown;

  static ShellMode parse(String? raw) {
    switch (raw) {
      case 'partner':
        return ShellMode.partner;
      case 'native':
        return ShellMode.native;
      default:
        return ShellMode.unknown;
    }
  }

  String persist() {
    switch (this) {
      case ShellMode.partner:
        return 'partner';
      case ShellMode.native:
        return 'native';
      case ShellMode.unknown:
        return 'unknown';
    }
  }
}
