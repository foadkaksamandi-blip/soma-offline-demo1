import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';
import '../balance_store.dart';
import '../models/transaction.dart';

class BLESeller {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _device;
  final encrypt.Encrypter _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromLength(32)));
  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  Future<void> startAdvertising(double amount) async {
    // Advertise as server
    await flutterBlue.startAdvertising(
      name: 'SOMA_SELLER',
      withServices: [Guid('0000fff0-0000-1000-8000-00805f9b34fb')],  // Service UUID
    );

    // Listen for connections
    var subscription = flutterBlue.connectedDevices.asStream().listen((devices) {
      if (devices.isNotEmpty) {
        _device = devices.first;
        _handleConnection(amount);
      }
    });
  }

  Future<void> _handleConnection(double amount) async {
    await _device?.discoverServices();
    BluetoothCharacteristic? char = /* find read char */;
    await char?.setNotifyValue(true);

    // Send request
    Map<String, dynamic> reqData = {'action': 'request_payment', 'amount': amount};
    String encrypted = _encrypt(jsonEncode(reqData));
    await char?.write(Uint8List.fromList(utf8.encode(encrypted)));

    // Listen for payment
    char!.value.listen((value) async {
      String decrypted = _decrypt(value);
      Map<String, dynamic> data = jsonDecode(decrypted);
      if (data['action'] == 'payment') {
        String txnId = data['txnId'];
        final balanceStore = BalanceStore();
        double current = await balanceStore.getBalance();
        await balanceStore.updateBalance(current + amount);

        final txn = Transaction(
          txnId: txnId,
          amount: amount,
          timestamp: DateTime.now(),
          type: 'credit',
          counterpart: 'Buyer',
        );
        await balanceStore.addTransaction(txn);
      }
    });
  }

  String _encrypt(String plain) {
    final encrypted = _encrypter.encrypt(plain, iv: _iv);
    return encrypted.base64;
  }

  String _decrypt(List<int> value) {
    String base64 = utf8.decode(value);
    return _encrypter.decrypt64(base64, iv: _iv);
  }

  void stopAdvertising() {
    flutterBlue.stopAdvertising();
  }
}
