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

  /// Gibt `true` zurück, wenn Daten erfolgreich übernommen wurden.
  Future<bool> refresh({bool force = false}) async {
    final sub = state.value ?? await future;
    if (sub == null) return false;
    final now = ref.read(clockProvider).now();
    if (!force && sub.lastFetched != null && now.difference(sub.lastFetched!) < refreshAfter) {
      return false;
    }
    final result = await fetchAndParse(sub.url);
    return result.when(
      ok: (parsed, _) async {
        await ref.read(appDataProvider.notifier).applyParsedImport(parsed, ImportMode.merge);
        await _commit(sub.copyWith(lastFetched: now, clearError: true));
        return true;
      },
      err: (message) async {
        await _commit(sub.copyWith(lastError: message));
        return false;
      },
    );
  }

  Future<void> remove() => _commit(null);
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(SubscriptionNotifier.new);
