import 'package:flutter/material.dart';
import '../models/media_file_model.dart';
import 'options_menu_widget.dart';

class MediaCardWidget extends StatelessWidget {
  final MediaFileModel media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // For diary entries
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool isSharedFolder;
  final String? contributorName;

  const MediaCardWidget({
    super.key,
    required this.media,
    this.onTap,
    this.onLongPress,
    this.onEditName,
    this.onDelete,
    this.onEdit,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.isSharedFolder = false,
    this.contributorName,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (media.type == 'image') {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          media.url, 
          width: 60, 
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60),
        ),
      );
    } else if (media.type == 'video') {
      content = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.videocam, size: 30, color: Colors.blue),
      );
    } else if (media.type == 'audio') {
      content = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.audiotrack, size: 30, color: Colors.purple),
      );
    } else if (media.type == 'diary') {
      content = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.book, size: 30, color: Colors.orange),
      );
    } else if (media.type == 'text') {
      content = Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              media.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (media.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                media.description!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
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
              // Main content area
              Positioned.fill(
                child: Column(
                  children: [
                    // Content (icon/image/text) - takes most space
                    Expanded(
                      flex: media.type == 'text' ? 1 : 3,
                      child: Center(child: content),
                    ),
                    
                    // Title area (for non-text media types)
                    if (media.type != 'text' && media.title?.isNotEmpty == true)
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            media.title!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Contributor attribution for shared folders
              if (isSharedFolder && contributorName != null && !isMultiSelectMode)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'by $contributorName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              
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
              if (!isMultiSelectMode && (onEditName != null || onDelete != null || onEdit != null))
                Positioned(
                  top: 8,
                  right: 8,
                  child: OptionsMenuWidget(
                    onEditName: onEditName,
                    onDelete: onDelete,
                    onEdit: onEdit,
                    mediaType: media.type,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}