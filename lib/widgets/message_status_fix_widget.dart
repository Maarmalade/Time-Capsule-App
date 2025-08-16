import 'package:flutter/material.dart';
import '../utils/message_delivery_test.dart';
import '../services/scheduled_message_service.dart';

/// Widget to help fix message delivery status issues
class MessageStatusFixWidget extends StatefulWidget {
  const MessageStatusFixWidget({super.key});

  @override
  State<MessageStatusFixWidget> createState() => _MessageStatusFixWidgetState();
}

class _MessageStatusFixWidgetState extends State<MessageStatusFixWidget> {
  final ScheduledMessageService _messageService = ScheduledMessageService();
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _forceRefreshMessages() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await MessageDeliveryTest.forceRefreshPendingMessages();
      setState(() {
        _statusMessage = 'Messages refreshed successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error refreshing messages: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCloudFunction() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await MessageDeliveryTest.testCloudFunctionDelivery();
      setState(() {
        _statusMessage = result['success'] 
            ? 'Cloud Function test successful: ${result['message']}'
            : 'Cloud Function test failed: ${result['error']}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error testing Cloud Function: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceStatusUpdate() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _messageService.forceStatusUpdate();
      setState(() {
        _statusMessage = 'Status update completed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Message Status Fix Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_statusMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage!.contains('Error') || _statusMessage!.contains('failed')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage!.contains('Error') || _statusMessage!.contains('failed')
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('Error') || _statusMessage!.contains('failed')
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
            ],

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _forceRefreshMessages,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Messages'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCloudFunction,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Test Cloud Function'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _forceStatusUpdate,
                  icon: const Icon(Icons.update),
                  label: const Text('Force Status Update'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'Use these tools if scheduled messages are stuck in "pending" status or not showing as delivered.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}