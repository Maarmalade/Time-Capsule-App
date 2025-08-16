/**
 * Firebase Cloud Functions for Time Capsule App
 * 
 * This file contains Cloud Functions for:
 * - Scheduled message delivery
 * - Push notifications
 * - Message status management
 */

const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin SDK
admin.initializeApp();

// For cost control, set maximum number of containers
setGlobalOptions({ maxInstances: 10 });

/**
 * Scheduled function that runs every 5 minutes to check for messages ready for delivery
 * This function processes pending scheduled messages whose delivery time has arrived
 */
exports.processScheduledMessages = onSchedule({
  schedule: "every 5 minutes",
  timeZone: "UTC",
  memory: "256MiB",
  maxInstances: 1, // Only one instance needed for scheduled processing
}, async (event) => {
  logger.info("Starting scheduled message processing...");
  
  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    
    // Query for pending messages that are ready for delivery
    const readyMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'pending')
      .where('scheduledFor', '<=', now)
      .limit(50) // Process in batches to avoid timeouts
      .get();
    
    if (readyMessages.empty) {
      logger.info("No messages ready for delivery");
      return;
    }
    
    logger.info(`Found ${readyMessages.docs.length} messages ready for delivery`);
    
    // Process each message with enhanced error handling
    const deliveryPromises = readyMessages.docs.map(async (doc) => {
      const messageData = doc.data();
      const messageId = doc.id;
      
      try {
        // Validate message data before processing
        if (!messageData.senderId || !messageData.recipientId || !messageData.textContent) {
          throw new Error('Invalid message data: missing required fields');
        }
        
        // Check if message is still valid for delivery
        const scheduledFor = messageData.scheduledFor;
        const now = admin.firestore.Timestamp.now();
        
        if (scheduledFor > now.toMillis() + (5 * 60 * 1000)) { // 5 minute buffer
          logger.warn(`Message ${messageId} scheduled time is too far in future, skipping`);
          return;
        }
        
        await deliverMessage(messageId, messageData);
        logger.info(`Successfully delivered message ${messageId}`);
        
      } catch (error) {
        logger.error(`Failed to deliver message ${messageId}:`, error);
        // Error handling is now done within deliverMessage function
      }
    });
    
    await Promise.allSettled(deliveryPromises);
    logger.info("Completed scheduled message processing");
    
  } catch (error) {
    logger.error("Error in processScheduledMessages:", error);
    throw error;
  }
});

/**
 * Delivers a scheduled message and updates its status
 * @param {string} messageId - The ID of the message to deliver
 * @param {Object} messageData - The message data from Firestore
 */
async function deliverMessage(messageId, messageData) {
  const db = admin.firestore();
  const deliveredAt = admin.firestore.Timestamp.now();
  
  try {
    // Use atomic transaction to ensure status update is consistent
    await db.runTransaction(async (transaction) => {
      const messageRef = db.collection('scheduledMessages').doc(messageId);
      const messageDoc = await transaction.get(messageRef);
      
      if (!messageDoc.exists) {
        throw new Error(`Message ${messageId} not found`);
      }
      
      const currentData = messageDoc.data();
      
      // Verify message is still pending before updating
      if (currentData.status !== 'pending') {
        logger.warn(`Message ${messageId} is no longer pending (status: ${currentData.status}), skipping delivery`);
        return;
      }
      
      // Atomic update with proper deliveredAt timestamp
      transaction.update(messageRef, {
        status: 'delivered',
        deliveredAt: deliveredAt,
        updatedAt: deliveredAt,
        // Add processing metadata for debugging
        processedBy: 'cloud-function',
        processedAt: deliveredAt,
      });
      
      logger.info(`Message ${messageId} status updated to delivered with timestamp ${deliveredAt.toDate().toISOString()}`);
    });
    
    // Send push notification to recipient (outside transaction to avoid timeout)
    try {
      await sendDeliveryNotification(messageData, messageId);
    } catch (notificationError) {
      logger.error(`Failed to send notification for message ${messageId}:`, notificationError);
      // Don't fail the entire delivery if notification fails
    }
    
    logger.info(`Message ${messageId} delivered successfully at ${deliveredAt.toDate().toISOString()}`);
    
  } catch (error) {
    logger.error(`Error delivering message ${messageId}:`, error);
    
    // Try to update message status to failed with proper error handling
    try {
      await db.runTransaction(async (transaction) => {
        const messageRef = db.collection('scheduledMessages').doc(messageId);
        const messageDoc = await transaction.get(messageRef);
        
        if (messageDoc.exists) {
          const currentData = messageDoc.data();
          
          // Only update to failed if still pending
          if (currentData.status === 'pending') {
            transaction.update(messageRef, {
              status: 'failed',
              failureReason: error.message || 'Unknown delivery error',
              failedAt: admin.firestore.Timestamp.now(),
              updatedAt: admin.firestore.Timestamp.now(),
              retryCount: (currentData.retryCount || 0) + 1,
            });
          }
        }
      });
    } catch (updateError) {
      logger.error(`Failed to update message ${messageId} to failed status:`, updateError);
    }
    
    throw error;
  }
}

