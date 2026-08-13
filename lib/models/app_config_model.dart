class AppConfigModel {
  final String esewaId;
  final String qrCodeUrl;

  AppConfigModel({
    required this.esewaId,
    required this.qrCodeUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'esewaId': esewaId,
      'qrCodeUrl': qrCodeUrl,
    };
  }

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      esewaId: map['esewaId'] ?? '98XXXXXXXX',
      qrCodeUrl: map['qrCodeUrl'] ?? '',
    );
  }
}
