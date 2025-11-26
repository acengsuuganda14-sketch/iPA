import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showAllMonths = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get showAllMonths => _showAllMonths;

  // GETTER YANG DIPERLUKAN
  double get balance => totalIncome - totalExpense;

  double get totalIncome {
    return filteredTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalExpense {
    return filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  List<Transaction> get filteredTransactions {
    if (_showAllMonths) {
      return _transactions;
    } else {
      return _transactions.where((transaction) {
        return transaction.date.year == _selectedMonth.year &&
            transaction.date.month == _selectedMonth.month;
      }).toList();
    }
  }

  Map<DateTime, double> get weeklyIncomeData {
    Map<DateTime, double> data = {};
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime(now.year, now.month, now.day - i);
      double total = _transactions
          .where((t) =>
      t.type == TransactionType.income &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      data[date] = total;
    }
    return data;
  }

  Map<DateTime, double> get weeklyExpenseData {
    Map<DateTime, double> data = {};
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime(now.year, now.month, now.day - i);
      double total = _transactions
          .where((t) =>
      t.type == TransactionType.expense &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      data[date] = total;
    }
    return data;
  }

  List<DateTime> get availableMonths {
    if (_transactions.isEmpty) {
      return [DateTime(DateTime.now().year, DateTime.now().month)];
    }

    Set<String> monthYears = {};
    for (var transaction in _transactions) {
      DateTime date = transaction.date;
      DateTime normalizedDate = DateTime(date.year, date.month);
      monthYears.add('${normalizedDate.year}-${normalizedDate.month}');
    }

    List<DateTime> months = monthYears.map((monthYear) {
      List<String> parts = monthYear.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList();

    months.sort((a, b) => b.compareTo(a));

    if (months.isEmpty) {
      months.add(DateTime(DateTime.now().year, DateTime.now().month));
    }

    return months;
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void toggleShowAllMonths() {
    _showAllMonths = !_showAllMonths;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _databaseHelper.getTransactions();

      final available = availableMonths;
      if (available.isNotEmpty) {
        bool currentMonthExists = available.any((month) =>
        month.year == _selectedMonth.year && month.month == _selectedMonth.month);

        if (!currentMonthExists) {
          _selectedMonth = available.first;
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _databaseHelper.insertTransaction(transaction);
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      print('Error adding transaction: $e');
      throw e;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _databaseHelper.deleteTransaction(id);
      _transactions.removeWhere((transaction) => transaction.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting transaction: $e');
      throw e;
    }
  }
}