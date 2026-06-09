import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/analyze_mode.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../app/di/dependency_injection.dart';
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
  final Set<String> _selectedIds = <String>{};

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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }
    setState(_selectedIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final bool remoteHistory = sl<AppConfig>().analyzeMode == AnalyzeMode.remote;
    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: <Widget>[
                AppHeroHeader(
                  title: AppStrings.historyTitle,
                  subtitle: remoteHistory ? AppStrings.historySubtitleRemote : AppStrings.historySubtitleLocal,
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
                  onRefresh: () async {
                    await v.load();
                    if (mounted) {
                      _clearSelection();
                    }
                  },
                  child: ListView.separated(
                    itemCount: v.items.length,
                    separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final HistoryItem item = v.items[i];
                      final bool selected = _selectedIds.contains(item.id);
                      return _HistoryCard(
                        item: item,
                        selected: selected,
                        selectionActive: _selectedIds.isNotEmpty,
                        onTap: () => _showContent(context, item, Theme.of(context).colorScheme),
                        onLongPress: () => _toggleSelection(item.id),
                        onDelete: (String id) async {
                          await v.remove(id);
                          if (mounted) {
                            setState(() => _selectedIds.remove(id));
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedIds.isNotEmpty)
          _SelectionBottomBar(
            count: _selectedIds.length,
            bottomInset: MediaQuery.paddingOf(context).bottom,
            onDelete: () => _onDeleteSelected(context),
            onClearSelection: _clearSelection,
          ),
      ],
    );
  }

  Future<void> _onDeleteSelected(BuildContext context) async {
    final int count = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          title: const Text(AppStrings.historyDeleteSelectedConfirmTitle),
          content: Text(
            count == 1
                ? 'Este item será apagado permanentemente.'
                : 'Os $count itens selecionados serão apagados permanentemente.',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(AppStrings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text(AppStrings.historyDelete)),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final QrHistoryViewModel v = context.read<QrHistoryViewModel>();
    final List<String> ids = _selectedIds.toList(growable: false);
    await v.removeMany(ids);
    if (context.mounted) {
      setState(_selectedIds.clear);
    }
  }
}

class _SelectionBottomBar extends StatelessWidget {
  const _SelectionBottomBar({
    required this.count,
    required this.bottomInset,
    required this.onDelete,
    required this.onClearSelection,
  });

  final int count;
  final double bottomInset;
  final VoidCallback onDelete;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.surfaceContainerHighest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      elevation: 8,
      shadowColor: c.shadow.withValues(alpha: 0.2),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$count selecionado${count == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                TextButton(onPressed: onClearSelection, child: const Text(AppStrings.historyClearSelection)),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: t.danger.withValues(alpha: 0.12),
                foregroundColor: t.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(
                AppStrings.historyDeleteSelected,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.selected,
    required this.selectionActive,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final HistoryItem item;
  final bool selected;
  final bool selectionActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final c = Theme.of(context).colorScheme;
    final df = DateFormat('dd/MM/yyyy · HH:mm');
    final title = item.type == HistoryItemType.scan ? AppStrings.scanType : AppStrings.genType;

    final Widget card = Material(
      color: selected ? t.brand.withValues(alpha: 0.08) : c.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (selectionActive)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? t.brand : t.muted,
                    size: 22,
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: (item.type == HistoryItemType.scan ? t.brand : t.muted).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? t.brand.withValues(alpha: 0.5) : c.outlineVariant.withValues(alpha: 0.3),
                  ),
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
    );

    if (selectionActive) {
      return card;
    }

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
      child: card,
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
