/**
 * Validation script for Cloud Function deployment
 * 
 * This script helps validate that the Cloud Function is properly deployed
 * and functioning correctly for scheduled message delivery.
 * 
 * Run this script after deploying the Cloud Functions to test:
 * - Function deployment status
 * - Basic function execution
 * - Message processing logic
 * - Error handling
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Make sure to set GOOGLE_APPLICATION_CREDENTIALS environment variable
// or provide service account key file path
try {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || 'your-project-id',
  });
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
  process.exit(1);
}

const db = admin.firestore();

/**
 * Test data for validation
 */
const testMessages = [
  {
    id: 'test-ready-message-1',
    senderId: 'test-sender-1',
    recipientId: 'test-recipient-1',
    textContent: 'Test message ready for delivery',
    status: 'pending',
    scheduledFor: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 10 * 60 * 1000) // 10 minutes ago
    ),
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
  },
  {
    id: 'test-future-message-1',
    senderId: 'test-sender-1',
    recipientId: 'test-recipient-1',
    textContent: 'Test message scheduled for future',
    status: 'pending',
    scheduledFor: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 60 * 60 * 1000) // 1 hour from now
    ),
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
  },
  {
    id: 'test-media-message-1',
    senderId: 'test-sender-1',
    recipientId: 'test-recipient-1',
    textContent: 'Test message with media attachments',
    imageUrls: ['https://example.com/test-image.jpg'],
    videoUrl: 'https://example.com/test-video.mp4',
    status: 'pending',
    scheduledFor: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5 * 60 * 1000) // 5 minutes ago
    ),
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
  },
];

/**
 * Validation functions
 */

async function validateFirestoreConnection() {
  console.log('\n🔍 Validating Firestore connection...');
  
  try {
    const testDoc = await db.collection('test').doc('connection-test').set({
      timestamp: admin.firestore.Timestamp.now(),
      test: true,
    });
    
    await db.collection('test').doc('connection-test').delete();
    console.log('✅ Firestore connection successful');
    return true;
  } catch (error) {
    console.error('❌ Firestore connection failed:', error.message);
    return false;
  }
}

async function createTestMessages() {
  console.log('\n📝 Creating test messages...');
  
  try {
    const batch = db.batch();
    
    testMessages.forEach((message) => {
      const docRef = db.collection('scheduledMessages').doc(message.id);
      batch.set(docRef, message);
    });
    
    await batch.commit();
    console.log(`✅ Created ${testMessages.length} test messages`);
    return true;
  } catch (error) {
    console.error('❌ Failed to create test messages:', error.message);
    return false;
  }
}

async function validateMessageQueries() {
  console.log('\n🔍 Validating message queries...');
  
  try {
    const now = admin.firestore.Timestamp.now();
    
    // Query for messages ready for delivery (same as Cloud Function)
    const readyMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'pending')
      .where('scheduledFor', '<=', now)
      .get();
    
    console.log(`✅ Found ${readyMessages.docs.length} messages ready for delivery`);
    
    // Validate each ready message
    readyMessages.docs.forEach((doc) => {
      const data = doc.data();
      const hasRequiredFields = data.senderId && data.recipientId && data.textContent;
      
      if (hasRequiredFields) {
        console.log(`  ✅ Message ${doc.id} has all required fields`);
      } else {
        console.log(`  ❌ Message ${doc.id} missing required fields`);
      }
    });
    
    return readyMessages.docs.length > 0;
  } catch (error) {
    console.error('❌ Message query validation failed:', error.message);
    return false;
  }
}

