class Transaction {
  final String id;
  final String type; // 'buy' or 'sell'
  final String saccoName;
  final int numberOfShares;
  final double pricePerShare;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.saccoName,
    required this.numberOfShares,
    required this.pricePerShare,
    required this.timestamp,
  });

  double get totalAmount => numberOfShares * pricePerShare;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['tx_id'] ?? '',
      type: json['tx_type'] ?? 'buy',
      saccoName: json['sacco_name'] ?? 'Unknown SACCO',
      numberOfShares: json['number_of_shares']?.toInt() ?? 0,
      pricePerShare: json['price_per_share']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}