import 'package:flutter/material.dart';
import 'balance_store.dart';
import 'ble_buyer.dart';
import 'qr_utils.dart';
import 'models/transaction.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SOMA Buyer', home: BuyerHome());
  }
}

class BuyerHome extends StatefulWidget {
  @override
  _BuyerHomeState createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final BalanceStore _store = BalanceStore();
  final BLEBuyer _ble = BLEBuyer();
  double _balance = 0;
  List<Transaction> _history = [];

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

  Future<void> _payViaQR() async {
    QRUtils.scanQR(context, (qrData) {
      var data = QRUtils.decodeQR(qrData);
      if (data['action'] == 'pay') {
        _confirmPayment(data['amount']);
      }
    });
  }

  Future<void> _confirmPayment(double amount) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأیید پرداخت'),
        content: Text('$amount تومان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('خیر')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            await _ble.connectToSeller();  // بعد از connect, payment ارسال می‌شه
            _loadData();
          }, child: Text('بله')),
        ],
      ),
    );
  }

  Future<void> _payViaBLE() async {
    await _ble.connectToSeller();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SOMA Buyer')),
      body: Column(
        children: [
          Text('موجودی: $_balance تومان'),
          ElevatedButton(onPressed: _payViaQR, child: Text('پرداخت با QR')),
          ElevatedButton(onPressed: _payViaBLE, child: Text('پرداخت با BLE')),
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
