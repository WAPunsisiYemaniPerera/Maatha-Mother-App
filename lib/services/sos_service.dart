import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> triggerSOS(String midwifeName, String? emergencyPhone) async {
    if (_uid == null) return;

    try {
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _db.collection('emergencies').add({
        'motherId': _uid,
        'midwifeName': midwifeName,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending', 
      });

      
      if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
        final Uri launchUri = Uri(scheme: 'tel', path: emergencyPhone);
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}