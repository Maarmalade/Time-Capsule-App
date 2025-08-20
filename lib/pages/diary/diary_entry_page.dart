import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/diary_entry_model.dart';
import '../../services/diary_service.dart';
import '../../services/video_integration_service.dart';

class DiaryEntryPage extends StatefulWidget {
  final DateTime date;
  final DiaryEntry? entry;
  const DiaryEntryPage({super.key, required this.date, this.entry});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final List<DiaryMedia> _media = [];
  bool _isFavorite = false;
  bool _loading = false;

  final DiaryService _diaryService = DiaryService();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
  _titleController.text = widget.entry!.title;
      _textController.text = widget.entry!.text;
      _media.addAll(widget.entry!.media);
      _isFavorite = widget.entry!.isFavorite;
    }
  }

  Future<void> _pickMedia(String type) async {
    final picker = ImagePicker();
    XFile? picked;
    if (type == 'image') {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == 'video') {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    }
    if (picked != null) {
      debugPrint('Image picked: ${picked.path}');
      // Show local preview immediately
      setState(() {
        _media.add(DiaryMedia(url: picked!.path, type: type));
      });
      setState(() => _loading = true);
      File fileToUpload = File(picked.path);
      if (type == 'image') {
        // Compress image before upload
        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );
        if (compressed != null) {
          final tempPath = '${picked.path}_compressed.jpg';
          final compressedFile = await File(tempPath).writeAsBytes(compressed);
          fileToUpload = compressedFile;
        }
      }
      debugPrint('Uploading image to Firebase Storage...');
      final entryId = widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final url = await _diaryService.uploadMedia(userId, entryId, fileToUpload, type);
      debugPrint('Upload complete. Firebase URL: $url');
      setState(() {
        // Replace local preview with Firebase URL
        _media.removeWhere((m) => m.url == picked!.path && m.type == type);
        _media.add(DiaryMedia(url: url, type: type));
        _loading = false;
      });
    }
  }

  void _playVideo(String videoUrl) {
    VideoIntegrationService.showFullScreenVideo(
      context,
      videoUrl,
      title: 'Diary Video',
    );
  }

  Future<void> _saveEntry() async {
    setState(() => _loading = true);
    final data = {
      'title': _titleController.text,
      'date': Timestamp.fromDate(widget.date),
      'text': _textController.text,
      'media': _media.map((m) => m.toMap()).toList(),
      'isFavorite': _isFavorite,
      'createdAt': widget.entry?.createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
    if (widget.entry == null) {
      await _diaryService.createDiaryEntry(userId, data);
    } else {
      await _diaryService.updateDiaryEntry(userId, widget.entry!.id, data);
    }
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${widget.date.day} ${_monthName(widget.date.month)} ${widget.date.year}';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Edit Title'),
                  content: TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Enter title'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(_titleController.text.isEmpty ? 'Title' : _titleController.text),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.yellow : null),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Content'),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Start Writing Here',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._media.map((m) => m.type == 'image'
                          ? (m.url.startsWith('http')
                              ? Image.network(m.url, width: 60, height: 60)
                              : Image.file(File(m.url), width: 60, height: 60))
                          : GestureDetector(
                              onTap: () => _playVideo(m.url),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.videocam, size: 30),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image, size: 32),
                        onPressed: () => _pickMedia('image'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.videocam, size: 32),
                        onPressed: () => _pickMedia('video'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 32),
                        onPressed: () {}, // For future audio support
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite ? Colors.yellow : null,
                          size: 32,
                        ),
                        onPressed: () => setState(() => _isFavorite = !_isFavorite),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}