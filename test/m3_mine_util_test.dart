import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/storage/teenager_pin_store.dart';
import 'package:vortek/core/utils/string_util.dart';
import 'package:vortek/core/utils/teenager_mode_util.dart';
import 'package:vortek/core/utils/user_bind_util.dart';

void main() {
  group('StringUtil mask', () {
    test('maskPhone 13812345678', () {
      expect(StringUtil.maskPhone('13812345678'), '138****5678');
    });

    test('maskEmail keeps first char and domain', () {
      expect(StringUtil.maskEmail('alice@example.com'), 'a****@example.com');
    });
  });

  group('UserBindUtil', () {
    test('phone validation', () {
      expect(UserBindUtil.isValidPhone('13812345678'), isTrue);
      expect(UserBindUtil.isValidPhone('12345'), isFalse);
    });

    test('email validation', () {
      expect(UserBindUtil.isValidEmail('a@b.co'), isTrue);
      expect(UserBindUtil.isValidEmail('bad'), isFalse);
    });

    test('sms lock seconds', () {
      expect(UserBindUtil.smsCodeLockSeconds, 60);
    });

    test('bindPhone API body', () {
      expect(
        UserBindApiBody.bindPhone(phone: '13812345678', code: '123456'),
        {'phone': '13812345678', 'code': '123456'},
      );
    });
  });

  group('TeenagerModeUtil', () {
    test('storageKey matches uniapp', () {
      expect(TeenagerModeUtil.storageKey(100), 'chats-app-100-teenagerMode');
    });

    test('parseEnabled from KV JSON', () {
      final raw = jsonEncode({'enabled': true});
      expect(TeenagerModeUtil.parseEnabled(raw), isTrue);
      expect(TeenagerModeUtil.parseEnabled(null), isFalse);
    });

    test('blocks addFriend when enabled', () {
      final blocked = <String>[];
      guardTeenagerFeature(
        teenagerModeEnabled: true,
        feature: TeenagerBlockFeature.addFriend,
        onBlocked: blocked.add,
      );
      expect(blocked, ['青少年模式下无法使用添加好友']);
      expect(
        isTeenagerFeatureBlocked(
          teenagerModeEnabled: false,
          feature: TeenagerBlockFeature.rtcCall,
        ),
        isFalse,
      );
    });
  });

  group('TeenagerPinStore hash', () {
    test('same salt same pin; different salt differs; no plaintext', () {
      final a = TeenagerPinStore.hashPin('1234', 'salt-a');
      final b = TeenagerPinStore.hashPin('1234', 'salt-a');
      final c = TeenagerPinStore.hashPin('1234', 'salt-b');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.contains('1234'), isFalse);
    });
  });
}