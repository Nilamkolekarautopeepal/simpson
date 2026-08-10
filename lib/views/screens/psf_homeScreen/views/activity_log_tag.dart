class ActivityLogTag {
  static const allTags = [
    'ESN',
    'DTC',
    'IQA',
    'PID',
    'FLASH',
    'HARNESS',
    'PLC',
    'DONGLE',
    'SESSION',
    'GENERAL'
  ];

  static String infer(String message) {
    final m = message.toLowerCase();
    if (m.contains('esn')) return 'ESN';
    if (m.contains('dtc')) return 'DTC';
    if (m.contains('iqa')) return 'IQA';
    if (m.contains('pid') || m.contains('live parameter')) return 'PID';
    if (m.contains('flash')) return 'FLASH';
    if (m.contains('harness') || m.contains('continuity')) return 'HARNESS';
    if (m.contains('plc')) return 'PLC';
    if (m.contains('session summary') ||
        m.contains('session report') ||
        m.contains('session started')) {
      return 'SESSION';
    }
    if (m.contains('dongle')) return 'DONGLE';
    return 'GENERAL';
  }

  static const _colors = {
    'ESN': 0xFF0E6E6E,
    'DTC': 0xFFD64545,
    'IQA': 0xFFDB2777,
    'PID': 0xFF27AE60,
    'FLASH': 0xFF2D6CDF,
    'HARNESS': 0xFF8E7CC3,
    'PLC': 0xFF6C5CE7,
    'DONGLE': 0xFFE67E22,
    'SESSION': 0xFF34495E,
    'GENERAL': 0xFF7C8698,
  };

  static int colorValue(String tag) => _colors[tag] ?? _colors['GENERAL']!;
}
