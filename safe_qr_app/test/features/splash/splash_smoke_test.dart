import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/core/constants/app_strings.dart';

void main() {
  test('splash expõe cópia curta (marca e tagline)', () {
    expect(AppStrings.appName, isNotEmpty);
    expect(AppStrings.splashTagline, isNotEmpty);
  });
}
