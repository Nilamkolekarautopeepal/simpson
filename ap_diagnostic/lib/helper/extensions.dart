extension ListExtension<T> on List<T> {
  /// Safely gets an element at [index], returning null if out of bounds
  T? safeElementAt(int? index) {
    if (index == null || index < 0 || index >= length) return null;
    return this[index];
  }
}