import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/qr_security_verdict.dart';

String verdictToLabel(QrSecurityVerdict v) {
  return switch (v) {
    QrSecurityVerdict.safe => AppStrings.safeLabel,
    QrSecurityVerdict.suspicious => AppStrings.suspiciousLabel,
    QrSecurityVerdict.unsafe => AppStrings.unsafeLabel,
    QrSecurityVerdict.unknown => AppStrings.unknownLabel,
  };
}
