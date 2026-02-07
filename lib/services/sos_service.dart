import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> triggerSOS(String midwifeName, String? emergencyContact) async {
    if (_uid == null) return;

    try {
      // 1. Location අවසර පරීක්ෂා කිරීම
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      // 2. ස්ථානය ලබා ගැනීම
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. දත්ත පද්ධතියට (Firestore) එක් කිරීම
      await _db.collection('emergencies').add({
        'motherId': _uid,
        'midwifeName': midwifeName,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      // 4. ඇමතුම ලබා ගැනීම
      if (emergencyContact != null && emergencyContact.isNotEmpty) {
        final Uri launchUri = Uri(scheme: 'tel', path: emergencyContact);
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        }
      }
    } catch (e) {
      print("SOS Error: $e");
      // දෝෂය නැවත එවීමෙන් HomeScreen එකට එය පෙන්විය හැක
      rethrow; 
    }
  }
}