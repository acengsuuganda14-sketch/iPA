import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/finance_chart.dart'; // Pastikan import ini benar
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Color constants untuk mengganti withOpacity
  static const Color lightWhite = Color(0x33FFFFFF);
  static const Color lightGreen = Color(0x334CAF50);
  static const Color lightRed = Color(0x33F44336);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (transactionProvider.isLoading && transactionProvider.transactions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Memuat data transaksi...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Keuangan Saya'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              transactionProvider.loadTransactions();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data diperbarui'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Overview
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Month Filter
                _buildMonthFilter(transactionProvider),
                SizedBox(height: 16),

                Text(
                  'Saldo Saat Ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  currencyFormat.format(transactionProvider.balance),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountCard(
                      'Pemasukan',
                      transactionProvider.totalIncome,
                      Colors.green,
                    ),
                    _buildAmountCard(
                      'Pengeluaran',
                      transactionProvider.totalExpense,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chart Section
          if (transactionProvider.transactions.isNotEmpty)
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              child: FinanceChart(transactionProvider: transactionProvider),
            ),

          // Transactions List Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transactionProvider.showAllMonths
                      ? 'Semua Transaksi'
                      : 'Transaksi ${DateFormat('MMMM yyyy').format(transactionProvider.selectedMonth)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${transactionProvider.filteredTransactions.length}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: transactionProvider.filteredTransactions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => transactionProvider.loadTransactions(),
              child: ListView.builder(
                itemCount: transactionProvider.filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactionProvider.filteredTransactions[index];
                  return _buildTransactionCard(transaction, currencyFormat, transactionProvider);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(),
            ),
          ).then((result) {
            if (result != null && result is Transaction) {
              _addNewTransaction(result, transactionProvider);
            }
          });
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
        tooltip: 'Tambah Transaksi',
      ),
    );
  }

  Widget _buildMonthFilter(TransactionProvider provider) {
    DateTime? validValue;

    try {
      final isValueValid = provider.availableMonths.any((month) =>
      month.year == provider.selectedMonth.year &&
          month.month == provider.selectedMonth.month);

      if (isValueValid && provider.availableMonths.isNotEmpty) {
        validValue = provider.selectedMonth;
      } else if (provider.availableMonths.isNotEmpty) {
        validValue = provider.availableMonths.first;
      } else {
        validValue = DateTime(DateTime.now().year, DateTime.now().month);
      }
    } catch (e) {
      validValue = provider.availableMonths.isNotEmpty
          ? provider.availableMonths.first
          : DateTime(DateTime.now().year, DateTime.now().month);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: lightWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<DateTime>(
              value: validValue,
              isExpanded: true,
              dropdownColor: Colors.blue,
              style: TextStyle(color: Colors.white, fontSize: 14),
              underline: SizedBox(),
              items: provider.availableMonths.map((DateTime month) {
                return DropdownMenuItem<DateTime>(
                  value: month,
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (DateTime? newMonth) {
                if (newMonth != null) {
                  provider.setSelectedMonth(newMonth);
                  if (provider.showAllMonths) {
                    provider.toggleShowAllMonths();
                  }
                }
              },
            ),
          ),
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              provider.toggleShowAllMonths();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: provider.showAllMonths ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                'Semua',
                style: TextStyle(
                  color: provider.showAllMonths ? Colors.blue : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + untuk menambah transaksi pertama',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(),
                ),
              ).then((result) {
                if (result != null && result is Transaction) {
                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                  _addNewTransaction(result, provider);
                }
              });
            },
            child: Text('Tambah Transaksi Pertama'),
          ),
        ],
      ),
    );
  }

  void _addNewTransaction(Transaction transaction, TransactionProvider provider) async {
    try {
      await provider.addTransaction(transaction);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Gagal menambah transaksi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAmountCard(String title, double amount, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white70)),
        SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction, NumberFormat currencyFormat, TransactionProvider transactionProvider) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Hapus Transaksi?'),
              content: Text('Apakah Anda yakin ingin menghapus transaksi "${transaction.category}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await transactionProvider.deleteTransaction(transaction.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaksi dihapus'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Gagal menghapus transaksi'),
              backgroundColor: Colors.red,
            ),
          );
          transactionProvider.loadTransactions();
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.type == TransactionType.income
                ? lightGreen
                : lightRed,
            child: Icon(
              transaction.type == TransactionType.income
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            transaction.category,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.description.isNotEmpty)
                Text(
                  transaction.description,
                  style: TextStyle(fontSize: 12),
                ),
              Text(
                '${transaction.formattedDate} ${transaction.formattedTime}',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(transaction.amount),
                style: TextStyle(
                  color: transaction.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                transaction.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}