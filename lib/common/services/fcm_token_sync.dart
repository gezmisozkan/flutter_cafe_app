import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FcmTokenSyncService {
  FcmTokenSyncService(this._firestore, this._messaging);

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<void> saveCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    final doc = _firestore.doc('users/$uid/tokens/$token');
    await doc.set(<String, Object?>{
      'token': token,
      'platform': _platformName(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    final doc = _firestore.doc('users/$uid/tokens/$token');
    await doc.delete().catchError((_) {});
  }

  String _platformName() {
    return kIsWeb ? 'web' : 'app';
  }
}
