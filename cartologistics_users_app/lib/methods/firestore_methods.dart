import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();
      
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('Users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user data in Firestore: $e');
    }
  }

  // Get ride data from Firestore
  Future<Map<String, dynamic>?> getRideData(String rideId) async {
    try {
      DocumentSnapshot rideDoc =
          await _firestore.collection('rides').doc(rideId).get();
      
      if (rideDoc.exists) {
        return rideDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting ride data from Firestore: $e');
      return null;
    }
  }

  // Update ride status in Firestore
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating ride status in Firestore: $e');
    }
  }

  // Get all rides for a specific user
  Future<List<Map<String, dynamic>>> getUserRides(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('rides')
          .where('userId', isEqualTo: userId)
          .orderBy('publishDateTime', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting user rides from Firestore: $e');
      return [];
    }
  }

  // Get rides by status
  Future<List<Map<String, dynamic>>> getRidesByStatus(String status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: status)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting rides by status from Firestore: $e');
      return [];
    }
  }

  // Check if user is blocked in Firestore
  Future<bool> isUserBlocked(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return data?['blockStatus'] == 'yes';
      }
      return false;
    } catch (e) {
      print('Error checking user block status in Firestore: $e');
      return false;
    }
  }

  // Listen to user data changes in real-time
  Stream<DocumentSnapshot> listenToUserData(String userId) {
    return _firestore.collection('Users').doc(userId).snapshots();
  }

  // Listen to ride data changes in real-time
  Stream<DocumentSnapshot> listenToRideData(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots();
  }
}
