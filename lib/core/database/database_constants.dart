class DatabaseTables {
  static const categories = 'categories';
  static const transactions = 'transactions';
  static const budgets = 'budgets';

  const DatabaseTables._();
}

class DatabaseColumns {
  static const id = 'id';
  static const name = 'name';
  static const type = 'type';
  static const iconKey = 'icon_key';
  static const colorValue = 'color_value';
  static const isDefault = 'is_default';
  static const isFavorite = 'is_favorite';
  static const sortOrder = 'sort_order';
  static const isArchived = 'is_archived';
  static const title = 'title';
  static const amount = 'amount';
  static const currency = 'currency';
  static const transactionDate = 'transaction_date';
  static const categoryId = 'category_id';
  static const merchantOrSource = 'merchant_or_source';
  static const paymentMethod = 'payment_method';
  static const note = 'note';
  static const receiptPath = 'receipt_path';
  static const amountLimit = 'amount_limit';
  static const startDate = 'start_date';
  static const endDate = 'end_date';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';

  const DatabaseColumns._();
}
