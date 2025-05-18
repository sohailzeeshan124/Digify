class SignerInfo {
  final String uid;
  final String displayName;
  final DateTime signedAt;

  SignerInfo({
    required this.uid,
    required this.displayName,
    required this.signedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'signedAt': signedAt.toIso8601String(),
      };

  factory SignerInfo.fromMap(Map<String, dynamic> map) => SignerInfo(
        uid: map['uid'],
        displayName: map['displayName'],
        signedAt: DateTime.parse(map['signedAt']),
      );
}

class DocumentModel {
  final String docId;
  final String docName;
  final String uploadedBy;
  final DateTime createdAt;
  final String pdfUrl;
  final String qrCodeUrl;
  final List<SignerInfo> signedBy;

  DocumentModel({
    required this.docId,
    required this.docName,
    required this.uploadedBy,
    required this.createdAt,
    required this.pdfUrl,
    required this.qrCodeUrl,
    required this.signedBy,
  });

  Map<String, dynamic> toMap() => {
        'docId': docId,
        'docName': docName,
        'uploadedBy': uploadedBy,
        'createdAt': createdAt.toIso8601String(),
        'pdfUrl': pdfUrl,
        'qrCodeUrl': qrCodeUrl,
        'signedBy': signedBy.map((s) => s.toMap()).toList(),
      };

  factory DocumentModel.fromMap(Map<String, dynamic> map) => DocumentModel(
        docId: map['docId'],
        docName: map['docName'],
        uploadedBy: map['uploadedBy'],
        createdAt: DateTime.parse(map['createdAt']),
        pdfUrl: map['pdfUrl'],
        qrCodeUrl: map['qrCodeUrl'],
        signedBy: List<SignerInfo>.from(
            (map['signedBy'] as List).map((e) => SignerInfo.fromMap(e))),
      );
}
