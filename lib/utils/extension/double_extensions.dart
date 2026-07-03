// ignore_for_file: null_check_always_fails

extension DoubleExtensions on double {
  bool get asBool => this > 0;

  double get asNullIfZero => this == 0 ? null! : this;

  bool get isNullOrZero => asNullIfZero == null!;

  // ignore: dead_code
  bool get isPositive => asNullIfZero == null! ? false : (this > 0);

  String get asStringValue => isPositive ? '$this' : '';
}
