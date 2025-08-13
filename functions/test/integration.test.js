/**
 * Integration tests for Cloud Functions deployment and basic functionality
 */

const functions = require('../index');

describe('Cloud Functions Integration', () => {
  test('should export all required functions', () => {
    expect(functions.processScheduledMessages).toBeDefined();
    expect(functions.onScheduledMessageCreated).toBeDefined();
    expect(functions.deliverMessageManually).toBeDefined();
    expect(functions.getDeliveryStats).toBeDefined();
    expect(functions.cleanupOldMessages).toBeDefined();
    expect(functions.retryFailedMessages).toBeDefined();
  });

  test('should have correct function types', () => {
    expect(typeof functions.processScheduledMessages).toBe('function');
    expect(typeof functions.onScheduledMessageCreated).toBe('function');
    expect(typeof functions.deliverMessageManually).toBe('function');
    expect(typeof functions.getDeliveryStats).toBe('function');
    expect(typeof functions.cleanupOldMessages).toBe('function');
    expect(typeof functions.retryFailedMessages).toBe('function');
  });

  test('should validate function configurations', () => {
    // These are Firebase Functions v2 objects, so we check they are callable
    expect(functions.processScheduledMessages).toBeInstanceOf(Function);
    expect(functions.onScheduledMessageCreated).toBeInstanceOf(Function);
    expect(functions.deliverMessageManually).toBeInstanceOf(Function);
    expect(functions.getDeliveryStats).toBeInstanceOf(Function);
    expect(functions.cleanupOldMessages).toBeInstanceOf(Function);
    expect(functions.retryFailedMessages).toBeInstanceOf(Function);
  });
});