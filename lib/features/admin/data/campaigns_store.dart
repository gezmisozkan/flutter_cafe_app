import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/models/repositories.dart';
import '../../../common/services/supabase.dart';
import '../../../core/env/env.dart';

class Campaign {
  Campaign({required this.title, required this.body});

  final String title;
  final String body;
}

class CampaignsStore extends StateNotifier<List<Campaign>> {
  CampaignsStore(this._repo) : super(const []) {
    _load();
  }

  final CampaignsRepository _repo;

  Future<void> _load() async {
    final items = await _repo.fetchAll();
    state = [for (final t in items) Campaign(title: t.$1, body: t.$2)];
  }

  Future<void> add(String title, String body) async {
    await _repo.add(title, body);
    state = [...state, Campaign(title: title, body: body)];
  }
}

final campaignsRepositoryProvider = Provider<CampaignsRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = ref.watch(supabaseClientProvider);
  if (env.isConfigured && client != null) {
    return SupabaseCampaignsRepository(client);
  }
  return InMemoryCampaignsRepository();
});

final campaignsStoreProvider =
    StateNotifierProvider<CampaignsStore, List<Campaign>>((ref) {
      final repo = ref.watch(campaignsRepositoryProvider);
      return CampaignsStore(repo);
    });
