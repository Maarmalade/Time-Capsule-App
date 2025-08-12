import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';
import '../utils/error_handler.dart';

class EditNameDialog extends StatefulWidget {
  final String currentName;
  final String title;
  final String hintText;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.title,
    required this.hintText,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _handleSave() {
    final newName = _controller.text.trim();
    
    // Validate the name
    final validationError = ValidationUtils.validateFileName(newName);
    if (validationError != null) {
      ErrorHandler.showErrorSnackBar(context, validationError);
      return;
    }
    
    // Check if name is the same
    if (newName == widget.currentName) {
      Navigator.pop(context);
      return;
    }
    
    // Sanitize the name
    final sanitizedName = ValidationUtils.sanitizeText(newName);
    if (!ValidationUtils.isSafeForDisplay(sanitizedName)) {
      ErrorHandler.showErrorSnackBar(context, 'Name contains invalid characters');
      return;
    }
    
    Navigator.pop(context, sanitizedName);
  }
}