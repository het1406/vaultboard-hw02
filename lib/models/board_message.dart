import 'package:cloud_firestore/cloud_firestore.dart';

class BoardMessage {
  final String id, text, authorUid, authorName;
  final DateTime? createdAt, editedAt;
  BoardMessage(
    this.id,
    this.text,
    this.authorUid,
    this.authorName,
    this.createdAt,
    this.editedAt,
  );
  factory BoardMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BoardMessage(
      doc.id,
      d['text'],
      d['authorUid'],
      d['authorName'],
      (d['createdAt'] as Timestamp?)?.toDate(),
      (d['editedAt'] as Timestamp?)?.toDate(),
    );
  }
}
