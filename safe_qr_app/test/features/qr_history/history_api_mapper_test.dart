import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_history/data/history_api_mapper.dart';
import 'package:safe_qr_app/features/qr_history/domain/entities/history_item.dart';

void main() {
  test('itemToApiJson espelha scan com verdict e safeToOpen', () {
    final HistoryItem item = HistoryItem(
      id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      type: HistoryItemType.scan,
      content: 'https://example.com',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1717689600123, isUtc: true),
      verdict: 'suspicious',
      safeToOpen: false,
      reasons: <String>['motivo'],
    );

    final Map<String, dynamic> json = HistoryApiMapper.itemToApiJson(item);

    expect(json['id'], item.id);
    expect(json['type'], 'scan');
    expect(json['content'], item.content);
    expect(json['createdAtMs'], 1717689600123);
    expect(json['verdict'], 'suspicious');
    expect(json['safeToOpen'], false);
    expect(json['reasons'], <String>['motivo']);
  });

  test('itemToApiJson espelha generated com verdict e safeToOpen null', () {
    final HistoryItem item = HistoryItem(
      id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
      type: HistoryItemType.generated,
      content: 'WIFI:T:WPA;S:x;P:y;;',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1717689700456, isUtc: true),
      reasons: <String>['Tipo: wifi'],
    );

    final Map<String, dynamic> json = HistoryApiMapper.itemToApiJson(item);

    expect(json['type'], 'generated');
    expect(json['verdict'], isNull);
    expect(json['safeToOpen'], isNull);
    expect(json['reasons'], <String>['Tipo: wifi']);
  });

  test('itemFromApiJson aceita reasons como List<dynamic> (resposta real da API)', () {
    final HistoryItem restored = HistoryApiMapper.itemFromApiJson(<String, dynamic>{
      'id': 'id-1',
      'type': 'scan',
      'content': 'x',
      'createdAtMs': 1000,
      'verdict': 'safe',
      'safeToOpen': true,
      'reasons': <dynamic>[
        'Ligação `https` a um host textualmente reconhecível (heurística; não é recomendação absoluta).',
      ],
    });

    expect(restored.id, 'id-1');
    expect(restored.type, HistoryItemType.scan);
    expect(restored.safeToOpen, isTrue);
    expect(restored.reasons, hasLength(1));
  });

  test('itemsFromListResponse com payload GET /v1/history', () {
    final List<HistoryItem> list = HistoryApiMapper.itemsFromListResponse(<String, dynamic>{
      'items': <dynamic>[
        <String, dynamic>{
          'id': '7ab18d82-1b14-42d2-ad60-4116d256219f',
          'type': 'scan',
          'content': 'https://amaz0n.com.br2',
          'createdAtMs': 1780976264492,
          'verdict': 'safe',
          'safeToOpen': true,
          'reasons': <dynamic>[
            'Ligação `https` a um host textualmente reconhecível (heurística; não é recomendação absoluta).',
          ],
        },
        <String, dynamic>{
          'id': 'a9dd55fb-23f6-4e83-adff-4c6b1589525d',
          'type': 'scan',
          'content': 'https://amaz0n.com.br',
          'createdAtMs': 1780976223205,
          'verdict': 'unsafe',
          'safeToOpen': false,
          'reasons': <dynamic>[
            'Domínio consta na lista de alertas (possível clone / phishing).',
            'Lista gerida no Firestore (`suspicious_hosts/clones`, campo `urls`).',
          ],
        },
      ],
      'total': 2,
    });

    expect(list, hasLength(2));
    expect(list.first.reasons, hasLength(1));
    expect(list.last.reasons, hasLength(2));
    expect(list.last.verdict, 'unsafe');
  });
}