/**
 * Sends a push notification when a scheduled message is delivered
 * @param {Object} messageData - The message data
 * @param {string} messageId - The message ID for tracking
 */
async function sendDeliveryNotification(messageData, messageId) {
  try {
    const db = admin.firestore();
    
    // Get recipient's FCM token from user profile
    const recipientDoc = await db.collection('users').doc(messageData.recipientId).get();
    
    if (!recipientDoc.exists) {
      logger.warn(`Recipient ${messageData.recipientId} not found`);
      return;
    }
    
    const recipientData = recipientDoc.data();
    const fcmToken = recipientData.fcmToken;
    
    if (!fcmToken) {
      logger.info(`No FCM token for recipient ${messageData.recipientId}`);
      return;
    }
    
    // Get sender's username for notification
    const senderDoc = await db.collection('users').doc(messageData.senderId).get();
    const senderUsername = senderDoc.exists ? senderDoc.data().username : 'Someone';
    
    // Determine notification content
    const isSelfMessage = messageData.senderId === messageData.recipientId;
    const title = isSelfMessage ? 
      "Time Capsule Message Delivered" : 
      `Message from ${senderUsername}`;
    
    const body = messageData.textContent.length > 100 ? 
      `${messageData.textContent.substring(0, 100)}...` : 
      messageData.textContent;
    
    // Create notification payload
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'scheduled_message_delivered',
        messageId: messageId || messageData.id || '',
        senderId: messageData.senderId,
        hasVideo: messageData.videoUrl ? 'true' : 'false',
        hasImages: (messageData.imageUrls && messageData.imageUrls.length > 0) ? 'true' : 'false',
        deliveredAt: new Date().toISOString(),
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#FF6B35',
          channelId: 'scheduled_messages',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };
    
    // Send the notification
    const response = await admin.messaging().send(message);
    logger.info(`Notification sent successfully: ${response}`);
    
  } catch (error) {
    logger.error("Error sending delivery notification:", error);
    // Don't throw error here - notification failure shouldn't fail message delivery
  }
}

/**
 * Trigger function that runs when a new scheduled message is created
 * This function validates the message and sets up any necessary metadata
 */
exports.onScheduledMessageCreated = onDocumentCreated({
  document: "scheduledMessages/{messageId}",
  memory: "256MiB",
}, async (event) => {
  const messageData = event.data.data();
  const messageId = event.params.messageId;
  
  logger.info(`New scheduled message created: ${messageId}`);
  
  try {
    // Validate message data
    if (!messageData.senderId || !messageData.recipientId || !messageData.textContent) {
      logger.error(`Invalid message data for ${messageId}`);
      return;
    }
    
    // Check if scheduled date is in the future
    const scheduledFor = messageData.scheduledFor;
    const now = admin.firestore.Timestamp.now();
    
    if (scheduledFor <= now) {
      logger.warn(`Message ${messageId} scheduled for past date, marking as failed`);
      
      await event.data.ref.update({
        status: 'failed',
        failureReason: 'Scheduled date is in the past',
        failedAt: now,
      });
      return;
    }
    
    // Log successful creation
    const deliveryTime = scheduledFor.toDate();
    logger.info(`Message ${messageId} scheduled for delivery at ${deliveryTime.toISOString()}`);
    
  } catch (error) {
    logger.error(`Error processing new scheduled message ${messageId}:`, error);
  }
});

/**
 * Callable function to manually trigger message delivery (for testing)
 * This function allows manual delivery of a specific message
 */
