import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_message.dart';

class BoardService {
  final FirebaseFirestore db;
  final String uid, name;
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  bool _posting = false;
  BoardService(this.db, this.uid, this.name);
  String get _key => 'pending.$uid';
  Stream<List<BoardMessage>> messageBoard() => db
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(BoardMessage.fromDoc).toList());
  Future<Map<String, dynamic>?> pending() async {
    final value = await prefs.getString(_key);
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> postMessage(String text) async {
    if (_posting) return;
    if (text.trim().isEmpty || text.trim().length > 2000) {
      throw ArgumentError('Invalid text');
    }
    _posting = true;
    try {
      final old = await pending();
      final payload =
          old ??
          {'id': db.collection('messages').doc().id, 'text': text.trim()};
      if (old == null) await prefs.setString(_key, jsonEncode(payload));
      final ref = db.collection('messages').doc(payload['id']);
      final receipt = db
          .collection('users')
          .doc(uid)
          .collection('postReceipts')
          .doc(ref.id);
      try {
        await db.runTransaction((tx) async {
          if ((await tx.get(receipt)).exists) return;
          tx.set(ref, {
            'text': payload['text'],
            'authorUid': uid,
            'authorName': name,
            'createdAt': FieldValue.serverTimestamp(),
            'editedAt': null,
          });
          tx.set(receipt, {
            'messageId': ref.id,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      } on FirebaseException catch (e) {
        // Concurrent commit may be rejected by immutable-receipt rules before
        // SDK conflict retry. A server-confirmed receipt proves completion.
        if (e.code != "permission-denied" ||
            !(await receipt.get(
              const GetOptions(source: Source.server),
            )).exists) {
          rethrow;
        }
      }
      await prefs.remove(_key);
    } finally {
      _posting = false;
    }
  }

  Future<void> editMessage(String id, String text) async {
    if (text.trim().isEmpty || text.trim().length > 2000) {
      throw ArgumentError('Invalid text');
    }
    await db.collection('messages').doc(id).update({
      'text': text.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String id) =>
      db.collection('messages').doc(id).delete();
}
