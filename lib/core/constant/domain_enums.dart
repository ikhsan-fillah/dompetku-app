enum TransactionType { income, expense }

enum PaymentMethod {
  cash,
  eWallet,
  qris,
  bankTransfer,
  debitCard,
  creditCard,
  other,
}

enum BiometricStatus {
  unavailable,
  required,
  authenticating,
  authenticated,
  failed,
  lockedOut,
}
