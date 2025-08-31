import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';

import '../../models/diary_entry_model.dart';
import '../../services/media_service.dart';
import '../../widgets/media_source_dialog.dart';
import '../../widgets/audio_recording_interface.dart';
import '../../widgets/audio_file_picker.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';
import '../../utils/accessibility_utils.dart';

/// Comprehensive diary creation and editing interface
class DiaryEditorPage extends StatefulWidget {
  final String folderId;
  final DiaryEntryModel? existingEntry; // null for new entries
  final bool isSharedFolder;
  final DateTime? selectedDate; // Date for the diary entry

  const DiaryEditorPage({
    super.key,
    required this.folderId,
    this.existingEntry,
    this.isSharedFolder = false,
    this.selectedDate,
  });

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  
  final MediaService _mediaService = MediaService();
  
  List<DiaryMediaAttachment> _attachments = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isFavorite = false;
  Timer? _autoSaveTimer;
  
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeEntry();
    _setupAutoSave();
    _setupChangeListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _initializeEntry() {
    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title ?? '';
      _contentController.text = widget.existingEntry!.content;
      _attachments = List.from(widget.existingEntry!.attachments);
      _isFavorite = widget.existingEntry!.isFavorite;
    }
  }

  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges && _canSave()) {
        _autoSave();
      }
    });
  }

  void _setupChangeListeners() {
    _titleController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
      });
    });
    
    _contentController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
      });
    });
  }

  bool _canSave() {
    return _titleController.text.trim().isNotEmpty && 
           _contentController.text.trim().isNotEmpty &&
           _userId != null;
  }

  Future<void> _autoSave() async {
    if (!_canSave()) return;
    
    try {
      final diary = _createDiaryEntry();
      
      if (widget.existingEntry != null) {
        await _mediaService.updateDiaryEntry(
          folderId: widget.folderId,
          diaryId: widget.existingEntry!.id,
          diary: diary,
          userId: _userId!,
        );
      } else {
        // For new entries, we'll save on manual save only
        // Auto-save for new entries could create unwanted drafts
      }
      
      setState(() {
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      // Silent auto-save failure - don't interrupt user
      debugPrint('Auto-save failed: $e');
    }
  }

  DiaryEntryModel _createDiaryEntry() {
    // Use selected date if provided, otherwise use existing entry's diary date or current time
    final diaryDate = widget.selectedDate != null 
        ? Timestamp.fromDate(widget.selectedDate!)
        : (widget.existingEntry?.diaryDate ?? Timestamp.now());
        
    return DiaryEntryModel(
      id: widget.existingEntry?.id ?? '',
      folderId: widget.folderId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      attachments: _attachments,
      createdAt: widget.existingEntry?.createdAt ?? Timestamp.now(), // Keep original creation time for existing entries
      diaryDate: diaryDate, // The date this diary entry is for
      lastModified: Timestamp.now(),
      uploadedBy: widget.isSharedFolder ? _userId : null,
      isFavorite: _isFavorite,
    );
  }

  Future<void> _saveDiary() async {
    if (!_canSave()) {
      _showErrorSnackBar('Please enter both title and content');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diary = _createDiaryEntry();
      
      if (widget.existingEntry != null) {
        await _mediaService.updateDiaryEntry(
          folderId: widget.folderId,
          diaryId: widget.existingEntry!.id,
          diary: diary,
          userId: _userId!,
        );
      } else {
        await _mediaService.createDiaryEntry(
          folderId: widget.folderId,
          diary: diary,
          userId: _userId!,
          isSharedFolder: widget.isSharedFolder,
        );
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save diary: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      _hasUnsavedChanges = true;
    });
    
    _showSuccessSnackBar(
      _isFavorite 
        ? 'Added to favorites! This entry will appear in nostalgia reminders.'
        : 'Removed from favorites.',
    );
  }



  Future<void> _addImageMedia() async {
    // Store ScaffoldMessenger reference early to avoid context issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show media source selection dialog
      final selectedSource = await MediaSourceDialog.show(
        context: context,
        mediaType: MediaSourceType.image,
      );

      if (selectedSource == null || _userId == null) {
        // User cancelled the dialog
        return;
      }

      // Convert to ImageSource
      final imageSource = MediaSourceDialog.toImageSource(selectedSource);
      if (imageSource == null) {
        return;
      }

      // Show loading indicator
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Processing image...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Use enhanced MediaService method
      final media = await _mediaService.captureAndUploadImage(
        folderId: widget.folderId,
        userId: _userId!,
        source: imageSource,
        context: context,
        isSharedFolder: widget.isSharedFolder,
      );

      if (mounted) {
        // Hide loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        if (media != null) {
          final attachment = DiaryMediaAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'image',
            url: media.url,
            position: _attachments.length,
          );

          setState(() {
            _attachments.add(attachment);
            _hasUnsavedChanges = true;
          });

          // Show success message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Image added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        // If media is null, user cancelled during the process (no error message needed)
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addVideoMedia() async {
    // Store ScaffoldMessenger reference early to avoid context issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show media source selection dialog
      final selectedSource = await MediaSourceDialog.show(
        context: context,
        mediaType: MediaSourceType.video,
      );

      if (selectedSource == null || _userId == null) {
        // User cancelled the dialog
        return;
      }

      // Convert to ImageSource
      final imageSource = MediaSourceDialog.toImageSource(selectedSource);
      if (imageSource == null) {
        return;
      }

      // Show loading indicator
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Processing video...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Use enhanced MediaService method
      final media = await _mediaService.captureAndUploadVideo(
        folderId: widget.folderId,
        userId: _userId!,
        source: imageSource,
        context: context,
        isSharedFolder: widget.isSharedFolder,
      );

      if (mounted) {
        // Hide loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        if (media != null) {
          final attachment = DiaryMediaAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'video',
            url: media.url,
            position: _attachments.length,
          );

          setState(() {
            _attachments.add(attachment);
            _hasUnsavedChanges = true;
          });

          // Show success message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Video added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        // If media is null, user cancelled during the process (no error message needed)
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add video: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addAudioMedia() async {
    // Store ScaffoldMessenger reference early to avoid context issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show audio source selection dialog (same as folder detail)
      final selectedSource = await MediaSourceDialog.show(
        context: context,
        mediaType: MediaSourceType.audio,
      );

      if (selectedSource == null || _userId == null) {
        // User cancelled the dialog
        return;
      }

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      if (selectedSource == MediaSource.record) {
        // Handle audio recording
        await _handleAudioRecording(_userId!, scaffoldMessenger);
      } else if (selectedSource == MediaSource.selectFile) {
        // Handle audio file selection
        await _handleAudioFileSelection(_userId!, scaffoldMessenger);
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add audio: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }



  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      _hasUnsavedChanges = true;
      
      // Update positions of remaining attachments
      for (int i = 0; i < _attachments.length; i++) {
        _attachments[i] = DiaryMediaAttachment(
          id: _attachments[i].id,
          type: _attachments[i].type,
          url: _attachments[i].url,
          caption: _attachments[i].caption,
          position: i,
        );
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsaved Changes',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    // Special styling for favorite button
    final isFavoriteButton = label == 'Favourite';
    final activeColor = isFavoriteButton ? AppColors.favoriteYellow : AppColors.primaryAccent;
    final activeBackgroundColor = isFavoriteButton 
        ? AppColors.favoriteYellow.withValues(alpha: 0.2)
        : AppColors.primaryAccent.withValues(alpha: 0.2);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive 
                  ? activeBackgroundColor
                  : AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: isActive 
                  ? Border.all(color: activeColor, width: 1)
                  : null,
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : AppColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAudioRecording(
    String userId,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    // Show audio recording dialog
    final recordingPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: AudioRecordingInterface(
            onRecordingComplete: (path) => Navigator.pop(dialogContext, path),
            onCancel: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    );

    if (recordingPath == null) {
      // User cancelled recording
      return;
    }

    // Show loading indicator
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Uploading audio recording...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Upload recorded audio
      final media = await _mediaService.uploadRecordedAudio(
        folderId: widget.folderId,
        userId: userId,
        recordingPath: recordingPath,
        title: 'Diary Recording',
        isSharedFolder: widget.isSharedFolder,
      );

      if (mounted) {
        // Hide loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        if (media != null) {
          final attachment = DiaryMediaAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'audio',
            url: media.url,
            position: _attachments.length,
          );

          setState(() {
            _attachments.add(attachment);
            _hasUnsavedChanges = true;
          });

          // Show success message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Audio recording added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to upload audio recording: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleAudioFileSelection(
    String userId,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    // Show audio file picker dialog
    final audioFile = await showDialog<File>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: AudioFilePicker(
          onFileSelected: (file, metadata) =>
              Navigator.pop(dialogContext, file),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
    );

    if (audioFile == null) {
      // User cancelled file selection
      return;
    }

    // Show loading indicator
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Uploading audio file...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Upload selected audio file
      final media = await _mediaService.uploadAudioFile(
        folderId: widget.folderId,
        userId: userId,
        audioFile: audioFile,
        title: 'Diary Audio',
        isSharedFolder: widget.isSharedFolder,
      );

      if (mounted) {
        // Hide loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        if (media != null) {
          final attachment = DiaryMediaAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'audio',
            url: media.url,
            position: _attachments.length,
          );

          setState(() {
            _attachments.add(attachment);
            _hasUnsavedChanges = true;
          });

          // Show success message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Audio file added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to upload audio file: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldDiscard = await _onWillPop();
          if (shouldDiscard && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfacePrimary,
        appBar: AppBar(
          backgroundColor: AppColors.surfacePrimary,
          elevation: 0,
          leading: Semantics(
            label: AccessibilityUtils.createSemanticLabel(
              label: 'Close diary editor',
              hint: _hasUnsavedChanges 
                ? 'Close editor, you have unsaved changes'
                : 'Close diary editor',
              isButton: true,
            ),
            button: true,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () async {
                if (await _onWillPop()) {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Close diary editor',
            ),
          ),
          title: Text(
            widget.existingEntry != null ? 'Edit Diary Entry' : 'New Diary Entry',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Semantics(
              label: AccessibilityUtils.createSemanticLabel(
                label: 'Save diary entry',
                hint: _canSave() && !_isLoading 
                  ? 'Save the diary entry'
                  : 'Cannot save, title and content required',
                isButton: true,
              ),
              button: true,
              enabled: _canSave() && !_isLoading,
              child: TextButton(
                onPressed: _canSave() && !_isLoading ? _saveDiary : null,
                child: Text(
                  'Save',
                  style: AppTypography.labelLarge.copyWith(
                    color: _canSave() && !_isLoading 
                      ? AppColors.primaryAccent 
                      : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryAccent),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Saving diary...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderMedium),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Semantics(
                            label: AccessibilityUtils.createSemanticLabel(
                              label: 'Diary entry title',
                              hint: 'Enter a title for your diary entry, required field',
                            ),
                            textField: true,
                            child: TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Diary Entry Title',
                                hintStyle: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                              maxLength: 100,
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.md),
                                  child: Semantics(
                                    label: '$currentLength of ${maxLength ?? 0} characters used',
                                    child: Text(
                                      '$currentLength/${maxLength ?? 0}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Content field - Large text area
                        Container(
                          height: 400, // Fixed height for the content area
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderMedium),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Semantics(
                            label: AccessibilityUtils.createSemanticLabel(
                              label: 'Diary entry content',
                              hint: 'Write your diary entry content, required field, supports multiple lines',
                            ),
                            textField: true,
                            multiline: true,
                            child: TextField(
                              controller: _contentController,
                              focusNode: _contentFocusNode,
                              style: AppTypography.headlineSmall.copyWith( // Same font size as title
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Start writing your diary entry...',
                                hintStyle: AppTypography.headlineSmall.copyWith( // Same font size as title
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(AppSpacing.md),
                              ),
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Attachments section
                        if (_attachments.isNotEmpty) ...[
                          Text(
                            'Attachments',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          
                          ...List.generate(_attachments.length, (index) {
                            final attachment = _attachments[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: AppSpacing.paddingMd,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderMedium),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      attachment.type == 'image' 
                                        ? Icons.image
                                        : attachment.type == 'video'
                                          ? Icons.videocam
                                          : Icons.audiotrack,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${attachment.type.toUpperCase()} Attachment',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: AppTypography.medium,
                                          ),
                                        ),
                                        if (attachment.caption?.isNotEmpty ?? false)
                                          Text(
                                            attachment.caption!,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: AppColors.errorRed,
                                    ),
                                    onPressed: () => _removeAttachment(index),
                                    tooltip: 'Remove attachment',
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            border: Border(
              top: BorderSide(
                color: AppColors.borderMedium,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Add Image button
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: 'Add image',
                      hint: 'Add image from camera or gallery to diary entry',
                      isButton: true,
                    ),
                    button: true,
                    child: _buildMediaButton(
                      icon: Icons.image,
                      label: 'Image',
                      onTap: () => _addImageMedia(),
                    ),
                  ),
                  
                  // Add Video button
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: 'Add video',
                      hint: 'Add video from camera or gallery to diary entry',
                      isButton: true,
                    ),
                    button: true,
                    child: _buildMediaButton(
                      icon: Icons.videocam,
                      label: 'Video',
                      onTap: () => _addVideoMedia(),
                    ),
                  ),
                  
                  // Add Audio button
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: 'Add audio',
                      hint: 'Add audio recording or file to diary entry',
                      isButton: true,
                    ),
                    button: true,
                    child: _buildMediaButton(
                      icon: Icons.mic,
                      label: 'Audio',
                      onTap: () => _addAudioMedia(),
                    ),
                  ),
                  
                  // Favorite toggle (star icon)
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      hint: _isFavorite 
                        ? 'Remove this diary entry from favorites'
                        : 'Add this diary entry to favorites for nostalgia reminders',
                      isButton: true,
                    ),
                    button: true,
                    child: _buildMediaButton(
                      icon: _isFavorite ? Icons.star : Icons.star_outline,
                      label: 'Favourite',
                      onTap: () => _toggleFavorite(),
                      isActive: _isFavorite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}