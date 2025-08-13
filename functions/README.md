# Time Capsule Cloud Functions

This directory contains Firebase Cloud Functions for the Time Capsule app, specifically for handling scheduled message delivery and related functionality.

## Functions Overview

### Scheduled Functions

#### `processScheduledMessages`
- **Trigger**: Runs every 5 minutes via Cloud Scheduler
- **Purpose**: Processes pending scheduled messages that are ready for delivery
- **Features**:
  - Queries for messages with `status: 'pending'` and `scheduledFor <= now`
  - Processes up to 50 messages per run to avoid timeouts
  - Updates message status to `delivered` or `failed`
  - Sends push notifications to recipients
  - Handles errors gracefully with proper logging

#### `cleanupOldMessages`
- **Trigger**: Runs daily at 2 AM UTC via Cloud Scheduler
- **Purpose**: Removes old delivered messages to keep database size manageable
- **Features**:
  - Deletes messages with `status: 'delivered'` older than 1 year
  - Processes in batches of 100 messages
  - Helps maintain database performance

### Firestore Triggers

#### `onScheduledMessageCreated`
- **Trigger**: When a document is created in `scheduledMessages` collection
- **Purpose**: Validates new scheduled messages and sets up metadata
- **Features**:
  - Validates required fields (senderId, recipientId, textContent)
  - Checks if scheduled date is in the future
  - Marks messages with past dates as failed
  - Logs message creation for monitoring

### Callable Functions

#### `deliverMessageManually`
- **Trigger**: HTTP callable function
- **Purpose**: Allows manual delivery of specific messages (useful for testing)
- **Authentication**: Required
- **Authorization**: User must be sender or recipient of the message
- **Parameters**:
  - `messageId`: ID of the message to deliver
- **Returns**: Success/failure status

#### `getDeliveryStats`
- **Trigger**: HTTP callable function
- **Purpose**: Returns delivery statistics for the authenticated user
- **Authentication**: Required
- **Returns**:
  ```json
  {
    "pending": 5,
    "delivered": 10,
    "failed": 2,
    "total": 17
  }
  ```

#### `retryFailedMessages`
- **Trigger**: HTTP callable function
- **Purpose**: Retries failed message deliveries (admin function)
- **Authentication**: Required
- **Features**:
  - Retries messages with `status: 'failed'` and `retryCount < 3`
  - Processes up to 10 messages per call
  - Increments retry count and updates timestamps
  - Returns retry statistics

## Message Delivery Process

1. **Message Creation**: User creates a scheduled message via the app
2. **Validation**: `onScheduledMessageCreated` validates the message
3. **Scheduling**: Message waits in `pending` status until delivery time
4. **Processing**: `processScheduledMessages` runs every 5 minutes to check for ready messages
5. **Delivery**: Message status is updated to `delivered` and notification is sent
6. **Cleanup**: Old delivered messages are cleaned up daily

## Push Notifications

The functions integrate with Firebase Cloud Messaging (FCM) to send push notifications when messages are delivered:

- **Title**: "Time Capsule Message Delivered" (self-messages) or "Message from [username]"
- **Body**: Message content (truncated to 100 characters if longer)
- **Data**: Includes message metadata for app handling
- **Platform-specific**: Configured for both Android and iOS

## Error Handling

- **Delivery Failures**: Messages that fail to deliver are marked with `status: 'failed'`
- **Retry Logic**: Failed messages can be retried up to 3 times
- **Graceful Degradation**: Notification failures don't prevent message delivery
- **Comprehensive Logging**: All operations are logged for monitoring and debugging

## Security

- **Authentication**: All callable functions require user authentication
- **Authorization**: Users can only access their own messages or messages they're recipients of
- **Data Validation**: All inputs are validated before processing
- **Rate Limiting**: Batch processing prevents resource exhaustion

## Development

### Setup
```bash
cd functions
npm install
```

### Testing
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Local Development
```bash
# Start Firebase emulators
npm run serve

# Test functions locally
npm run shell
```

### Deployment
```bash
# Deploy all functions
npm run deploy

# Deploy specific function
firebase deploy --only functions:processScheduledMessages
```

### Monitoring
```bash
# View function logs
npm run logs

# View specific function logs
firebase functions:log --only processScheduledMessages
```

## Configuration

### Environment Variables
The functions use Firebase Admin SDK which automatically configures itself in the Firebase environment. For local development, ensure you have:

1. Firebase project configured
2. Service account key (for local testing)
3. Firestore database enabled
4. Cloud Messaging enabled

### Firestore Security Rules
Ensure your Firestore security rules allow the Cloud Functions to read/write scheduled messages:

```javascript
// Allow Cloud Functions to access scheduled messages
match /scheduledMessages/{messageId} {
  allow read, write: if request.auth != null && 
    (resource.data.senderId == request.auth.uid || 
     resource.data.recipientId == request.auth.uid);
}
```

### FCM Setup
For push notifications to work:

1. Enable Firebase Cloud Messaging in your project
2. Configure FCM tokens in user profiles
3. Set up notification channels in your mobile app
4. Handle notification data in your app

## Monitoring and Alerts

Consider setting up monitoring for:

- Function execution errors
- Message delivery failures
- High retry rates
- Function timeout issues
- Database query performance

## Cost Optimization

The functions are designed with cost optimization in mind:

- **Batch Processing**: Limits concurrent executions
- **Efficient Queries**: Uses indexed fields and limits
- **Cleanup**: Removes old data to reduce storage costs
- **Error Handling**: Prevents infinite retry loops
- **Resource Limits**: Configured with appropriate memory and timeout settings

## Troubleshooting

### Common Issues

1. **Messages not delivering**: Check function logs and message status
2. **Notifications not received**: Verify FCM token and app configuration
3. **Function timeouts**: Reduce batch sizes or optimize queries
4. **Permission errors**: Check Firestore security rules and authentication

### Debug Commands
```bash
# Check function status
firebase functions:list

# View recent logs
firebase functions:log --limit 50

# Test specific function
firebase functions:shell
> processScheduledMessages()
```