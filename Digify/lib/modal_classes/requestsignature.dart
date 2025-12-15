class RequestSignature {
  final String requestUid;
  final String title;
  final String description;
  final String documentUid;
  final List<String> signerIds;
  final String communityId;
  final bool isRejected;
  final String? rejectionReason;
  final String userId;
  final String status; // 'in progress', 'rejected', 'completed'
  final List<String> signedIds;

  RequestSignature({
    required this.requestUid,
    required this.title,
    required this.description,
    required this.documentUid,
    required this.signerIds,
    required this.communityId,
    this.isRejected = false,
    this.rejectionReason,
    required this.userId,
    this.signedIds = const [],
    this.status = 'in progress',
  });

  Map<String, dynamic> toMap() {
    return {
      'requestUid': requestUid,
      'title': title,
      'description': description,
      'documentUid': documentUid,
      'signerIds': signerIds,
      'communityId': communityId,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
      'userId': userId,
      'signedIds': signedIds,
      'status': status,
    };
  }

  factory RequestSignature.fromMap(Map<String, dynamic> map) {
    return RequestSignature(
      requestUid: map['requestUid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      documentUid: map['documentUid'] ?? '',
      signerIds: List<String>.from(map['signerIds'] ?? []),
      communityId: map['communityId'] ?? '',
      isRejected: map['isRejected'] ?? false,
      rejectionReason: map['rejectionReason'],
      userId: map['userId'] ?? '',
      signedIds: List<String>.from(map['signedIds'] ?? []),
      status: map['status'] ?? 'in progress',
    );
  }
}
