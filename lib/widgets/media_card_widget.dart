import 'package:flutter/material.dart';
import '../models/media_file_model.dart';
import 'options_menu_widget.dart';

class MediaCardWidget extends StatelessWidget {
  final MediaFileModel media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isMultiSelectMode;

  const MediaCardWidget({
    super.key,
    required this.media,
    this.onTap,
    this.onLongPress,
    this.onEditName,
    this.onDelete,
    this.isSelected = false,
    this.isMultiSelectMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (media.type == 'image') {
      content = Image.network(media.url, width: 60, height: 60);
    } else if (media.type == 'video') {
      content = const Icon(Icons.videocam, size: 60);
    } else if (media.type == 'text') {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            media.title ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            media.description ?? '',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      content = const Icon(Icons.insert_drive_file, size: 60);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: isSelected ? 8 : 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isSelected 
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          ),
          child: Stack(
            children: [
              Center(child: content),
              
              // Selection indicator
              if (isMultiSelectMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                      border: Border.all(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                  ),
                ),
              
              // Options menu (hidden in multi-select mode)
              if (!isMultiSelectMode && (onEditName != null || onDelete != null))
                Positioned(
                  top: 8,
                  right: 8,
                  child: OptionsMenuWidget(
                    onEditName: onEditName,
                    onDelete: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}