import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/result.dart';
import '../../../data/models/subscription.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../domain/apply_import.dart';
import '../domain/http_source.dart';
import '../domain/parsed_import.dart';

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  static const refreshAfter = Duration(hours: 24);

  @override
  Future<Subscription?> build() => ref.read(settingsRepositoryProvider).loadSubscription();

  Future<void> _commit(Subscription? sub) async {
    await ref.read(settingsRepositoryProvider).saveSubscription(sub);
    state = AsyncData(sub);
  }

  static String sourceIdFor(Uri uri) => 'url:${uri.host}';

  /// Lädt und parst, ohne etwas zu speichern (für Vorschau).
  Future<Result<ParsedImport>> fetchAndParse(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return const Err('Bitte eine gültige http- oder https-Adresse eingeben.');
    }
    try {
      final bytes = await ref.read(httpSourceProvider).getBytes(uri);
      return ref.read(importServiceProvider).parseBytes(bytes: bytes, sourceId: sourceIdFor(uri));
    } on HttpSourceException catch (e) {
      return Err(e.message);
    } on SocketException {
      return const Err('Keine Netzwerkverbindung.');
    } catch (e) {
      return Err('Laden fehlgeschlagen: $e');
    }
  }

  /// Speichert das Abo und führt einen ersten erzwungenen Abruf aus.
  Future<void> activate(String url) async {
    await _commit(Subscription(url: url.trim()));
    await refresh(force: true);
  }

  Future<bool>? _inFlight;

  /// Gibt `true` zurück, wenn Daten erfolgreich übernommen wurden.
  /// Gleichzeitige Aufrufe teilen sich denselben Abruf.
  Future<bool> refresh({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final f = _refresh(force: force).whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  Future<bool> _refresh({required bool force}) async {
    final sub = state.value ?? await future;
    if (sub == null) return false;
    final now = ref.read(clockProvider).now();
    if (!force && sub.lastFetched != null && now.difference(sub.lastFetched!) < refreshAfter) {
      return false;
    }
    final result = await fetchAndParse(sub.url);
    final current = state.value;
    if (current == null || current.url != sub.url) return false;
    switch (result) {
      case Ok(:final value):
        try {
          await ref.read(appDataProvider.notifier).applyParsedImport(value, ImportMode.merge);
          await _commit(current.copyWith(lastFetched: now, clearError: true));
          return true;
        } catch (e) {
          await _commit(current.copyWith(lastError: 'Übernahme fehlgeschlagen: $e'));
          return false;
        }
      case Err(:final message):
        await _commit(current.copyWith(lastError: message));
        return false;
    }
  }

  Future<void> remove() => _commit(null);

  Future<void> markActivated(String url) =>
      _commit(Subscription(url: url.trim(), lastFetched: ref.read(clockProvider).now()));
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(SubscriptionNotifier.new);
