import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/models/shared_folder_data.dart';

void main() {
  group('SharedFolderData', () {
    late DateTime testDate;
    late SharedFolderData testSharedFolderData;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testSharedFolderData = SharedFolderData(
        contributorIds: ['contributor-1', 'contributor-2'],
        ownerId: 'owner-id',
        isLocked: false,
        isPublic: false,
      );
    });

    group('constructor', () {
      test('should create SharedFolderData with all fields', () {
        final data = SharedFolderData(
          contributorIds: ['contributor-1', 'contributor-2'],
          ownerId: 'owner-id',
          isLocked: true,
          lockedAt: testDate,
          isPublic: true,
        );

        expect(data.contributorIds, equals(['contributor-1', 'contributor-2']));
        expect(data.ownerId, equals('owner-id'));
        expect(data.isLocked, isTrue);
        expect(data.lockedAt, equals(testDate));
        expect(data.isPublic, isTrue);
      });

      test('should create SharedFolderData with default values', () {
        final data = SharedFolderData(
          contributorIds: ['contributor-1'],
          ownerId: 'owner-id',
        );

        expect(data.isLocked, isFalse);
        expect(data.lockedAt, isNull);
        expect(data.isPublic, isFalse);
      });
    });

    group('fromMap', () {
      test('should create SharedFolderData from Map', () {
        final map = {
          'contributorIds': ['contributor-1', 'contributor-2'],
          'ownerId': 'owner-id',
          'isLocked': true,
          'lockedAt': Timestamp.fromDate(testDate),
          'isPublic': true,
        };

        final data = SharedFolderData.fromMap(map);

        expect(data.contributorIds, equals(['contributor-1', 'contributor-2']));
        expect(data.ownerId, equals('owner-id'));
        expect(data.isLocked, isTrue);
        expect(data.lockedAt, equals(testDate));
        expect(data.isPublic, isTrue);
      });

      test('should handle missing fields with defaults', () {
        final map = {
          'ownerId': 'owner-id',
        };

        final data = SharedFolderData.fromMap(map);

        expect(data.contributorIds, isEmpty);
        expect(data.ownerId, equals('owner-id'));
        expect(data.isLocked, isFalse);
        expect(data.lockedAt, isNull);
        expect(data.isPublic, isFalse);
      });

      test('should handle null contributorIds', () {
        final map = {
          'contributorIds': null,
          'ownerId': 'owner-id',
        };

        final data = SharedFolderData.fromMap(map);

        expect(data.contributorIds, isEmpty);
      });
    });

    group('toMap', () {
      test('should convert SharedFolderData to Map', () {
        final data = SharedFolderData(
          contributorIds: ['contributor-1', 'contributor-2'],
          ownerId: 'owner-id',
          isLocked: true,
          lockedAt: testDate,
          isPublic: true,
        );

        final map = data.toMap();

        expect(map['contributorIds'], equals(['contributor-1', 'contributor-2']));
        expect(map['ownerId'], equals('owner-id'));
        expect(map['isLocked'], isTrue);
        expect(map['lockedAt'], isA<Timestamp>());
        expect(map['isPublic'], isTrue);
        expect((map['lockedAt'] as Timestamp).toDate(), equals(testDate));
      });

      test('should handle null lockedAt', () {
        final map = testSharedFolderData.toMap();

        expect(map['lockedAt'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedData = testSharedFolderData.copyWith(
          isLocked: true,
          lockedAt: testDate,
          isPublic: true,
        );

        expect(updatedData.contributorIds, equals(testSharedFolderData.contributorIds));
        expect(updatedData.ownerId, equals(testSharedFolderData.ownerId));
        expect(updatedData.isLocked, isTrue);
        expect(updatedData.lockedAt, equals(testDate));
        expect(updatedData.isPublic, isTrue);
      });

      test('should create copy with updated contributor list', () {
        final newContributors = ['new-contributor-1', 'new-contributor-2'];
        final updatedData = testSharedFolderData.copyWith(
          contributorIds: newContributors,
        );

        expect(updatedData.contributorIds, equals(newContributors));
        expect(updatedData.ownerId, equals(testSharedFolderData.ownerId));
      });

      test('should create identical copy when no parameters provided', () {
        final copiedData = testSharedFolderData.copyWith();

        expect(copiedData.contributorIds, equals(testSharedFolderData.contributorIds));
        expect(copiedData.ownerId, equals(testSharedFolderData.ownerId));
        expect(copiedData.isLocked, equals(testSharedFolderData.isLocked));
        expect(copiedData.isPublic, equals(testSharedFolderData.isPublic));
      });

      test('should create independent copy of contributor list', () {
        final originalContributors = ['contributor-1'];
        final data = SharedFolderData(
          contributorIds: originalContributors,
          ownerId: 'owner-id',
        );

        final copiedData = data.copyWith();
        // Test that the lists are independent by checking they're different objects
        expect(identical(data.contributorIds, copiedData.contributorIds), isFalse);
        expect(data.contributorIds, equals(copiedData.contributorIds));
      });
    });

    group('contributor management methods', () {
      test('hasContributor should return true when user is contributor', () {
        expect(testSharedFolderData.hasContributor('contributor-1'), isTrue);
        expect(testSharedFolderData.hasContributor('contributor-2'), isTrue);
      });

      test('hasContributor should return false when user is not contributor', () {
        expect(testSharedFolderData.hasContributor('non-contributor'), isFalse);
      });

      test('isOwner should return true when user is owner', () {
        expect(testSharedFolderData.isOwner('owner-id'), isTrue);
      });

      test('isOwner should return false when user is not owner', () {
        expect(testSharedFolderData.isOwner('contributor-1'), isFalse);
      });

      test('canContribute should return true for owner when not locked', () {
        expect(testSharedFolderData.canContribute('owner-id'), isTrue);
      });

      test('canContribute should return true for contributor when not locked', () {
        expect(testSharedFolderData.canContribute('contributor-1'), isTrue);
      });

      test('canContribute should return false when locked', () {
        final lockedData = testSharedFolderData.copyWith(isLocked: true);
        expect(lockedData.canContribute('owner-id'), isFalse);
        expect(lockedData.canContribute('contributor-1'), isFalse);
      });

      test('canContribute should return false for non-contributor', () {
        expect(testSharedFolderData.canContribute('non-contributor'), isFalse);
      });

      test('canView should return true for owner', () {
        expect(testSharedFolderData.canView('owner-id'), isTrue);
      });

      test('canView should return true for contributor', () {
        expect(testSharedFolderData.canView('contributor-1'), isTrue);
      });

      test('canView should return true for anyone when public', () {
        final publicData = testSharedFolderData.copyWith(isPublic: true);
        expect(publicData.canView('random-user'), isTrue);
      });

      test('canView should return false for non-contributor when private', () {
        expect(testSharedFolderData.canView('random-user'), isFalse);
      });

      test('canManage should return true for owner only', () {
        expect(testSharedFolderData.canManage('owner-id'), isTrue);
        expect(testSharedFolderData.canManage('contributor-1'), isFalse);
        expect(testSharedFolderData.canManage('random-user'), isFalse);
      });
    });

    group('contributor modification methods', () {
      test('addContributor should add new contributor', () {
        final updatedData = testSharedFolderData.addContributor('new-contributor');

        expect(updatedData.contributorIds, contains('new-contributor'));
        expect(updatedData.contributorIds.length, equals(3));
      });

      test('addContributor should not add existing contributor', () {
        final updatedData = testSharedFolderData.addContributor('contributor-1');

        expect(updatedData.contributorIds.length, equals(2));
        expect(updatedData.contributorIds, equals(testSharedFolderData.contributorIds));
      });

      test('addContributor should not add owner as contributor', () {
        final updatedData = testSharedFolderData.addContributor('owner-id');

        expect(updatedData.contributorIds, equals(testSharedFolderData.contributorIds));
      });

      test('removeContributor should remove existing contributor', () {
        final updatedData = testSharedFolderData.removeContributor('contributor-1');

        expect(updatedData.contributorIds, isNot(contains('contributor-1')));
        expect(updatedData.contributorIds.length, equals(1));
        expect(updatedData.contributorIds, contains('contributor-2'));
      });

      test('removeContributor should not change list when contributor not found', () {
        final updatedData = testSharedFolderData.removeContributor('non-contributor');

        expect(updatedData.contributorIds, equals(testSharedFolderData.contributorIds));
      });
    });

    group('lock/unlock methods', () {
      test('lock should set isLocked to true and set lockedAt', () {
        final lockedData = testSharedFolderData.lock();

        expect(lockedData.isLocked, isTrue);
        expect(lockedData.lockedAt, isNotNull);
        expect(lockedData.lockedAt!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('unlock should set isLocked to false and clear lockedAt', () {
        final lockedData = testSharedFolderData.copyWith(
          isLocked: true,
          lockedAt: DateTime.now(),
        );
        final unlockedData = lockedData.unlock();

        expect(unlockedData.isLocked, isFalse);
        expect(unlockedData.lockedAt, isNull);
      });
    });

    group('public/private methods', () {
      test('makePublic should set isPublic to true', () {
        final publicData = testSharedFolderData.makePublic();

        expect(publicData.isPublic, isTrue);
      });

      test('makePrivate should set isPublic to false', () {
        final publicData = testSharedFolderData.makePublic();
        final privateData = publicData.makePrivate();

        expect(privateData.isPublic, isFalse);
      });
    });

    group('validation methods', () {
      test('isValid should return true for valid data', () {
        expect(testSharedFolderData.isValid(), isTrue);
      });

      test('isValid should return false for empty ownerId', () {
        final data = testSharedFolderData.copyWith(ownerId: '');
        expect(data.isValid(), isFalse);
      });

      test('isValid should return false when owner is in contributors list', () {
        final data = SharedFolderData(
          contributorIds: ['owner-id', 'contributor-1'],
          ownerId: 'owner-id',
        );
        expect(data.isValid(), isFalse);
      });

      test('totalContributors should include owner plus contributors', () {
        expect(testSharedFolderData.totalContributors, equals(3)); // 2 contributors + 1 owner
      });

      test('totalContributors should be 1 when no contributors', () {
        final data = SharedFolderData(
          contributorIds: [],
          ownerId: 'owner-id',
        );
        expect(data.totalContributors, equals(1));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final data1 = SharedFolderData(
          contributorIds: ['contributor-1', 'contributor-2'],
          ownerId: 'owner-id',
          isLocked: false,
          isPublic: false,
        );

        final data2 = SharedFolderData(
          contributorIds: ['contributor-1', 'contributor-2'],
          ownerId: 'owner-id',
          isLocked: false,
          isPublic: false,
        );

        expect(data1, equals(data2));
        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final data1 = testSharedFolderData;
        final data2 = testSharedFolderData.copyWith(isLocked: true);

        expect(data1, isNot(equals(data2)));
      });

      test('should not be equal when contributor lists differ', () {
        final data1 = testSharedFolderData;
        final data2 = testSharedFolderData.copyWith(
          contributorIds: ['different-contributor'],
        );

        expect(data1, isNot(equals(data2)));
      });

      test('should be equal to itself', () {
        expect(testSharedFolderData, equals(testSharedFolderData));
      });

      test('should not be equal to null', () {
        expect(testSharedFolderData, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        expect(testSharedFolderData, isNot(equals('string')));
      });
    });

    group('toString', () {
      test('should return string representation of SharedFolderData', () {
        final stringRepresentation = testSharedFolderData.toString();

        expect(stringRepresentation, contains('SharedFolderData'));
        expect(stringRepresentation, contains('owner-id'));
        expect(stringRepresentation, contains('contributor-1'));
        expect(stringRepresentation, contains('contributor-2'));
        expect(stringRepresentation, contains('false')); // isLocked and isPublic
      });
    });

    group('edge cases', () {
      test('should handle empty contributor list', () {
        final data = SharedFolderData(
          contributorIds: [],
          ownerId: 'owner-id',
        );

        expect(data.contributorIds, isEmpty);
        expect(data.totalContributors, equals(1));
        expect(data.hasContributor('anyone'), isFalse);
      });

      test('should handle very long contributor lists', () {
        final longList = List.generate(1000, (index) => 'contributor-$index');
        final data = SharedFolderData(
          contributorIds: longList,
          ownerId: 'owner-id',
        );

        expect(data.contributorIds.length, equals(1000));
        expect(data.totalContributors, equals(1001));
        expect(data.hasContributor('contributor-500'), isTrue);
      });

      test('should handle special characters in IDs', () {
        final data = SharedFolderData(
          contributorIds: ['contributor-with-special-chars'],
          ownerId: 'owner-id-with-special-chars',
        );

        expect(data.ownerId, equals('owner-id-with-special-chars'));
        expect(data.hasContributor('contributor-with-special-chars'), isTrue);
      });

      test('should handle duplicate contributors in list', () {
        final data = SharedFolderData(
          contributorIds: ['contributor-1', 'contributor-1', 'contributor-2'],
          ownerId: 'owner-id',
        );

        // The model should handle duplicates gracefully
        expect(data.contributorIds.length, equals(3));
        expect(data.hasContributor('contributor-1'), isTrue);
      });
    });
  });
}