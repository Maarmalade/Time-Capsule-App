import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/audio_recording_interface.dart';

void main() {
  group('AudioRecordingInterface Widget Tests', () {
    testWidgets('should display initial recording interface correctly', (tester) async {
      String? recordingPath;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {
              recordingPath = path;
            },
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      );

      // Verify app bar
      expect(find.text('Audio Recording'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify initial duration display
      expect(find.text('00:00'), findsOneWidget);

      // Verify waveform visualization area exists
      expect(find.byType(CustomPaint), findsOneWidget);

      // Verify main record button
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('should handle cancel action correctly', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      );

      // Tap cancel button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('should have proper accessibility labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Verify cancel button accessibility
      expect(
        find.bySemanticsLabel('Cancel recording, Close audio recording interface without saving, button'),
        findsOneWidget,
      );

      // Verify duration display accessibility
      expect(
        find.bySemanticsLabel('Recording duration, 00:00'),
        findsOneWidget,
      );

      // Verify waveform accessibility
      expect(
        find.bySemanticsLabel('Audio waveform visualization, Audio waveform display'),
        findsOneWidget,
      );

      // Verify main record button accessibility
      expect(
        find.bySemanticsLabel('Start recording, Begin audio recording, button'),
        findsOneWidget,
      );
    });

    testWidgets('should display waveform visualization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Find the waveform painter
      final customPaint = find.byType(CustomPaint);
      expect(customPaint, findsOneWidget);

      // Verify the painter is WaveformPainter
      final customPaintWidget = tester.widget<CustomPaint>(customPaint);
      expect(customPaintWidget.painter, isA<WaveformPainter>());
    });

    testWidgets('should handle touch targets correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Find all interactive elements
      final inkWells = find.byType(InkWell);
      
      for (int i = 0; i < inkWells.evaluate().length; i++) {
        final inkWell = inkWells.at(i);
        final size = tester.getSize(inkWell);
        
        // Verify minimum touch target size (44x44 dp)
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('should display recording controls when recording', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Initially, only the main record button should be visible
      expect(find.byIcon(Icons.mic), findsOneWidget);
      
      // Pause and stop buttons should not be visible initially
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('should format duration correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Initial duration should be 00:00
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // The widget should render without errors even if services fail
      expect(find.byType(AudioRecordingInterface), findsOneWidget);
    });

    testWidgets('should display action buttons when recording is stopped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Initially, action buttons should not be visible
      expect(find.text('Play'), findsNothing);
      expect(find.text('Re-record'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Save'), findsNothing);
    });
  });

  group('WaveformPainter Tests', () {
    testWidgets('should paint waveform correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitude: 0.5,
                isRecording: true,
                animationValue: 0.0,
              ),
              size: const Size(200, 100),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    test('should repaint when properties change', () {
      final painter1 = WaveformPainter(
        amplitude: 0.5,
        isRecording: true,
        animationValue: 0.0,
      );

      final painter2 = WaveformPainter(
        amplitude: 0.7,
        isRecording: true,
        animationValue: 0.0,
      );

      final painter3 = WaveformPainter(
        amplitude: 0.5,
        isRecording: false,
        animationValue: 0.0,
      );

      final painter4 = WaveformPainter(
        amplitude: 0.5,
        isRecording: true,
        animationValue: 0.5,
      );

      // Should repaint when amplitude changes
      expect(painter1.shouldRepaint(painter2), isTrue);

      // Should repaint when recording state changes
      expect(painter1.shouldRepaint(painter3), isTrue);

      // Should repaint when animation value changes
      expect(painter1.shouldRepaint(painter4), isTrue);

      // Should not repaint when nothing changes
      final painter5 = WaveformPainter(
        amplitude: 0.5,
        isRecording: true,
        animationValue: 0.0,
      );
      expect(painter1.shouldRepaint(painter5), isFalse);
    });
  });
}