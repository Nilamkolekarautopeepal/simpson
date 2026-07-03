extension IntExtensions on int {
  bool get asBool => this > 0;

  int? get asNullIfZero => this == 0 ? null : this;

  bool get isPositive => asNullIfZero == null ? false : (this > 0);

  bool get isNullOrZero => asNullIfZero == null;
}
