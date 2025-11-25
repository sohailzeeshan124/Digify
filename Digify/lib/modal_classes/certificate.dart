class SignerInfo {
  final String uid;
  final String Name;
  final DateTime signedAt;

  SignerInfo({
    required this.uid,
    required this.Name,
    required this.signedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'Name': Name,
        'signedAt': signedAt.toIso8601String(),
      };

  factory SignerInfo.fromMap(Map<String, dynamic> map) => SignerInfo(
        uid: map['uid'],
        Name: map['Name'],
        signedAt: DateTime.parse(map['signedAt']),
      );
}

class CertificateModel {
  final String docId;
  final String Name;
  final String uploadedBy;
  final DateTime createdAt;
  final String pdfUrl;
  final String localpdfpath;
  final List<SignerInfo> signedBy;

  CertificateModel({
    required this.docId,
    required this.Name,
    required this.uploadedBy,
    required this.createdAt,
    required this.pdfUrl,
    required this.localpdfpath,
    required this.signedBy,
  });

  Map<String, dynamic> toMap() => {
        'docId': docId,
        'Name': Name,
        'uploadedBy': uploadedBy,
        'createdAt': createdAt.toIso8601String(),
        'pdfUrl': pdfUrl,
        'localpdfpath': localpdfpath,
        'signedBy': signedBy.map((s) => s.toMap()).toList(),
      };

  factory CertificateModel.fromMap(Map<String, dynamic> map) =>
      CertificateModel(
        docId: map['docId'],
        Name: map['Name'],
        uploadedBy: map['uploadedBy'],
        createdAt: DateTime.parse(map['createdAt']),
        pdfUrl: map['pdfUrl'],
        localpdfpath: map['localpdfpath'],
        signedBy: List<SignerInfo>.from(
            (map['signedBy'] as List).map((e) => SignerInfo.fromMap(e))),
      );
}