exports.deliverMessageManually = onCall({
  memory: "256MiB",
}, async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new Error("Authentication required");
  }
  
  const { messageId } = request.data;
  
  if (!messageId) {
    throw new Error("Message ID is required");
  }
  
  try {
    const db = admin.firestore();
    const messageDoc = await db.collection('scheduledMessages').doc(messageId).get();
    
    if (!messageDoc.exists) {
      throw new Error("Message not found");
    }
    
    const messageData = messageDoc.data();
    
    // Verify user has permission to deliver this message (sender or recipient)
    const userId = request.auth.uid;
    if (messageData.senderId !== userId && messageData.recipientId !== userId) {
      throw new Error("Permission denied");
    }
    
    // Check if message is still pending
    if (messageData.status !== 'pending') {
      throw new Error(`Message is already ${messageData.status}`);
    }
    
    // Deliver the message
    await deliverMessage(messageId, messageData);
    
    return { success: true, message: "Message delivered successfully" };
    
  } catch (error) {
    logger.error(`Error in manual message delivery for ${messageId}:`, error);
    throw error;
  }
});

/**
 * Callable function to get delivery statistics
 * Returns counts of pending, delivered, and failed messages
 */
exports.getDeliveryStats = onCall({
  memory: "256MiB",
}, async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new Error("Authentication required");
  }
  
  try {
    const db = admin.firestore();
    const userId = request.auth.uid;
    
    // Get counts for messages sent by this user
    const [pendingSnapshot, deliveredSnapshot, failedSnapshot] = await Promise.all([
      db.collection('scheduledMessages')
        .where('senderId', '==', userId)
        .where('status', '==', 'pending')
        .get(),
      db.collection('scheduledMessages')
        .where('senderId', '==', userId)
        .where('status', '==', 'delivered')
        .get(),
      db.collection('scheduledMessages')
        .where('senderId', '==', userId)
        .where('status', '==', 'failed')
        .get(),
    ]);
    
    return {
      pending: pendingSnapshot.size,
      delivered: deliveredSnapshot.size,
      failed: failedSnapshot.size,
      total: pendingSnapshot.size + deliveredSnapshot.size + failedSnapshot.size,
    };
    
  } catch (error) {
    logger.error("Error getting delivery stats:", error);
    throw error;
  }
});

/**
 * Cleanup function to remove old delivered messages (runs daily)
 * This helps keep the database size manageable
 */
exports.cleanupOldMessages = onSchedule({
  schedule: "0 2 * * *", // Run daily at 2 AM UTC
  timeZone: "UTC",
  memory: "256MiB",
  maxInstances: 1,
}, async (event) => {
  logger.info("Starting cleanup of old messages...");
  
  try {
    const db = admin.firestore();
    
    // Delete delivered messages older than 1 year
    const oneYearAgo = new Date();
    oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
    const cutoffDate = admin.firestore.Timestamp.fromDate(oneYearAgo);
    
    const oldMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'delivered')
      .where('deliveredAt', '<', cutoffDate)
      .limit(100) // Process in batches
      .get();
    
    if (oldMessages.empty) {
      logger.info("No old messages to clean up");
      return;
    }
    
    // Delete old messages in batch
    const batch = db.batch();
    oldMessages.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    logger.info(`Cleaned up ${oldMessages.docs.length} old messages`);
    
  } catch (error) {
    logger.error("Error in cleanup function:", error);
    throw error;
  }
});

/**
 * Error handling function for failed message deliveries
 * This function implements retry logic for failed messages
 */
exports.retryFailedMessages = onCall({
  memory: "256MiB",
}, async (request) => {
  // Verify user is authenticated and is admin (you might want to add admin check)
  if (!request.auth) {
    throw new Error("Authentication required");
  }
  
  try {
    const db = admin.firestore();
    
    // Get failed messages that haven't been retried too many times
    const failedMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'failed')
      .where('retryCount', '<', 3) // Max 3 retries
      .limit(10) // Process small batches
      .get();
    
    if (failedMessages.empty) {
      return { message: "No failed messages to retry", retriedCount: 0 };
    }
    
    let retriedCount = 0;
    
    // Retry each failed message
    for (const doc of failedMessages.docs) {
      const messageData = doc.data();
      const messageId = doc.id;
      
      try {
        // Reset status to pending and increment retry count
        await doc.ref.update({
          status: 'pending',
          retryCount: (messageData.retryCount || 0) + 1,
          lastRetryAt: admin.firestore.Timestamp.now(),
        });
        
        // Attempt delivery
        await deliverMessage(messageId, messageData);
        retriedCount++;
        
      } catch (error) {
        logger.error(`Retry failed for message ${messageId}:`, error);
        
        // Mark as failed again
        await doc.ref.update({
          status: 'failed',
          failureReason: error.message,
          failedAt: admin.firestore.Timestamp.now(),
        });
      }
    }
    
    return { 
      message: `Retried ${retriedCount} out of ${failedMessages.docs.length} failed messages`,
      retriedCount: retriedCount,
      totalFailed: failedMessages.docs.length,
    };
    
  } catch (error) {
    logger.error("Error in retry function:", error);
    throw error;
  }
});

