import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

 
  static const String _pepper = "Maatha#Secret#2026";

  //hashing function that combines password, salt, and pepper
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt + _pepper);
    return sha256.convert(bytes).toString();
  }

  Future<User?> signIn(String nic, String password) async {
    try {
      // first, fetch the user document based on NIC to get the salt
      var snapshot = await _db
          .collection('mothers')
          .where('nic', isEqualTo: nic.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("User not found in Firestore");
        return null;
      }

      // get the salt from the user document
      String salt = snapshot.docs.first.get('salt');

      // hash the input password with the retrieved salt and pepper
      String hashedInputPassword = _hashPassword(password.trim(), salt);

      // 4. Email Masking
      String maskedEmail = "${nic.trim().toLowerCase()}@maatha.lk";

      // login with Firebase Auth using the masked email and hashed password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: maskedEmail,
        password: hashedInputPassword,
      );
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.code}");
      return null;
    } catch (e) {
      debugPrint("General Error: $e");
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}