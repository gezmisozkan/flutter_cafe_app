abstract class CampaignsRepository {
  Future<List<(String title, String body)>> fetchAll();
  Future<void> add(String title, String body);
}

class InMemoryCampaignsRepository implements CampaignsRepository {
  final List<(String, String)> _items = [
    ('Welcome', '10% off first order'),
    ('New Beans', 'Try our seasonal roast'),
    ('Rewards', 'Redeem points for free coffee'),
  ];

  @override
  Future<void> add(String title, String body) async {
    _items.add((title, body));
  }

  @override
  Future<List<(String title, String body)>> fetchAll() async {
    return List.of(_items);
  }
}

class SupabaseCampaignsRepository implements CampaignsRepository {
  SupabaseCampaignsRepository(this._client);

  final dynamic _client; // late-bound to avoid importing supabase here

  @override
  Future<void> add(String title, String body) async {
    await _client.from('campaigns').insert({'title': title, 'body': body});
  }

  @override
  Future<List<(String title, String body)>> fetchAll() async {
    final rows = await _client
        .from('campaigns')
        .select('title, body')
        .order('created_at');
    final list = (rows as List).cast<Map<String, dynamic>>();
    return [for (final r in list) (r['title'] as String, r['body'] as String)];
  }
}