/**
 * Manual trigger function to process pending messages immediately
 * This is useful for testing and manual intervention
 */
exports.triggerMessageDelivery = onCall({
  memory: "256MiB",
}, async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new Error("Authentication required");
  }
  
  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    
    // Query for pending messages that are ready for delivery
    const readyMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'pending')
      .where('scheduledFor', '<=', now)
      .limit(50) // Process in batches to avoid timeouts
      .get();
    
    if (readyMessages.empty) {
      return { message: "No messages ready for delivery", processedCount: 0 };
    }
    
    logger.info(`Found ${readyMessages.docs.length} messages ready for delivery`);
    
    let processedCount = 0;
    let failedCount = 0;
    
    // Process each message with enhanced validation
    for (const doc of readyMessages.docs) {
      const messageData = doc.data();
      const messageId = doc.id;
      
      try {
        // Validate message data before processing
        if (!messageData.senderId || !messageData.recipientId || !messageData.textContent) {
          throw new Error('Invalid message data: missing required fields');
        }
        
        await deliverMessage(messageId, messageData);
        processedCount++;
        logger.info(`Successfully delivered message ${messageId}`);
        
      } catch (error) {
        failedCount++;
        logger.error(`Failed to deliver message ${messageId}:`, error);
        // Error handling is now done within deliverMessage function
      }
    }
    
    return { 
      message: `Processed ${processedCount} messages, ${failedCount} failed`,
      processedCount: processedCount,
      failedCount: failedCount,
      totalFound: readyMessages.docs.length,
    };
    
  } catch (error) {
    logger.error("Error in manual trigger function:", error);
    throw error;
  }
});

/**
 * Test function to validate Cloud Function message processing
 * This function helps test the delivery mechanism and status updates
 */
exports.testMessageDelivery = onCall({
  memory: "256MiB",
}, async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new Error("Authentication required");
  }
  
  const { messageId, forceDelivery } = request.data;
  
  if (!messageId) {
    throw new Error("Message ID is required for testing");
  }
  
  try {
    const db = admin.firestore();
    const messageDoc = await db.collection('scheduledMessages').doc(messageId).get();
    
    if (!messageDoc.exists) {
      throw new Error("Message not found");
    }
    
    const messageData = messageDoc.data();
    const userId = request.auth.uid;
    
    // Verify user has permission to test this message (sender or recipient)
    if (messageData.senderId !== userId && messageData.recipientId !== userId) {
      throw new Error("Permission denied: You can only test your own messages");
    }
    
    // Validate message status
    if (messageData.status !== 'pending' && !forceDelivery) {
      return {
        success: false,
        message: `Message is already ${messageData.status}. Use forceDelivery=true to override.`,
        currentStatus: messageData.status,
        deliveredAt: messageData.deliveredAt ? messageData.deliveredAt.toDate().toISOString() : null,
      };
    }
    
    // Test the delivery process
    const testStartTime = admin.firestore.Timestamp.now();
    
    try {
      // If forcing delivery, temporarily reset status to pending
      if (forceDelivery && messageData.status !== 'pending') {
        await db.collection('scheduledMessages').doc(messageId).update({
          status: 'pending',
          testMode: true,
          testStartedAt: testStartTime,
        });
      }
      
      // Perform the delivery
      await deliverMessage(messageId, messageData);
      
      // Verify the delivery was successful
      const updatedDoc = await db.collection('scheduledMessages').doc(messageId).get();
      const updatedData = updatedDoc.data();
      
      return {
        success: true,
        message: "Message delivery test completed successfully",
        originalStatus: messageData.status,
        newStatus: updatedData.status,
        deliveredAt: updatedData.deliveredAt ? updatedData.deliveredAt.toDate().toISOString() : null,
        processingTime: admin.firestore.Timestamp.now().toMillis() - testStartTime.toMillis(),
        testMode: forceDelivery || false,
      };
      
    } catch (deliveryError) {
      logger.error(`Test delivery failed for message ${messageId}:`, deliveryError);
      
      return {
        success: false,
        message: `Delivery test failed: ${deliveryError.message}`,
        originalStatus: messageData.status,
        error: deliveryError.message,
        processingTime: admin.firestore.Timestamp.now().toMillis() - testStartTime.toMillis(),
      };
    }
    
  } catch (error) {
    logger.error(`Error in test message delivery for ${messageId}:`, error);
    throw error;
  }
});
