const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc, query, where, getDocs } = require('firebase/firestore');

/**
 * Comprehensive test suite for Firestore security rules
 * 
 * To run these tests:
 * 1. Install dependencies: npm install --save-dev @firebase/rules-unit-testing
 * 2. Start Firebase emulator: firebase emulators:start --only firestore
 * 3. Run tests: npm test
 */

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'time-capsule-test',
    firestore: {
      rules: require('fs').readFileSync('firestore.rules', 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('Friend Request Security Rules', () => {
  test('should allow user to read their own sent friend requests', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'request1');
    
    await assertSucceeds(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'bob',
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
    
    await assertSucceeds(getDoc(friendRequestRef));
  });
  
  test('should allow user to read their own received friend requests', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'request2');
    
    // Alice creates a friend request to Bob
    await assertSucceeds(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'bob',
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
    
    // Bob should be able to read the request sent to him
    await assertSucceeds(getDoc(doc(bob.firestore(), 'friendRequests', 'request2')));
  });
  
  test('should deny reading friend requests not involving the user', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const charlie = testEnv.authenticatedContext('charlie');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'request3');
    
    await assertSucceeds(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'bob',
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
    
    // Charlie should not be able to read Alice's request to Bob
    await assertFails(getDoc(doc(charlie.firestore(), 'friendRequests', 'request3')));
  });
  
  test('should prevent self friend requests', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'selfRequest');
    
    await assertFails(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'alice', // Same as sender
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
  });
  
  test('should allow receiver to accept friend request', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'request4');
    
    // Alice sends friend request to Bob
    await assertSucceeds(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'bob',
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
    
    // Bob accepts the request
    await assertSucceeds(updateDoc(doc(bob.firestore(), 'friendRequests', 'request4'), {
      status: 'accepted',
      respondedAt: new Date(),
    }));
  });
  
  test('should deny sender from accepting their own request', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const friendRequestRef = doc(alice.firestore(), 'friendRequests', 'request5');
    
    await assertSucceeds(setDoc(friendRequestRef, {
      senderId: 'alice',
      receiverId: 'bob',
      senderUsername: 'alice_user',
      status: 'pending',
      createdAt: new Date(),
    }));
    
    // Alice should not be able to accept her own request
    await assertFails(updateDoc(friendRequestRef, {
      status: 'accepted',
      respondedAt: new Date(),
    }));
  });
});

describe('Friendship Security Rules', () => {
  test('should allow users to read their own friendships', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const friendshipRef = doc(alice.firestore(), 'friendships', 'friendship1');
    
    // Simulate system creating friendship (this would normally be done by Cloud Function)
    const admin = testEnv.authenticatedContext('admin', { admin: true });
    await assertSucceeds(setDoc(doc(admin.firestore(), 'friendships', 'friendship1'), {
      userId1: 'alice',
      userId2: 'bob',
      createdAt: new Date(),
    }));
    
    // Alice should be able to read the friendship
    await assertSucceeds(getDoc(friendshipRef));
  });
  
  test('should allow users to delete their own friendships', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const admin = testEnv.authenticatedContext('admin', { admin: true });
    
    // Create friendship
    await assertSucceeds(setDoc(doc(admin.firestore(), 'friendships', 'friendship2'), {
      userId1: 'alice',
      userId2: 'bob',
      createdAt: new Date(),
    }));
    
    // Alice should be able to delete the friendship
    await assertSucceeds(deleteDoc(doc(alice.firestore(), 'friendships', 'friendship2')));
  });
  
  test('should deny users from creating friendships directly', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const friendshipRef = doc(alice.firestore(), 'friendships', 'directFriendship');
    
    await assertFails(setDoc(friendshipRef, {
      userId1: 'alice',
      userId2: 'bob',
      createdAt: new Date(),
    }));
  });
});

describe('Folder Security Rules', () => {
  test('should allow owner to create and access their folders', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const folderRef = doc(alice.firestore(), 'folders', 'aliceFolder');
    
    await assertSucceeds(setDoc(folderRef, {
      name: 'Alice\'s Folder',
      userId: 'alice',
      createdAt: new Date(),
      isShared: false,
      isPublic: false,
      isLocked: false,
      contributorIds: [],
    }));
    
    await assertSucceeds(getDoc(folderRef));
  });
  
  test('should allow contributors to access shared folders', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const folderRef = doc(alice.firestore(), 'folders', 'sharedFolder');
    
    // Alice creates shared folder with Bob as contributor
    await assertSucceeds(setDoc(folderRef, {
      name: 'Shared Folder',
      userId: 'alice',
      createdAt: new Date(),
      isShared: true,
      isPublic: false,
      isLocked: false,
      contributorIds: ['bob'],
    }));
    
    // Bob should be able to read the shared folder
    await assertSucceeds(getDoc(doc(bob.firestore(), 'folders', 'sharedFolder')));
  });
  
  test('should allow anyone to read public folders', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const charlie = testEnv.authenticatedContext('charlie');
    const folderRef = doc(alice.firestore(), 'folders', 'publicFolder');
    
    // Alice creates public folder
    await assertSucceeds(setDoc(folderRef, {
      name: 'Public Folder',
      userId: 'alice',
      createdAt: new Date(),
      isShared: false,
      isPublic: true,
      isLocked: false,
      contributorIds: [],
    }));
    
    // Charlie (not owner or contributor) should be able to read public folder
    await assertSucceeds(getDoc(doc(charlie.firestore(), 'folders', 'publicFolder')));
  });
  
  test('should deny access to private folders for non-owners/contributors', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const charlie = testEnv.authenticatedContext('charlie');
    const folderRef = doc(alice.firestore(), 'folders', 'privateFolder');
    
    // Alice creates private folder
    await assertSucceeds(setDoc(folderRef, {
      name: 'Private Folder',
      userId: 'alice',
      createdAt: new Date(),
      isShared: false,
      isPublic: false,
      isLocked: false,
      contributorIds: [],
    }));
    
    // Charlie should not be able to read Alice's private folder
    await assertFails(getDoc(doc(charlie.firestore(), 'folders', 'privateFolder')));
  });
  
  test('should prevent contributors from modifying locked folders', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const folderRef = doc(alice.firestore(), 'folders', 'lockedFolder');
    
    // Alice creates shared but locked folder
    await assertSucceeds(setDoc(folderRef, {
      name: 'Locked Folder',
      userId: 'alice',
      createdAt: new Date(),
      isShared: true,
      isPublic: false,
      isLocked: true,
      contributorIds: ['bob'],
    }));
    
    // Bob should not be able to modify locked folder
    await assertFails(updateDoc(doc(bob.firestore(), 'folders', 'lockedFolder'), {
      name: 'Modified Name',
    }));
  });
});

