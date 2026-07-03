extension IntExtensions on int {
  bool get asBool => this > 0;

  // ignore: null_check_always_fails
  int get asNullIfZero => this == 0 ? null! : this;

  // ignore: null_check_always_fails, dead_code
  bool get isPositive => asNullIfZero == null! ? false : (this > 0);

  // ignore: unnecessary_null_comparison
  bool get isNullOrZero => asNullIfZero == null;
}
