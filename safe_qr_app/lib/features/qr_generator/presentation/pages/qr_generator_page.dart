import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../domain/qr_generation_type.dart';
import '../../../../shared/presentation/widgets/app_hero_header.dart';
import '../../../../shared/presentation/widgets/app_rounded_action_button.dart';
import '../view_models/qr_generator_view_model.dart';
import '../../../../shared/presentation/widgets/safe_qr_loading_overlay.dart';
import 'qr_generator_result_page.dart';

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  bool _generateBusy = false;

  final TextEditingController _draft = TextEditingController();
  final TextEditingController _wifiSsid = TextEditingController();
  final TextEditingController _wifiPass = TextEditingController();
  final TextEditingController _emailSubject = TextEditingController();
  final TextEditingController _emailBody = TextEditingController();
  final TextEditingController _smsMessage = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    _wifiSsid.dispose();
    _wifiPass.dispose();
    _emailSubject.dispose();
    _emailBody.dispose();
    _smsMessage.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    if (_generateBusy) {
      return;
    }
    final QrGeneratorViewModel vm = context.read<QrGeneratorViewModel>();
    vm.setDraft(_draft.text);
    vm.setWifiSsid(_wifiSsid.text);
    vm.setWifiPassword(_wifiPass.text);
    vm.setEmailSubject(_emailSubject.text);
    vm.setEmailBody(_emailBody.text);
    vm.setSmsText(_smsMessage.text);
    vm.generateQr();
    if (!mounted) {
      return;
    }
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
      return;
    }
    setState(() {
      _generateBusy = true;
    });
    try {
      final String payload = vm.generatedPayload!;
      final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          barrierColor: const Color(0xB3000000),
          builder: (BuildContext dialogContext) {
            return const Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 32),
              child: SafeQrLoadingOverlay(
                title: AppStrings.generatorLoadingTitle,
                subtitle: AppStrings.generatorLoadingSubtitle,
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (rootNav.canPop()) {
        rootNav.pop();
      }
      if (!mounted) {
        return;
      }
      final bool historyOk = await vm.saveToHistory();
      if (!mounted) {
        return;
      }
      if (!historyOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? AppStrings.generatorHistorySaveFailed),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => QrGeneratorResultPage(payload: payload),
        ),
      );
      if (!mounted) {
        return;
      }
      vm.clearGenerated();
    } finally {
      if (mounted) {
        setState(() {
          _generateBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: ListView(
        children: <Widget>[
          const AppHeroHeader(
            title: AppStrings.generatorTitle,
            subtitle: AppStrings.generatorHeroSubtitle,
          ),
          const SizedBox(height: 16),
          Consumer<QrGeneratorViewModel>(
            builder: (BuildContext context, QrGeneratorViewModel vm, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TypeDropdown(
                    value: vm.type,
                    onChanged: (QrGenerationType? v) {
                      if (v != null) {
                        vm.setType(v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  if (vm.type == QrGenerationType.wifi) ...<Widget>[
                    TextField(
                      controller: _wifiSsid,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorWifiSsid,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _wifiPass,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorWifiPassword,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WifiSecurityField(
                      value: vm.wifiSecurity,
                      onChanged: (String v) => vm.setWifiSecurity(v),
                    ),
                  ] else if (vm.type == QrGenerationType.email) ...<Widget>[
                    TextField(
                      controller: _draft,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorEmailTo,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailSubject,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorEmailSubject,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailBody,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorEmailBody,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ] else if (vm.type == QrGenerationType.sms) ...<Widget>[
                    TextField(
                      controller: _draft,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorSmsNumber,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _smsMessage,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: AppStrings.generatorSmsMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ] else ...<Widget>[
                    TextField(
                      controller: _draft,
                      minLines: _singleLineType(vm.type) ? 1 : 2,
                      maxLines: _singleLineType(vm.type) ? 1 : 6,
                      keyboardType: _keyboardForType(vm.type),
                      decoration: InputDecoration(
                        labelText: _fieldLabelForType(vm.type),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AppRoundedActionButton(
            onPressed: _generateBusy ? null : _onGenerate,
            label: AppStrings.generatorBtnGenerate,
            leading: const Icon(Icons.qr_code_2, size: 18),
          ),
        ],
      ),
    );
  }
}

bool _singleLineType(QrGenerationType t) {
  return t == QrGenerationType.url || t == QrGenerationType.imageUrl || t == QrGenerationType.phone;
}

String _fieldLabelForType(QrGenerationType t) {
  return switch (t) {
    QrGenerationType.plainText => AppStrings.generatorFieldPlain,
    QrGenerationType.url => AppStrings.generatorFieldUrl,
    QrGenerationType.imageUrl => AppStrings.generatorFieldImageUrl,
    QrGenerationType.phone => AppStrings.generatorFieldPhone,
    _ => AppStrings.generatorFieldPlain,
  };
}

TextInputType _keyboardForType(QrGenerationType t) {
  if (t == QrGenerationType.phone) {
    return TextInputType.phone;
  }
  if (t == QrGenerationType.url || t == QrGenerationType.imageUrl) {
    return TextInputType.url;
  }
  return TextInputType.multiline;
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});
  final QrGenerationType value;
  final ValueChanged<QrGenerationType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.generatorTypeLabel,
          style: GoogleFonts.plusJakartaSans(
            color: context.safeColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<QrGenerationType>(
                isExpanded: true,
                value: value,
                borderRadius: BorderRadius.circular(12),
                items: <DropdownMenuItem<QrGenerationType>>[
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.plainText,
                    child: Text(AppStrings.generatorTypePlain),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.url,
                    child: Text(AppStrings.generatorTypeUrl),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.imageUrl,
                    child: Text(AppStrings.generatorTypeImage),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.wifi,
                    child: Text(AppStrings.generatorTypeWifi),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.email,
                    child: Text(AppStrings.generatorTypeEmail),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.phone,
                    child: Text(AppStrings.generatorTypePhone),
                  ),
                  const DropdownMenuItem<QrGenerationType>(
                    value: QrGenerationType.sms,
                    child: Text(AppStrings.generatorTypeSms),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WifiSecurityField extends StatelessWidget {
  const _WifiSecurityField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final String normalized = _norm(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.generatorWifiSecurity,
          style: GoogleFonts.plusJakartaSans(
            color: context.safeColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: normalized,
                borderRadius: BorderRadius.circular(12),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(value: 'WEP', child: Text(AppStrings.generatorWifiWep)),
                  const DropdownMenuItem<String>(value: 'WPA', child: Text(AppStrings.generatorWifiWpa)),
                  const DropdownMenuItem<String>(value: 'NOPASS', child: Text(AppStrings.generatorWifiOpen)),
                ],
                onChanged: (String? v) {
                  if (v != null) {
                    onChanged(v);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _norm(String s) {
    final u = s.toUpperCase();
    if (u == 'WEP' || u == 'WPA' || u == 'WPA2' || u == 'NOPASS') {
      if (u == 'WPA2') {
        return 'WPA';
      }
      return u;
    }
    return 'WPA';
  }
}
