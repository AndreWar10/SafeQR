import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../shared/presentation/widgets/app_hero_header.dart';
import '../../domain/entities/history_item.dart';
import '../view_models/qr_history_view_model.dart';

class QrHistoryPage extends StatefulWidget {
  const QrHistoryPage({super.key});

  @override
  State<QrHistoryPage> createState() => _QrHistoryPageState();
}

class _QrHistoryPageState extends State<QrHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      context.read<QrHistoryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: <Widget>[
          AppHeroHeader(
            title: AppStrings.historyTitle,
            subtitle: 'Tudo fica no dispositivo. Apaga o que já não for útil.',
            trailing: TextButton(
              onPressed: () => _onClearAll(context),
              child: Text(AppStrings.historyClear, style: GoogleFonts.plusJakartaSans(color: t.danger, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<QrHistoryViewModel>(
              builder: (BuildContext context, QrHistoryViewModel v, _) {
                if (v.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (v.error != null) {
                  return Center(child: Text('Erro: ${v.error}'));
                }
                if (v.items.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.historyEmpty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: t.muted),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: v.load,
                  child: ListView.separated(
                    itemCount: v.items.length,
                    separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      return _HistoryCard(item: v.items[i], onDelete: (String id) => v.remove(id));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          title: const Text('Limpar tudo?'),
          content: const Text('Esta ação apaga o histórico local deste aparelho.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(AppStrings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Limpar')),
          ],
        );
      },
    );
    if (ok == true && context.mounted) {
      await context.read<QrHistoryViewModel>().clear();
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onDelete});
  final HistoryItem item;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final c = Theme.of(context).colorScheme;
    final df = DateFormat('dd/MM/yyyy · HH:mm');
    final title = item.type == HistoryItemType.scan ? AppStrings.scanType : AppStrings.genType;
    return Dismissible(
      key: ValueKey<String>(item.id),
      direction: DismissDirection.endToStart,
      background: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x22DC2626),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
          ),
        ),
      ),
      onDismissed: (_) => onDelete(item.id),
      child: Material(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _showContent(context, item, c);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: (item.type == HistoryItemType.scan ? t.brand : t.muted).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      item.type == HistoryItemType.scan ? Icons.qr_code_scanner : Icons.qr_code_2,
                      color: item.type == HistoryItemType.scan ? t.brand : t.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: t.muted),
                          ),
                          const Spacer(),
                          Text(
                            df.format(item.createdAt),
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: t.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(textStyle: Theme.of(context).textTheme.bodySmall),
                      ),
                      if (item.type == HistoryItemType.scan) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Veredicto: ${item.verdict ?? "—"} · Abrir: ${item.safeToOpen == null ? "—" : (item.safeToOpen! ? "sim" : "não")}',
                          style: GoogleFonts.plusJakartaSans(color: t.muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showContent(BuildContext context, HistoryItem item, ColorScheme c) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + MediaQuery.paddingOf(ctx).bottom, top: 4),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text('Conteúdo', style: GoogleFonts.plusJakartaSans(color: c.onSurface, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 8),
            SelectableText(item.content, style: GoogleFonts.jetBrainsMono(textStyle: Theme.of(context).textTheme.bodySmall)),
            if (item.reasons.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text('Razões', style: GoogleFonts.plusJakartaSans(color: c.onSurface, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 6),
              ...List<Widget>.generate(
                item.reasons.length,
                (int i) => Text('· ${item.reasons[i]}', style: GoogleFonts.plusJakartaSans(textStyle: Theme.of(context).textTheme.bodyMedium)),
              ),
            ],
          ],
        ),
      );
    },
  );
}