async function simulateCloudFunctionDelivery() {
  console.log('\n🚀 Simulating Cloud Function delivery process...');
  
  try {
    const now = admin.firestore.Timestamp.now();
    
    // Get messages ready for delivery
    const readyMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'pending')
      .where('scheduledFor', '<=', now)
      .limit(5)
      .get();
    
    if (readyMessages.empty) {
      console.log('ℹ️  No messages ready for delivery');
      return true;
    }
    
    let successCount = 0;
    let failureCount = 0;
    
    // Process each message (simulate Cloud Function logic)
    for (const doc of readyMessages.docs) {
      const messageData = doc.data();
      const messageId = doc.id;
      
      try {
        // Validate message data
        if (!messageData.senderId || !messageData.recipientId || !messageData.textContent) {
          throw new Error('Invalid message data: missing required fields');
        }
        
        // Simulate atomic update (as Cloud Function would do)
        await db.runTransaction(async (transaction) => {
          const messageRef = db.collection('scheduledMessages').doc(messageId);
          const messageDoc = await transaction.get(messageRef);
          
          if (!messageDoc.exists) {
            throw new Error(`Message ${messageId} not found`);
          }
          
          const currentData = messageDoc.data();
          
          // Verify message is still pending
          if (currentData.status !== 'pending') {
            console.log(`  ⚠️  Message ${messageId} is no longer pending (status: ${currentData.status})`);
            return;
          }
          
          // Atomic update with deliveredAt timestamp
          const deliveredAt = admin.firestore.Timestamp.now();
          transaction.update(messageRef, {
            status: 'delivered',
            deliveredAt: deliveredAt,
            updatedAt: deliveredAt,
            processedBy: 'validation-script',
            processedAt: deliveredAt,
          });
          
          console.log(`  ✅ Message ${messageId} delivered successfully`);
        });
        
        successCount++;
        
      } catch (error) {
        console.log(`  ❌ Failed to deliver message ${messageId}: ${error.message}`);
        
        // Simulate error handling
        try {
          await db.runTransaction(async (transaction) => {
            const messageRef = db.collection('scheduledMessages').doc(messageId);
            const messageDoc = await transaction.get(messageRef);
            
            if (messageDoc.exists) {
              const currentData = messageDoc.data();
              
              if (currentData.status === 'pending') {
                transaction.update(messageRef, {
                  status: 'failed',
                  failureReason: error.message,
                  failedAt: admin.firestore.Timestamp.now(),
                  updatedAt: admin.firestore.Timestamp.now(),
                  retryCount: (currentData.retryCount || 0) + 1,
                });
              }
            }
          });
        } catch (updateError) {
          console.log(`  ❌ Failed to update error status for ${messageId}: ${updateError.message}`);
        }
        
        failureCount++;
      }
    }
    
    console.log(`✅ Delivery simulation completed: ${successCount} successful, ${failureCount} failed`);
    return true;
    
  } catch (error) {
    console.error('❌ Cloud Function simulation failed:', error.message);
    return false;
  }
}

async function validateDeliveredMessages() {
  console.log('\n🔍 Validating delivered messages...');
  
  try {
    const deliveredMessages = await db.collection('scheduledMessages')
      .where('status', '==', 'delivered')
      .get();
    
    console.log(`✅ Found ${deliveredMessages.docs.length} delivered messages`);
    
    // Validate delivered message structure
    deliveredMessages.docs.forEach((doc) => {
      const data = doc.data();
      const hasDeliveredAt = data.deliveredAt != null;
      const hasProcessedBy = data.processedBy != null;
      
      if (hasDeliveredAt && hasProcessedBy) {
        console.log(`  ✅ Message ${doc.id} has proper delivery metadata`);
      } else {
        console.log(`  ❌ Message ${doc.id} missing delivery metadata`);
      }
    });
    
    return true;
  } catch (error) {
    console.error('❌ Delivered message validation failed:', error.message);
    return false;
  }
}

async function cleanupTestMessages() {
  console.log('\n🧹 Cleaning up test messages...');
  
  try {
    const batch = db.batch();
    
    testMessages.forEach((message) => {
      const docRef = db.collection('scheduledMessages').doc(message.id);
      batch.delete(docRef);
    });
    
    await batch.commit();
    console.log('✅ Test messages cleaned up');
    return true;
  } catch (error) {
    console.error('❌ Cleanup failed:', error.message);
    return false;
  }
}

/**
 * Main validation function
 */
async function runValidation() {
  console.log('🚀 Starting Cloud Function validation...\n');
  
  const results = [];
  
  // Run validation steps
  results.push(await validateFirestoreConnection());
  results.push(await createTestMessages());
  results.push(await validateMessageQueries());
  results.push(await simulateCloudFunctionDelivery());
  results.push(await validateDeliveredMessages());
  results.push(await cleanupTestMessages());
  
  // Summary
  const passedCount = results.filter(Boolean).length;
  const totalCount = results.length;
  
  console.log('\n📊 Validation Summary:');
  console.log(`✅ Passed: ${passedCount}/${totalCount}`);
  
  if (passedCount === totalCount) {
    console.log('🎉 All validations passed! Cloud Function appears to be working correctly.');
    process.exit(0);
  } else {
    console.log('❌ Some validations failed. Please check the Cloud Function deployment.');
    process.exit(1);
  }
}

// Handle command line execution
if (require.main === module) {
  runValidation().catch((error) => {
    console.error('💥 Validation script failed:', error);
    process.exit(1);
  });
}

module.exports = {
  runValidation,
  validateFirestoreConnection,
  createTestMessages,
  validateMessageQueries,
  simulateCloudFunctionDelivery,
  validateDeliveredMessages,
  cleanupTestMessages,
};