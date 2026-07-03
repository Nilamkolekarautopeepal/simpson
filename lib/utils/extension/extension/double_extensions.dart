extension DoubleExtensions on double {
  bool get asBool => this > 0;

  double? get asNullIfZero => this == 0 ? null : this;

  bool get isNullOrZero => asNullIfZero == null;

  bool get isPositive => asNullIfZero == null ? false : (this > 0);

  String get asStringValue => isPositive ? '$this' : '';
}
