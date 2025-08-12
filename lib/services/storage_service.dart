import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage with comprehensive error handling
  Future<String> uploadFile(File file, String path, {String? expectedType}) async {
    try {
      // Validate file before upload
      final validationError = ValidationUtils.validateFileUpload(file, expectedType: expectedType);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Validate path
      if (path.isEmpty) {
        throw Exception('Upload path cannot be empty');
      }

      // Sanitize path to prevent directory traversal
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      final ref = _storage.ref().child(sanitizedPath);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after upload');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Uploads file bytes to Firebase Storage with comprehensive error handling
  Future<String> uploadFileBytes(Uint8List bytes, String path) async {
    try {
      // Validate inputs
      if (bytes.isEmpty) {
        throw Exception('File data is empty');
      }

      if (path.isEmpty) {
        throw Exception('Upload path cannot be empty');
      }

      // Check file size
      if (bytes.length > ValidationUtils.maxFileSize) {
        throw Exception('File size exceeds maximum allowed size');
      }

      // Sanitize path
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      final ref = _storage.ref().child(sanitizedPath);
      final uploadTask = await ref.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after upload');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Deletes a file from Firebase Storage with comprehensive error handling
  Future<void> deleteFile(String url) async {
    try {
      if (url.isEmpty) {
        throw Exception('File URL cannot be empty');
      }

      // Validate URL format
      if (!url.startsWith('https://') || !url.contains('firebasestorage.googleapis.com')) {
        throw Exception('Invalid Firebase Storage URL');
      }

      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Don't throw error if file doesn't exist
      if (e.code == 'object-not-found') {
        return; // File already deleted or never existed
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Deletes multiple files with error handling for each file
  Future<List<String>> deleteFiles(List<String> urls) async {
    final errors = <String>[];
    
    for (final url in urls) {
      try {
        await deleteFile(url);
      } catch (e) {
        errors.add('Failed to delete file $url: ${ErrorHandler.getErrorMessage(e)}');
      }
    }
    
    return errors;
  }

  /// Gets file metadata with error handling
  Future<FullMetadata?> getFileMetadata(String url) async {
    try {
      if (url.isEmpty) {
        throw Exception('File URL cannot be empty');
      }

      final ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null; // File doesn't exist
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to get file metadata: ${ErrorHandler.getErrorMessage(e)}');
    }
  }
}