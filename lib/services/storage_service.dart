import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadFileBytes(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putData(bytes);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}