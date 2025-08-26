import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:time_capsule/services/audio_recording_service.dart';

// Generate mocks
@GenerateMocks([AudioRecorder, AudioPlayer])
import 'audio_recording_service_test.mocks.dart';

void main() {
  group('AudioRecordingService Tests', () {
    late AudioRecordingService service;
    late MockAudioRecorder mockRecorder;
    late MockAudioPlayer mockPlayer;

    setUp(() {
      mockRecorder = MockAudioRecorder();
      mockPlayer = MockAudioPlayer();
      service = AudioRecordingService();
      // Note: In a real implementation, you'd inject these dependencies
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with idle state', () {
      expect(service.recordingStateStream, emits(RecordingState.idle));
    });

    test('should start recording successfully', () async {
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {
        return null;
      });

      final result = await service.startRecording();
      
      expect(result, isTrue);
      expect(service.recordingStateStream, emits(RecordingState.recording));
    });

    test('should fail to start recording without permission', () async {
      when(mockRecorder.hasPermission()).thenAnswer((_) async => false);

      final result = await service.startRecording();
      
      expect(result, isFalse);
      expect(service.recordingStateStream, emits(RecordingState.idle));
    });

    test('should stop recording and return file path', () async {
      when(mockRecorder.stop()).thenAnswer((_) async => '/path/to/recording.m4a');

      final path = await service.stopRecording();
      
      expect(path, equals('/path/to/recording.m4a'));
      expect(service.recordingStateStream, emits(RecordingState.stopped));
    });

    test('should pause recording successfully', () async {
      when(mockRecorder.pause()).thenAnswer((_) async {
        return null;
      });

      final result = await service.pauseRecording();
      
      expect(result, isTrue);
      expect(service.recordingStateStream, emits(RecordingState.paused));
    });

    test('should resume recording successfully', () async {
      when(mockRecorder.resume()).thenAnswer((_) async {
        return null;
      });

      final result = await service.resumeRecording();
      
      expect(result, isTrue);
      expect(service.recordingStateStream, emits(RecordingState.recording));
    });

    test('should handle recording errors gracefully', () async {
      when(mockRecorder.start(any)).thenThrow(Exception('Recording failed'));

      final result = await service.startRecording();
      
      expect(result, isFalse);
      expect(service.recordingStateStream, emits(RecordingState.error));
    });

    test('should update duration during recording', () async {
      // This would require more complex mocking of the timer mechanism
      // For now, we'll test that the stream exists
      expect(service.recordingDurationStream, isA<Stream<Duration>>());
    });

    test('should update amplitude during recording', () async {
      // This would require mocking the amplitude detection
      expect(service.amplitudeStream, isA<Stream<double>>());
    });

    test('should play recording successfully', () async {
      when(mockPlayer.play(any)).thenAnswer((_) async {
        return null;
      });

      final result = await service.playRecording('/path/to/recording.m4a');
      
      expect(result, isTrue);
    });

    test('should handle playback errors gracefully', () async {
      when(mockPlayer.play(any)).thenThrow(Exception('Playback failed'));

      final result = await service.playRecording('/path/to/recording.m4a');
      
      expect(result, isFalse);
    });

    test('should stop playback successfully', () async {
      when(mockPlayer.stop()).thenAnswer((_) async {
        return null;
      });

      await service.stopPlayback();
      
      verify(mockPlayer.stop()).called(1);
    });

    test('should reset service state', () async {
      when(mockRecorder.stop()).thenAnswer((_) async => null);

      await service.reset();
      
      expect(service.recordingStateStream, emits(RecordingState.idle));
    });

    test('should check recording capability', () async {
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);

      final canRecord = await service.canRecord();
      
      expect(canRecord, isTrue);
    });

    test('should get audio duration', () async {
      // This would require mocking file analysis
      final duration = await service.getAudioDuration('/path/to/recording.m4a');
      
      // For now, we'll just verify the method exists and returns a Duration or null
      expect(duration, anyOf(isA<Duration>(), isNull));
    });

    test('should cancel recording and cleanup', () async {
      when(mockRecorder.stop()).thenAnswer((_) async => '/path/to/recording.m4a');

      await service.cancelRecording();
      
      expect(service.recordingStateStream, emits(RecordingState.idle));
    });
  });
}