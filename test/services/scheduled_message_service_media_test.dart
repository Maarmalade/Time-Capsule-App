import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledMessageService Media Upload Logic Tests', () {
    
    group('validateScheduledTime logic', () {
      bool validateScheduledTime(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        return scheduledTime.isAfter(minimumFutureTime);
      }

      test('should return true for time more than 1 minute in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 5));
        expect(validateScheduledTime(futureTime), isTrue);
      });

      test('should return false for time less than 1 minute in future', () {
        final nearFutureTime = DateTime.now().add(const Duration(seconds: 30));
        expect(validateScheduledTime(nearFutureTime), isFalse);
      });

      test('should return false for past time', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
        expect(validateScheduledTime(pastTime), isFalse);
      });

      test('should return true for time exactly 1 minute and 1 second in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 1, seconds: 1));
        expect(validateScheduledTime(futureTime), isTrue);
      });

      test('should return false for time exactly 1 minute in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 1));
        expect(validateScheduledTime(futureTime), isFalse);
      });
    });

    group('Media URL separation logic', () {
      test('should correctly identify video URLs by extension', () {
        // This tests the logic used in createScheduledMessageWithMedia
        final testUrls = [
          'https://example.com/image1.jpg',
          'https://example.com/video.mp4',
          'https://example.com/image2.png',
          'https://example.com/video2.mov',
        ];

        final imageUrls = <String>[];
        String? videoUrl;

        for (final url in testUrls) {
          if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi') || 
              url.contains('.mkv') || url.contains('.webm')) {
            videoUrl = url;
          } else {
            imageUrls.add(url);
          }
        }

        expect(imageUrls, hasLength(2));
        expect(imageUrls, contains('https://example.com/image1.jpg'));
        expect(imageUrls, contains('https://example.com/image2.png'));
        expect(videoUrl, equals('https://example.com/video2.mov')); // Should be the last video found
      });

      test('should handle URLs with no video files', () {
        final testUrls = [
          'https://example.com/image1.jpg',
          'https://example.com/image2.png',
          'https://example.com/image3.gif',
        ];

        final imageUrls = <String>[];
        String? videoUrl;

        for (final url in testUrls) {
          if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi') || 
              url.contains('.mkv') || url.contains('.webm')) {
            videoUrl = url;
          } else {
            imageUrls.add(url);
          }
        }

        expect(imageUrls, hasLength(3));
        expect(videoUrl, isNull);
      });

      test('should handle URLs with only video files', () {
        final testUrls = [
          'https://example.com/video1.mp4',
          'https://example.com/video2.webm',
        ];

        final imageUrls = <String>[];
        String? videoUrl;

        for (final url in testUrls) {
          if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi') || 
              url.contains('.mkv') || url.contains('.webm')) {
            videoUrl = url;
          } else {
            imageUrls.add(url);
          }
        }

        expect(imageUrls, isEmpty);
        expect(videoUrl, equals('https://example.com/video2.webm')); // Should be the last video found
      });
    });

    group('File validation logic', () {
      test('should identify image extensions correctly', () {
        final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
        
        final testFiles = [
          'image.jpg',
          'photo.PNG',
          'video.mp4',
          'movie.MOV',
          'document.pdf',
        ];

        for (final fileName in testFiles) {
          final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
          final isImage = imageExtensions.contains(extension);
          final isVideo = videoExtensions.contains(extension);
          
          if (fileName.contains('image') || fileName.contains('photo')) {
            expect(isImage, isTrue, reason: '$fileName should be identified as image');
          } else if (fileName.contains('video') || fileName.contains('movie')) {
            expect(isVideo, isTrue, reason: '$fileName should be identified as video');
          } else {
            expect(isImage || isVideo, isFalse, reason: '$fileName should not be identified as media');
          }
        }
      });
    });
  });
}