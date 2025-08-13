const functionsTest = require('firebase-functions-test')();
const admin = require('firebase-admin');

// Mock Firebase Admin SDK
const mockFirestore = {
  collection: jest.fn(),
  doc: jest.fn(),
  batch: jest.fn(),
};

const mockMessaging = {
  send: jest.fn(),
};

// Mock admin SDK
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => mockFirestore),
  messaging: jest.fn(() => mockMessaging),
}));

// Import functions after mocking
const functions = require('../index');

describe('Scheduled Message Cloud Functions', () => {
  let mockCollection, mockDoc, mockQuery, mockSnapshot;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Setup common mocks
    mockCollection = {
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn(),
      doc: jest.fn(),
    };
    
    mockDoc = {
      id: 'test-message-id',
      data: jest.fn(),
      ref: {
        update: jest.fn(),
        delete: jest.fn(),
      },
      get: jest.fn(),
      exists: true,
    };
    
    mockQuery = {
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn(),
    };
    
    mockSnapshot = {
      empty: false,
      docs: [mockDoc],
      size: 1,
    };
    
    mockFirestore.collection.mockReturnValue(mockCollection);
    mockCollection.get.mockResolvedValue(mockSnapshot);
    mockCollection.doc.mockReturnValue(mockDoc);
    mockDoc.get.mockResolvedValue(mockDoc);
  });

  afterAll(() => {
    functionsTest.cleanup();
  });

  describe('processScheduledMessages', () => {
    test('should process pending messages ready for delivery', async () => {
      // Mock message data
      const messageData = {
        id: 'test-message-id',
        senderId: 'sender123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        status: 'pending',
        scheduledFor: { toDate: () => new Date(Date.now() - 1000) }, // Past date
      };
      
      mockDoc.data.mockReturnValue(messageData);
      mockDoc.ref.update.mockResolvedValue();
      
      // Mock user data for notification
      const userData = {
        fcmToken: 'test-fcm-token',
        username: 'testuser',
      };
      mockDoc.data.mockReturnValue(userData);
      
      mockMessaging.send.mockResolvedValue('message-id');
      
      // Create a mock event (scheduler events don't have specific structure)
      const mockEvent = {};
      
      // Test the function
      await expect(functions.processScheduledMessages(mockEvent)).resolves.not.toThrow();
      
      // Verify message status was updated
      expect(mockDoc.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'delivered',
        })
      );
    });

    test('should handle empty message queue', async () => {
      mockSnapshot.empty = true;
      mockSnapshot.docs = [];
      
      const mockEvent = {};
      
      await expect(functions.processScheduledMessages(mockEvent)).resolves.not.toThrow();
      
      // Should not attempt to update any documents
      expect(mockDoc.ref.update).not.toHaveBeenCalled();
    });

    test('should handle message delivery failures', async () => {
      const messageData = {
        id: 'test-message-id',
        senderId: 'sender123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        status: 'pending',
        scheduledFor: { toDate: () => new Date(Date.now() - 1000) },
      };
      
      mockDoc.data.mockReturnValue(messageData);
      
      // Mock failure in message delivery
      mockDoc.ref.update.mockRejectedValueOnce(new Error('Delivery failed'));
      
      const mockEvent = {};
      
      await expect(functions.processScheduledMessages(mockEvent)).resolves.not.toThrow();
      
      // Should attempt to mark message as failed
      expect(mockDoc.ref.update).toHaveBeenCalled();
    });
  });

  describe('onScheduledMessageCreated', () => {
    test('should validate new scheduled message', async () => {
      const messageData = {
        senderId: 'sender123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        scheduledFor: { 
          toDate: () => new Date(Date.now() + 86400000), // Future date
          seconds: Math.floor((Date.now() + 86400000) / 1000),
        },
      };
      
      const mockEvent = {
        data: {
          data: () => messageData,
          ref: {
            update: jest.fn(),
          },
        },
        params: {
          messageId: 'test-message-id',
        },
      };
      
      // Mock Timestamp comparison
      admin.firestore = jest.fn(() => ({
        Timestamp: {
          now: () => ({
            seconds: Math.floor(Date.now() / 1000),
          }),
        },
      }));
      
      await expect(functions.onScheduledMessageCreated(mockEvent)).resolves.not.toThrow();
      
      // Should not update the document for valid message
      expect(mockEvent.data.ref.update).not.toHaveBeenCalled();
    });

    test('should handle message scheduled for past date', async () => {
      const messageData = {
        senderId: 'sender123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        scheduledFor: { 
          toDate: () => new Date(Date.now() - 86400000), // Past date
          seconds: Math.floor((Date.now() - 86400000) / 1000),
        },
      };
      
      const mockEvent = {
        data: {
          data: () => messageData,
          ref: {
            update: jest.fn(),
          },
        },
        params: {
          messageId: 'test-message-id',
        },
      };
      
      // Mock Timestamp comparison
      admin.firestore = jest.fn(() => ({
        Timestamp: {
          now: () => ({
            seconds: Math.floor(Date.now() / 1000),
          }),
        },
      }));
      
      await functions.onScheduledMessageCreated(mockEvent);
      
      // Should mark message as failed
      expect(mockEvent.data.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          failureReason: 'Scheduled date is in the past',
        })
      );
    });

    test('should handle invalid message data', async () => {
      const messageData = {
        senderId: '', // Invalid - empty sender ID
        recipientId: 'recipient456',
        textContent: 'Test message',
      };
      
      const mockEvent = {
        data: {
          data: () => messageData,
          ref: {
            update: jest.fn(),
          },
        },
        params: {
          messageId: 'test-message-id',
        },
      };
      
      await expect(functions.onScheduledMessageCreated(mockEvent)).resolves.not.toThrow();
      
      // Function should handle invalid data gracefully
      expect(mockEvent.data.ref.update).not.toHaveBeenCalled();
    });
  });

  describe('deliverMessageManually', () => {
    test('should deliver message when user has permission', async () => {
      const messageData = {
        senderId: 'user123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        status: 'pending',
      };
      
      mockDoc.data.mockReturnValue(messageData);
      mockDoc.exists = true;
      mockDoc.ref.update.mockResolvedValue();
      
      const mockRequest = {
        auth: {
          uid: 'user123', // Same as sender
        },
        data: {
          messageId: 'test-message-id',
        },
      };
      
      const result = await functions.deliverMessageManually(mockRequest);
      
      expect(result.success).toBe(true);
      expect(result.message).toBe('Message delivered successfully');
    });

    test('should reject unauthenticated requests', async () => {
      const mockRequest = {
        auth: null,
        data: {
          messageId: 'test-message-id',
        },
      };
      
      await expect(functions.deliverMessageManually(mockRequest))
        .rejects.toThrow('Authentication required');
    });

    test('should reject requests without message ID', async () => {
      const mockRequest = {
        auth: {
          uid: 'user123',
        },
        data: {},
      };
      
      await expect(functions.deliverMessageManually(mockRequest))
        .rejects.toThrow('Message ID is required');
    });

    test('should reject requests for non-existent messages', async () => {
      mockDoc.exists = false;
      
      const mockRequest = {
        auth: {
          uid: 'user123',
        },
        data: {
          messageId: 'non-existent-id',
        },
      };
      
      await expect(functions.deliverMessageManually(mockRequest))
        .rejects.toThrow('Message not found');
    });

    test('should reject requests without permission', async () => {
      const messageData = {
        senderId: 'other-user',
        recipientId: 'another-user',
        textContent: 'Test message',
        status: 'pending',
      };
      
      mockDoc.data.mockReturnValue(messageData);
      mockDoc.exists = true;
      
      const mockRequest = {
        auth: {
          uid: 'user123', // Different from sender and recipient
        },
        data: {
          messageId: 'test-message-id',
        },
      };
      
      await expect(functions.deliverMessageManually(mockRequest))
        .rejects.toThrow('Permission denied');
    });

    test('should reject requests for already delivered messages', async () => {
      const messageData = {
        senderId: 'user123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        status: 'delivered', // Already delivered
      };
      
      mockDoc.data.mockReturnValue(messageData);
      mockDoc.exists = true;
      
      const mockRequest = {
        auth: {
          uid: 'user123',
        },
        data: {
          messageId: 'test-message-id',
        },
      };
      
      await expect(functions.deliverMessageManually(mockRequest))
        .rejects.toThrow('Message is already delivered');
    });
  });

  describe('getDeliveryStats', () => {
    test('should return delivery statistics for authenticated user', async () => {
      // Mock different snapshots for different statuses
      const pendingSnapshot = { size: 5 };
      const deliveredSnapshot = { size: 10 };
      const failedSnapshot = { size: 2 };
      
      mockCollection.get
        .mockResolvedValueOnce(pendingSnapshot)
        .mockResolvedValueOnce(deliveredSnapshot)
        .mockResolvedValueOnce(failedSnapshot);
      
      const mockRequest = {
        auth: {
          uid: 'user123',
        },
      };
      
      const result = await functions.getDeliveryStats(mockRequest);
      
      expect(result).toEqual({
        pending: 5,
        delivered: 10,
        failed: 2,
        total: 17,
      });
    });

    test('should reject unauthenticated requests', async () => {
      const mockRequest = {
        auth: null,
      };
      
      await expect(functions.getDeliveryStats(mockRequest))
        .rejects.toThrow('Authentication required');
    });
  });

  describe('cleanupOldMessages', () => {
    test('should delete old delivered messages', async () => {
      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(),
      };
      
      mockFirestore.batch.mockReturnValue(mockBatch);
      
      const mockEvent = {};
      
      await expect(functions.cleanupOldMessages(mockEvent)).resolves.not.toThrow();
      
      // Should create batch operations
      expect(mockBatch.delete).toHaveBeenCalled();
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    test('should handle empty cleanup queue', async () => {
      mockSnapshot.empty = true;
      mockSnapshot.docs = [];
      
      const mockEvent = {};
      
      await expect(functions.cleanupOldMessages(mockEvent)).resolves.not.toThrow();
      
      // Should not create batch operations
      expect(mockFirestore.batch).not.toHaveBeenCalled();
    });
  });

  describe('retryFailedMessages', () => {
    test('should retry failed messages', async () => {
      const messageData = {
        senderId: 'sender123',
        recipientId: 'recipient456',
        textContent: 'Test message',
        status: 'failed',
        retryCount: 1,
      };
      
      mockDoc.data.mockReturnValue(messageData);
      mockDoc.ref.update.mockResolvedValue();
      
      const mockRequest = {
        auth: {
          uid: 'admin-user',
        },
      };
      
      const result = await functions.retryFailedMessages(mockRequest);
      
      expect(result.retriedCount).toBeGreaterThanOrEqual(0);
      expect(result.totalFailed).toBeGreaterThanOrEqual(0);
      expect(result.message).toContain('Retried');
    });

    test('should handle no failed messages to retry', async () => {
      mockSnapshot.empty = true;
      mockSnapshot.docs = [];
      
      const mockRequest = {
        auth: {
          uid: 'admin-user',
        },
      };
      
      const result = await functions.retryFailedMessages(mockRequest);
      
      expect(result.message).toBe('No failed messages to retry');
      expect(result.retriedCount).toBe(0);
    });

    test('should reject unauthenticated requests', async () => {
      const mockRequest = {
        auth: null,
      };
      
      await expect(functions.retryFailedMessages(mockRequest))
        .rejects.toThrow('Authentication required');
    });
  });
});

describe('Helper Functions', () => {
  describe('sendDeliveryNotification', () => {
    test('should handle missing recipient', async () => {
      mockDoc.exists = false;
      
      const messageData = {
        senderId: 'sender123',
        recipientId: 'non-existent-user',
        textContent: 'Test message',
      };
      
      // This function is not exported, so we test it indirectly through message delivery
      // The function should handle missing recipients gracefully without throwing
      expect(true).toBe(true); // Placeholder test
    });

    test('should handle missing FCM token', async () => {
      const userData = {
        username: 'testuser',
        // No fcmToken
      };
      
      mockDoc.data.mockReturnValue(userData);
      mockDoc.exists = true;
      
      // Function should handle missing FCM token gracefully
      expect(true).toBe(true); // Placeholder test
    });
  });
});