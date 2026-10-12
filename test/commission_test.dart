import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/constants/commission.dart';

void main() {
  group('DesignerCommission.applicationFeeCents', () {
    test('20 % standard sur HT (TVA 20 %)', () {
      // 12,00 EUR TTC = 1200 cents → HT = round(1200/1.2)=1000 → 20% = 200
      expect(
        DesignerCommission.applicationFeeCents(1200, commissionPercent: 20),
        200,
      );
    });

    test('10 % founding sur HT', () {
      // 12,00 EUR TTC → HT 1000 → 10% = 100
      expect(
        DesignerCommission.applicationFeeCents(1200, commissionPercent: 10),
        100,
      );
    });

    test('prix catalogue typique 13 EUR', () {
      // 1300 / 1.2 = 1083.333 → 1083 ; 20% → 217
      expect(
        DesignerCommission.applicationFeeCents(1300, commissionPercent: 20),
        217,
      );
      // founding
      expect(
        DesignerCommission.applicationFeeCents(1300, commissionPercent: 10),
        108,
      );
    });
  });
}
