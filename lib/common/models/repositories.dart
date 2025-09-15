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
