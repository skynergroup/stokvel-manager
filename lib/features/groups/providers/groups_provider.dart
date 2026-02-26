import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/stokvel.dart';

final groupsListProvider = Provider<List<Stokvel>>((ref) {
  return [
    Stokvel(
      id: '1',
      name: 'Umoja Savings',
      type: StokvelType.rotational,
      contributionAmount: 500,
      contributionFrequency: 'monthly',
      createdBy: 'user1',
      createdAt: DateTime(2025, 1, 1),
      memberCount: 12,
      totalCollected: 48000,
    ),
    Stokvel(
      id: '2',
      name: 'Kasi Burial Society',
      type: StokvelType.burial,
      contributionAmount: 200,
      contributionFrequency: 'monthly',
      createdBy: 'user2',
      createdAt: DateTime(2024, 6, 15),
      memberCount: 25,
      totalCollected: 15000,
    ),
    Stokvel(
      id: '3',
      name: 'Year-End Grocery',
      type: StokvelType.grocery,
      contributionAmount: 300,
      contributionFrequency: 'monthly',
      createdBy: 'user1',
      createdAt: DateTime(2025, 3, 1),
      memberCount: 8,
      totalCollected: 7200,
    ),
  ];
});
