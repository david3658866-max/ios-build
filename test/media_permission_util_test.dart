import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:vortek/core/utils/media_permission_util.dart';

void main() {
  group('MediaPermissionUtil.isGrantedStatus', () {
    test('granted and limited are treated as authorized', () {
      expect(MediaPermissionUtil.isGrantedStatus(PermissionStatus.granted), isTrue);
      expect(MediaPermissionUtil.isGrantedStatus(PermissionStatus.limited), isTrue);
      expect(MediaPermissionUtil.isGrantedStatus(PermissionStatus.denied), isFalse);
      expect(
        MediaPermissionUtil.isGrantedStatus(PermissionStatus.permanentlyDenied),
        isFalse,
      );
    });
  });
}
