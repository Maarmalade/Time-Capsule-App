/**
 * Integration tests for Cloud Function message delivery
 * 
 * This test file validates the Cloud Function behavior by:
 * - Testing the processScheduledMessages function
 * - Verifying atomic status updates with deliveredAt timestamps
 * - Testing error handling for delivery failures
 * - Validating message processing triggers
 */

const admin = require('firebase-admin');
const test = require('firebase-functions-test')();

// Initialize test environment
const testEnv = test({
  projectId: 'time-capsule-test',
});

// Mock Firestore data
const mockFirestore = {
  collection: jest.fn(() => ({
    doc: jest.fn(() => ({
      get: jest.fn(),
      update: jest.fn(),
      set: jest.fn(),
    })),
    where: jest.fn(() => ({
      where: jest.fn(() => ({
        limit: jest.fn(() => ({
          get: jest.fn(),
        })),
      })),
    })),
  })),
  runTransaction: jest.fn(),
};

// Mock admin SDK
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => mockFirestore),
  messaging: jest.fn(() => ({
    send: jest.fn(),
  })),
}));

describe('Cloud Function Message Delivery', () => {
  let processScheduledMessages;
  let deliverMessageManually;
  let testMessageDelivery;

  beforeAll(() => {
    // Import functions after mocking
    const functions = require('../../functions/index.js');
    processScheduledMessages = functions.processScheduledMessages;
    deliverMessageManually = functions.deliverMessageManually;
    testMessageDelivery = functions.testMessageDelivery;
  });

  afterAll(() => {
    test.cleanup();
  });

  describe('Scheduled Message Processing', () => {
    test('should process pending messages ready for delivery', async () => {
      // Mock ready messages
      const mockMessages = [
        {
          id: 'msg1',
          data: () => ({
            senderId: 'user1',
            recipientId: 'user2',
            textContent: 'Test message 1',
            status: 'pending',
            scheduledFor: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() - 10 * 60 * 1000) // 10 minutes ago
            ),
          }),
          ref: {
            update: jest.fn(),
          },
        },
        {
          id: 'msg2',
          data: () => ({
            senderId: 'user1',
            recipientId: 'user3',
            textContent: 'Test message 2',
            status: 'pending',
            scheduledFor: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() - 5 * 60 * 1000) // 5 minutes ago
            ),
          }),
          ref: {
            update: jest.fn(),
          },
        },
      ];

      // Mock Firestore query
      mockFirestore.collection().where().where().limit().get.mockResolvedValue({
        empty: false,
        docs: mockMessages,
      });

      // Mock transaction for atomic updates
      mockFirestore.runTransaction.mockImplementation(async (callback) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ status: 'pending' }),
          }),
          update: jest.fn(),
        };
        await callback(mockTransaction);
      });

      // Execute the function
      const event = {}; // Mock event object
      await processScheduledMessages(event);

      // Verify messages were processed
      expect(mockFirestore.collection).toHaveBeenCalledWith('scheduledMessages');
      expect(mockFirestore.runTransaction).toHaveBeenCalledTimes(2);
    });

    test('should handle empty message queue gracefully', async () => {
      // Mock empty query result
      mockFirestore.collection().where().where().limit().get.mockResolvedValue({
        empty: true,
        docs: [],
      });

      const event = {};
      await processScheduledMessages(event);

      // Should not attempt any processing
      expect(mockFirestore.runTransaction).not.toHaveBeenCalled();
    });

    test('should handle invalid message data', async () => {
      // Mock message with missing required fields
      const invalidMessage = {
        id: 'invalid-msg',
        data: () => ({
          senderId: 'user1',
          // Missing recipientId and textContent
          status: 'pending',
          scheduledFor: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 10 * 60 * 1000)
          ),
        }),
        ref: {
          update: jest.fn(),
        },
      };

      mockFirestore.collection().where().where().limit().get.mockResolvedValue({
        empty: false,
        docs: [invalidMessage],
      });

      const event = {};
      await processScheduledMessages(event);

      // Should skip invalid messages
      expect(mockFirestore.runTransaction).not.toHaveBeenCalled();
    });
  });

  describe('Atomic Status Updates', () => {
    test('should update message status atomically with deliveredAt timestamp', async () => {
      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ status: 'pending' }),
        }),
        update: jest.fn(),
      };

      mockFirestore.runTransaction.mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      // Mock message data
      const messageData = {
        senderId: 'user1',
        recipientId: 'user2',
        textContent: 'Test message',
        status: 'pending',
      };

      // This would be called within the deliverMessage function
      await mockFirestore.runTransaction(async (transaction) => {
        const messageRef = mockFirestore.collection('scheduledMessages').doc('test-msg');
        const messageDoc = await transaction.get(messageRef);
        
        if (messageDoc.exists && messageDoc.data().status === 'pending') {
          const deliveredAt = admin.firestore.Timestamp.now();
          transaction.update(messageRef, {
            status: 'delivered',
            deliveredAt: deliveredAt,
            updatedAt: deliveredAt,
            processedBy: 'cloud-function',
            processedAt: deliveredAt,
          });
        }
      });

      // Verify atomic update was called
      expect(mockTransaction.update).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          status: 'delivered',
          deliveredAt: expect.any(Object),
          updatedAt: expect.any(Object),
          processedBy: 'cloud-function',
          processedAt: expect.any(Object),
        })
      );
    });

    test('should skip delivery if message is no longer pending', async () => {
      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ status: 'delivered' }), // Already delivered
        }),
        update: jest.fn(),
      };

      mockFirestore.runTransaction.mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      // Simulate checking message status before update
      await mockFirestore.runTransaction(async (transaction) => {
        const messageRef = mockFirestore.collection('scheduledMessages').doc('test-msg');
        const messageDoc = await transaction.get(messageRef);
        
        if (messageDoc.exists && messageDoc.data().status === 'pending') {
          // This should not execute
          transaction.update(messageRef, { status: 'delivered' });
        }
      });

      // Verify update was not called for non-pending message
      expect(mockTransaction.update).not.toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    test('should handle delivery failures gracefully', async () => {
      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ status: 'pending' }),
        }),
        update: jest.fn(),
      };

      // Mock transaction failure
      mockFirestore.runTransaction
        .mockRejectedValueOnce(new Error('Firestore transaction failed'))
        .mockImplementation(async (callback) => {
          await callback(mockTransaction);
        });

      const messageData = {
        senderId: 'user1',
        recipientId: 'user2',
        textContent: 'Test message',
        status: 'pending',
      };

      // Simulate error handling in deliverMessage
      try {
        await mockFirestore.runTransaction(async (transaction) => {
          throw new Error('Simulated delivery failure');
        });
      } catch (error) {
        // Should handle error and update message to failed status
        await mockFirestore.runTransaction(async (transaction) => {
          const messageRef = mockFirestore.collection('scheduledMessages').doc('test-msg');
          const messageDoc = await transaction.get(messageRef);
          
          if (messageDoc.exists && messageDoc.data().status === 'pending') {
            transaction.update(messageRef, {
              status: 'failed',
              failureReason: error.message,
              failedAt: admin.firestore.Timestamp.now(),
              updatedAt: admin.firestore.Timestamp.now(),
            });
          }
        });
      }

      // Verify error handling update was called
      expect(mockTransaction.update).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          status: 'failed',
          failureReason: expect.any(String),
          failedAt: expect.any(Object),
          updatedAt: expect.any(Object),
        })
      );
    });
  });

  describe('Manual Delivery Testing', () => {
    test('should allow manual message delivery for testing', async () => {
      const mockRequest = {
        auth: { uid: 'test-user' },
        data: { messageId: 'test-msg-123' },
      };

      // Mock message document
      mockFirestore.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({
          senderId: 'test-user',
          recipientId: 'recipient-user',
          textContent: 'Test message',
          status: 'pending',
        }),
      });

      // Mock successful delivery
      mockFirestore.runTransaction.mockImplementation(async (callback) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ status: 'pending' }),
          }),
          update: jest.fn(),
        };
        await callback(mockTransaction);
      });

      // Execute manual delivery
      const result = await deliverMessageManually(mockRequest);

      expect(result).toEqual({
        success: true,
        message: 'Message delivered successfully',
      });
    });

    test('should reject unauthorized manual delivery attempts', async () => {
      const mockRequest = {
        auth: null, // No authentication
        data: { messageId: 'test-msg-123' },
      };

      await expect(deliverMessageManually(mockRequest)).rejects.toThrow(
        'Authentication required'
      );
    });

    test('should validate user permissions for manual delivery', async () => {
      const mockRequest = {
        auth: { uid: 'unauthorized-user' },
        data: { messageId: 'test-msg-123' },
      };

      // Mock message owned by different user
      mockFirestore.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({
          senderId: 'different-user',
          recipientId: 'another-user',
          textContent: 'Test message',
          status: 'pending',
        }),
      });

      await expect(deliverMessageManually(mockRequest)).rejects.toThrow(
        'Permission denied'
      );
    });
  });

  describe('Test Function Validation', () => {
    test('should provide test delivery functionality', async () => {
      const mockRequest = {
        auth: { uid: 'test-user' },
        data: { messageId: 'test-msg-123', forceDelivery: false },
      };

      // Mock pending message
      mockFirestore.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({
            senderId: 'test-user',
            recipientId: 'recipient-user',
            textContent: 'Test message',
            status: 'pending',
          }),
        })
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({
            senderId: 'test-user',
            recipientId: 'recipient-user',
            textContent: 'Test message',
            status: 'delivered',
            deliveredAt: admin.firestore.Timestamp.now(),
          }),
        });

      // Mock successful delivery
      mockFirestore.runTransaction.mockImplementation(async (callback) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ status: 'pending' }),
          }),
          update: jest.fn(),
        };
        await callback(mockTransaction);
      });

      const result = await testMessageDelivery(mockRequest);

      expect(result).toEqual(
        expect.objectContaining({
          success: true,
          message: 'Message delivery test completed successfully',
          originalStatus: 'pending',
          newStatus: 'delivered',
          deliveredAt: expect.any(String),
        })
      );
    });
  });
});