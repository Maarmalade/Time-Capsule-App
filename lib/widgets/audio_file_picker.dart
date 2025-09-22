import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_file_service.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';

class AudioFilePicker extends StatefulWidget {
  final Function(File, AudioFileMetadata) onFileSelected;
  final Function() onCancel;

  const AudioFilePicker({
    super.key,
    required this.onFileSelected,
    required this.onCancel,
  });

  @override
  State<AudioFilePicker> createState() => _AudioFilePickerState();
}

class _AudioFilePickerState extends State<AudioFilePicker> {
  final AudioFileService _audioFileService = AudioFileService();
  
  File? _selectedFile;
  AudioFileMetadata? _fileMetadata;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _audioFileService.stopPlayback();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = await _audioFileService.pickAudioFile();
      
      if (file != null) {
        final metadata = await _audioFileService.getAudioMetadata(file);
        
        if (metadata != null) {
          setState(() {
            _selectedFile = file;
            _fileMetadata = metadata;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not read audio file metadata';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting audio file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playPreview() async {
    if (_selectedFile == null) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      await _audioFileService.playAudioFile(_selectedFile!.path);
      
      // Stop playing after the duration or 30 seconds, whichever is shorter
      final previewDuration = _fileMetadata?.duration ?? const Duration(seconds: 30);
      final maxPreview = const Duration(seconds: 30);
      final playDuration = previewDuration < maxPreview ? previewDuration : maxPreview;
      
      await Future.delayed(playDuration);
      
      if (mounted) {
        await _stopPreview();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error playing audio preview: $e';
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopPreview() async {
    await _audioFileService.stopPlayback();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFile != null && _fileMetadata != null) {
      widget.onFileSelected(_selectedFile!, _fileMetadata!);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _fileMetadata = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: Text(
          'Select Audio File',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File selection area
              if (_selectedFile == null) ...[
                Expanded(
                  child: _buildFileSelectionArea(),
                ),
              ] else ...[
                // File preview area
                Expanded(
                  child: _buildFilePreviewArea(),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Action buttons
                _buildActionButtons(),
              ],
              
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.errorRedLight,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: AppColors.errorRed),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.errorRedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelectionArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // File icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(
                color: AppColors.borderMedium,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.audiotrack,
              size: 60,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Instructions
          Text(
            'Select an audio file from your device',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            'Supported formats: MP3, M4A, AAC, WAV, OGG, FLAC\nMaximum size: 50MB',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Select button
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAudioFile,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryWhite,
                        ),
                      ),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(_isLoading ? 'Loading...' : 'Select File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.primaryWhite,
                padding: AppSpacing.paddingMd,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewArea() {
    if (_fileMetadata == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File info card
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File name
              Row(
                children: [
                  Icon(
                    Icons.audiotrack,
                    color: AppColors.primaryAccent,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _fileMetadata!.fileName,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // File details
              _buildFileDetail('Duration', _fileMetadata!.formattedDuration),
              _buildFileDetail('Size', _fileMetadata!.formattedFileSize),
              _buildFileDetail('Format', _fileMetadata!.format),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Preview controls
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Column(
            children: [
              Text(
                'Audio Preview',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPreview : _playPreview,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying 
                          ? AppColors.errorRed 
                          : AppColors.successGreen,
                      foregroundColor: AppColors.primaryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Change file button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.refresh),
            label: const Text('Change File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderMedium),
              padding: AppSpacing.paddingMd,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: AppSpacing.md),
        
        // Confirm button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check),
            label: const Text('Use This File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryWhite,
              padding: AppSpacing.paddingMd,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}