import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction_item.dart';

class LocalStorageService {
  static const String transactionsBoxKey = "transactionsBox";
  static const String balanceBoxKey = "balanceBox";
  static const String budgetBoxKey = "budgetBoxKey";

  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      // Just to make sure it doesn't initialize twice, it was causing some minor issues without this check
      Hive.registerAdapter(TransactionItemAdapter());
    }
    //
    await Hive.openBox<double>(budgetBoxKey);
    await Hive.openBox<TransactionItem>(transactionsBoxKey);
    await Hive.openBox<double>(balanceBoxKey);
  }

  List<TransactionItem> getAllTransactions() {
    return Hive.box<TransactionItem>(transactionsBoxKey).values.toList();
  }

  double getBalance() {
    return Hive.box<double>(balanceBoxKey).get("balance") ?? 0.0; // 0.0 if null
  }

  double getBudget() {
    return Hive.box<double>(budgetBoxKey).get("budget") ??
        2000.0; // 2000.0 default balance
  }

  void saveTransactionItem(TransactionItem transaction) {
    Hive.box<TransactionItem>(transactionsBoxKey).add(transaction);
    saveBalance(transaction);
  }

  Future<void> saveBalance(TransactionItem item) async {
    final balanceBox = Hive.box<double>(balanceBoxKey);
    final currentBalance = balanceBox.get("balance") ?? 0.0;
    if (item.isExpense) {
      balanceBox.put("balance", currentBalance + item.amount);
    } else {
      balanceBox.put("balance", currentBalance - item.amount);
    }
  }

  Future<void> saveBudget(double budget) {
    return Hive.box<double>(budgetBoxKey).put("budget", budget);
  }

  void deleteTransactionItem(TransactionItem transaction) {
    // Get a list of our transactions
    final transactions = Hive.box<TransactionItem>(transactionsBoxKey);
    // Create a map out of it
    final Map<dynamic, TransactionItem> map = transactions.toMap();
    dynamic desiredKey;
    // For each key in the map, we check if the transaction is the same as the one we want to delete
    map.forEach((key, value) {
      if (value.itemTitle == transaction.itemTitle) desiredKey = key;
    });
    // If we found the key, we delete it
    transactions.delete(desiredKey);
    // And we update the balance
    saveBalanceOnDelete(transaction);
  }

  Future<void> saveBalanceOnDelete(TransactionItem item) async {
    final balanceBox = Hive.box<double>(balanceBoxKey);
    final currentBalance = balanceBox.get("balance") ?? 0.0;
    if (item.isExpense) {
      balanceBox.put("balance", currentBalance - item.amount);
    } else {
      balanceBox.put("balance", currentBalance + item.amount);
    }
  }
}
