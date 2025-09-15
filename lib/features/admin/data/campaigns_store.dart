import 'package:hooks_riverpod/hooks_riverpod.dart';

class Campaign {
  Campaign({required this.title, required this.body});

  final String title;
  final String body;
}

class CampaignsStore extends StateNotifier<List<Campaign>> {
  CampaignsStore()
    : super([
        Campaign(title: 'Welcome', body: '10% off first order'),
        Campaign(title: 'New Beans', body: 'Try our seasonal roast'),
        Campaign(title: 'Rewards', body: 'Redeem points for free coffee'),
      ]);

  void add(String title, String body) {
    state = [...state, Campaign(title: title, body: body)];
  }
}

final campaignsStoreProvider =
    StateNotifierProvider<CampaignsStore, List<Campaign>>((ref) {
      return CampaignsStore();
    });
