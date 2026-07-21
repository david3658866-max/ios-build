import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/public_net_probe.dart';

void main() {
  group('PublicNetProbe.isDomesticEligible', () {
    test('explicit foreign dial code is skipped', () {
      expect(
        PublicNetProbe.isDomesticEligible(loginPhone: '+1 2025550100'),
        isFalse,
      );
      expect(
        PublicNetProbe.isDomesticEligible(loginPhone: '0044123456789'),
        isFalse,
      );
    });

    test('+86 phone is eligible when timezone is UTC+8', () {
      // This workspace/CI is typically UTC+8; if not, skip assertion on true.
      final eligible = PublicNetProbe.isDomesticEligible(loginPhone: '+8613800138000');
      final isPlus8 = DateTime.now().timeZoneOffset.inHours == 8;
      expect(eligible, isPlus8);
    });
  });
}
