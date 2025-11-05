import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload an image selected via ImagePicker across all platforms (mobile and web).
  /// Uses bytes upload to ensure Flutter Web compatibility.
  static Future<String?> uploadPickedImage(XFile imageFile, String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final contentType = 'image/${fileExt.isEmpty ? 'jpeg' : fileExt}';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}_${imageFile.name}';
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: contentType));
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload an XFile with progress callback (works on web via bytes upload).
  static Future<String?> uploadImageWithProgress(
    XFile imageFile,
    String folder,
    void Function(double progress) onProgress,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final contentType = 'image/${fileExt.isEmpty ? 'jpeg' : fileExt}';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}_${imageFile.name}';
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: contentType));

      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes;
        final sent = event.bytesTransferred;
        if (total > 0) onProgress(sent / total);
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      onProgress(0);
      return null;
    }
  }
}