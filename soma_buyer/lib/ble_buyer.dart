import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';
import '../balance_store.dart';
import '../models/transaction.dart';

class BLEBuyer {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _device;
  final encrypt.Encrypter _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromLength(32)));
  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  Future<void> connectToSeller() async {
    // Scan for devices
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    var subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == 'SOMA_SELLER') {  // نام دستگاه Seller
          _device = r.device;
          _connect();
          break;
        }
      }
    });
    await Future.delayed(Duration(seconds: 5));
    flutterBlue.stopScan();
    subscription.cancel();
  }

  Future<void> _connect() async {
    await _device?.connect();
    List<BluetoothService> services = await _device!.discoverServices();
    BluetoothCharacteristic? characteristic = services
        .expand((s) => s.characteristics)
        .firstWhere((c) => c.uuid.toString() == '0000fff1-0000-1000-8000-00805f9b34fb');  // UUID نمونه برای write
    await characteristic.setNotifyValue(true);

    // Listen for payment request from seller
    characteristic.value.listen((value) {
      String decrypted = _decrypt(value);
      Map<String, dynamic> data = jsonDecode(decrypted);
      if (data['action'] == 'request_payment') {
        // Handle payment
        _sendPayment(data['amount']);
      }
    });
  }

  Future<void> _sendPayment(double amount) async {
    final balanceStore = BalanceStore();
    double current = await balanceStore.getBalance();
    if (current < amount) return;

    String txnId = Uuid().v4();
    final txn = Transaction(
      txnId: txnId,
      amount: amount,
      timestamp: DateTime.now(),
      type: 'debit',
      counterpart: 'Seller',
    );

    // Encrypt payment data
    Map<String, dynamic> payData = {'action': 'payment', 'amount': amount, 'txnId': txnId};
    String encrypted = _encrypt(jsonEncode(payData));

    // Write to characteristic
    BluetoothCharacteristic? char = /* find write char */;
    await char?.write(Uint8List.fromList(utf8.encode(encrypted)));

    // Update local
    await balanceStore.updateBalance(current - amount);
    await balanceStore.addTransaction(txn);
  }

  String _encrypt(String plain) {
    final encrypted = _encrypter.encrypt(plain, iv: _iv);
    return encrypted.base64;
  }

  String _decrypt(List<int> value) {
    String base64 = utf8.decode(value);
    return _encrypter.decrypt64(base64, iv: _iv);
  }

  void disconnect() {
    _device?.disconnect();
  }
}
