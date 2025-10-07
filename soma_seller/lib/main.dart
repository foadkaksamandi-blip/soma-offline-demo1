import 'package:flutter/material.dart';
import 'balance_store.dart';
import 'ble_seller.dart';
import 'qr_utils.dart';
import 'models/transaction.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SOMA Seller', home: SellerHome());
  }
}

class SellerHome extends StatefulWidget {
  @override
  _SellerHomeState createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  final BalanceStore _store = BalanceStore();
  final BLESeller _ble = BLESeller();
  double _balance = 0;
  List<Transaction> _history = [];
  double _selectedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _balance = await _store.getBalance();
    _history = await _store.getHistory();
    setState(() {});
  }

  Future<void> _generateQR() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ساخت QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QRUtils.generateQR(_selectedAmount),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) {
                _selectedAmount = double.tryParse(val) ?? 0.0;
              },
              decoration: InputDecoration(labelText: 'مبلغ (تومان)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('بستن')),
        ],
      ),
    );
  }

  Future<void> _advertiseBLE() async {
    if (_selectedAmount > 0) {
      await _ble.startAdvertising(_selectedAmount);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تبلیغات BLE شروع شد')));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SOMA Seller')),
      body: Column(
        children: [
          Text('موجودی: $_balance تومان'),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) {
              _selectedAmount = double.tryParse(val) ?? 0.0;
              setState(() {});
            },
            decoration: InputDecoration(labelText: 'مبلغ فروش'),
          ),
          ElevatedButton(onPressed: _generateQR, child: Text('ساخت QR')),
          ElevatedButton(onPressed: _advertiseBLE, child: Text('شروع BLE')),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_history[index].txnId),
                subtitle: Text('${_history[index].amount} - ${_history[index].type}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
