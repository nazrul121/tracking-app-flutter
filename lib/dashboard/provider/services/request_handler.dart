import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestHandler {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playAlertSound() async {
    try {
      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      await audioPlayer.setSourceAsset('alert.mp3');
      await audioPlayer.resume();
      print("Sound should be playing.");
    } catch (e) {
      print("Audio play error: $e");
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('provider_notifications')
          .doc(requestId)
          .update({'status': 'accepted'});
      print("Request $requestId accepted.");
    } catch (e) {
      print("Failed to accept request: $e");
    }
  }

  Future<void> ignoreRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('provider_notifications')
          .doc(requestId)
          .update({'status': 'ignored'});
      print("Request $requestId ignored.");
    } catch (e) {
      print("Failed to ignore request: $e");
    }
  }

  Future<void> stopSound() async {
    try {
      await audioPlayer.stop();
    } catch (_) {}
  }

}
