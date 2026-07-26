import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/device_id_util.dart';

void main() {
  group('DeviceIdUtil.isUsableAndroidRawId', () {
    test('accepts normal ANDROID_ID', () {
      expect(DeviceIdUtil.isUsableAndroidRawId('891657111e970686'), isTrue);
      expect(DeviceIdUtil.isUsableAndroidRawId('a1b2c3d4e5f67890'), isTrue);
    });

    test('accepts appgen uuid', () {
      expect(
        DeviceIdUtil.isUsableAndroidRawId(
          'appgen:a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        ),
        isTrue,
      );
    });

    test('rejects bad values', () {
      expect(DeviceIdUtil.isUsableAndroidRawId(''), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('unknown'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('0000000000000000'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('ffffffffffffffff'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('9774d56d682e549c'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('UP1A.231005.007'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('appgen:not-a-uuid'), isFalse);
      expect(DeviceIdUtil.isUsableAndroidRawId('aaaaaaaa'), isFalse);
    });
  });
}