describe('Scheduled Message Security Rules', () => {
  test('should allow user to create scheduled message to friend', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'message1');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    
    await assertSucceeds(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: 'Hello future Bob!',
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
  });
  
  test('should allow recipient to read delivered messages', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'message2');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    
    // Alice creates message for Bob
    await assertSucceeds(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: 'Hello Bob!',
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
    
    // Bob should be able to read the message
    await assertSucceeds(getDoc(doc(bob.firestore(), 'scheduledMessages', 'message2')));
  });
  
  test('should deny creating messages scheduled for the past', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'pastMessage');
    
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 1);
    
    await assertFails(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: 'This should fail',
      scheduledFor: pastDate,
      createdAt: new Date(),
      status: 'pending',
    }));
  });
  
  test('should deny messages with empty content', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'emptyMessage');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    
    await assertFails(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: '', // Empty content
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
  });
  
  test('should deny messages exceeding text limit', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'longMessage');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    const longText = 'x'.repeat(5001); // Exceeds 5KB limit
    
    await assertFails(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: longText,
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
  });
  
  test('should allow sender to cancel pending messages', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'cancelMessage');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    
    // Create message
    await assertSucceeds(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: 'This will be cancelled',
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
    
    // Alice should be able to cancel her own message
    await assertSucceeds(updateDoc(messageRef, {
      status: 'cancelled',
    }));
  });
  
  test('should deny non-senders from accessing messages', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const charlie = testEnv.authenticatedContext('charlie');
    const messageRef = doc(alice.firestore(), 'scheduledMessages', 'privateMessage');
    
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    
    // Alice creates message for Bob
    await assertSucceeds(setDoc(messageRef, {
      senderId: 'alice',
      recipientId: 'bob',
      textContent: 'Private message',
      scheduledFor: futureDate,
      createdAt: new Date(),
      status: 'pending',
    }));
    
    // Charlie should not be able to read the message
    await assertFails(getDoc(doc(charlie.firestore(), 'scheduledMessages', 'privateMessage')));
  });
});

describe('User Collection Security Rules', () => {
  test('should allow users to read any user profile for search', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const userRef = doc(alice.firestore(), 'users', 'bob');
    
    // Create Bob's profile
    await assertSucceeds(setDoc(doc(bob.firestore(), 'users', 'bob'), {
      email: 'bob@example.com',
      username: 'bob_user',
      createdAt: new Date(),
    }));
    
    // Alice should be able to read Bob's profile for search
    await assertSucceeds(getDoc(userRef));
  });
  
  test('should only allow users to update their own profile', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    
    // Alice creates her profile
    await assertSucceeds(setDoc(doc(alice.firestore(), 'users', 'alice'), {
      email: 'alice@example.com',
      username: 'alice_user',
      createdAt: new Date(),
    }));
    
    // Alice should be able to update her own profile
    await assertSucceeds(updateDoc(doc(alice.firestore(), 'users', 'alice'), {
      username: 'new_alice_user',
    }));
    
    // Bob should not be able to update Alice's profile
    await assertFails(updateDoc(doc(bob.firestore(), 'users', 'alice'), {
      username: 'hacked_alice',
    }));
  });
  
  test('should validate username format on user creation', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    // Valid username
    await assertSucceeds(setDoc(doc(alice.firestore(), 'users', 'alice'), {
      email: 'alice@example.com',
      username: 'valid_username123',
      createdAt: new Date(),
    }));
    
    // Invalid username (too short)
    await assertFails(setDoc(doc(alice.firestore(), 'users', 'alice2'), {
      email: 'alice2@example.com',
      username: 'ab',
      createdAt: new Date(),
    }));
    
    // Invalid username (contains special characters)
    await assertFails(setDoc(doc(alice.firestore(), 'users', 'alice3'), {
      email: 'alice3@example.com',
      username: 'user@name',
      createdAt: new Date(),
    }));
  });
});