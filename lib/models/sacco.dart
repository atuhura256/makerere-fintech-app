class Sacco {
  final String saccoId;
  final String name;
  final String registrationNumber;
  final String schemaName;
  final String createdAt;

  Sacco({
    required this.saccoId,
    required this.name,
    required this.registrationNumber,
    required this.schemaName,
    required this.createdAt,
  });

  factory Sacco.fromJson(Map<String, dynamic> json) {
    return Sacco(
      saccoId: json['sacco_id'] as String? ?? '',
      name: json['sacco_name'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? '',
      schemaName: json['schema_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}