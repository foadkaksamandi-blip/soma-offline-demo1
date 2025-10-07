class Transaction {
  final String txnId;
  final double amount;
  final DateTime timestamp;
  final String type;  // 'debit' for buyer, 'credit' for seller
  final String counterpart;  // 'Seller' or 'Buyer'

  Transaction({
    required this.txnId,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.counterpart,
  });

  Map<String, dynamic> toMap() {
    return {
      'txnId': txnId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'counterpart': counterpart,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      txnId: map['txnId'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      counterpart: map['counterpart'],
    );
  }
}
