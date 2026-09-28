String? requiredText(String? value, {String fieldName = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? positiveAmount(int? amount) {
  if (amount == null || amount <= 0) {
    return 'Amount must be greater than zero';
  }
  return null;
}
