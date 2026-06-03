class Beneficiary {
  final String id;
  final String nickname;
  final String phoneNumber;
  final String network;
  final String type;
  final String createdAt;

  const Beneficiary({
    required this.id,
    required this.nickname,
    required this.phoneNumber,
    required this.network,
    required this.type,
    required this.createdAt,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
        id: json['id']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        network: json['network']?.toString() ?? '',
        type: json['type']?.toString() ?? 'airtime',
        createdAt: json['created_at']?.toString() ?? '',
      );

  String get displayName => nickname.isNotEmpty ? nickname : phoneNumber;
}
