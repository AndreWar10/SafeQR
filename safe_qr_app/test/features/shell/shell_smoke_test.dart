import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/core/constants/app_strings.dart';

void main() {
  test('nomes de tabs estão alinhados com o app', () {
    expect(AppStrings.tabReader, isNotEmpty);
    expect(AppStrings.tabGenerator, isNotEmpty);
    expect(AppStrings.tabHistory, isNotEmpty);
  });
}
