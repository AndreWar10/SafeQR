import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../qr_generator/presentation/pages/qr_generator_page.dart';
import '../../../qr_history/presentation/pages/qr_history_page.dart';
import '../../../qr_history/presentation/view_models/qr_history_view_model.dart';
import '../../../qr_scanner/presentation/pages/qr_reader_page.dart';
import '../../../../shared/presentation/widgets/theme_cycle_action.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        actions: const <Widget>[ThemeCycleAction()],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          QrReaderPage(),
          QrGeneratorPage(),
          QrHistoryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) {
          setState(() => _index = i);
          if (i == 2) {
            context.read<QrHistoryViewModel>().load();
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: AppStrings.tabReader,
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: AppStrings.tabGenerator,
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: AppStrings.tabHistory,
          ),
        ],
      ),
    );
  }
}
