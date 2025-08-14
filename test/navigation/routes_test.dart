import 'package:flutter_test/flutter_test.dart';

import 'package:time_capsule/constants/route_constants.dart';

void main() {
  group('Routes Constants Tests', () {
    test('should have correct social feature route constants', () {
      expect(Routes.friends, equals('/friends'));
      expect(Routes.addFriend, equals('/add-friend'));
      expect(Routes.friendRequests, equals('/friend-requests'));
      expect(Routes.scheduledMessages, equals('/scheduled-messages'));
      expect(Routes.deliveredMessages, equals('/delivered-messages'));
      expect(Routes.publicFolders, equals('/public-folders'));
      expect(Routes.sharedFolderSettings, equals('/shared-folder-settings'));
    });

    test('should have existing route constants', () {
      expect(Routes.login, equals('/'));
      expect(Routes.register, equals('/register'));
      expect(Routes.usernameSetup, equals('/username-setup'));
      expect(Routes.home, equals('/home'));
      expect(Routes.profile, equals('/profile'));
      expect(Routes.editUsername, equals('/edit-username'));
      expect(Routes.changePassword, equals('/change-password'));
    });
  });
}
