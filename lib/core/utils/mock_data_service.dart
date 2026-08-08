import '../../data/models/donation_model.dart';
import '../../data/repositories/emergency_repository.dart';

class MockDataService {
  static List<DonationModel> getSeedDonations() {
    return [
      DonationModel(
        id: 'don_101',
        donorId: 'user_donor_1',
        donorName: 'Dhoni Super Donor',
        donorPhone: '+91 9876543210',
        foodName: 'Paneer Butter Masala & Naan Box',
        category: 'Cooked Meals',
        membersServed: 25,
        imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500',
        preparedTime: DateTime.now().subtract(const Duration(minutes: 45)),
        bestBeforeTime: DateTime.now().add(const Duration(hours: 4)),
        pickupAddress: 'Building 4, Sector 2, HSR Layout, Bengaluru',
        latitude: 12.9121,
        longitude: 77.6446,
        specialInstructions: 'Please collect from Gate 2 cafeteria reception',
        status: 'in_progress',
        assignedNgoId: 'ngo_201',
        assignedNgoName: 'Asha Food Rescue Foundation',
        assignedNgoPhone: '+91 9123456789',
        qrCode: 'QR_FOOD_DON_101',
        timeline: [
          TimelineModel(status: 'requested', time: DateTime.now().subtract(const Duration(minutes: 45)), description: 'Donation created by donor'),
          TimelineModel(status: 'matched', time: DateTime.now().subtract(const Duration(minutes: 30)), description: 'Matched with Asha Food Rescue Foundation'),
          TimelineModel(status: 'picked_up', time: DateTime.now().subtract(const Duration(minutes: 15)), description: 'NGO pickup driver en route'),
        ],
      ),
      DonationModel(
        id: 'don_102',
        donorId: 'user_donor_1',
        donorName: 'Dhoni Super Donor',
        donorPhone: '+91 9876543210',
        foodName: 'Fresh Vegetable Biryani Packs',
        category: 'Cooked Meals',
        membersServed: 40,
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500',
        preparedTime: DateTime.now().subtract(const Duration(hours: 1)),
        bestBeforeTime: DateTime.now().add(const Duration(hours: 3)),
        pickupAddress: 'Koramangala 5th Block, Bengaluru',
        latitude: 12.9352,
        longitude: 77.6245,
        specialInstructions: 'Packed in thermal eco-insulated containers',
        status: 'accepted',
        assignedNgoId: 'ngo_202',
        assignedNgoName: 'Care India Relief Network',
        assignedNgoPhone: '+91 9811223344',
        qrCode: 'QR_FOOD_DON_102',
        timeline: [
          TimelineModel(status: 'requested', time: DateTime.now().subtract(const Duration(hours: 1)), description: 'Donation created'),
          TimelineModel(status: 'accepted', time: DateTime.now().subtract(const Duration(minutes: 40)), description: 'Accepted by Care India Relief Network'),
        ],
      ),
      DonationModel(
        id: 'don_103',
        donorId: 'user_donor_2',
        donorName: 'Grand Plaza Event Hall',
        donorPhone: '+91 9988776655',
        foodName: 'Surplus Event Catering Buffet',
        category: 'Cooked Meals',
        membersServed: 80,
        imageUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033?w=500',
        preparedTime: DateTime.now().subtract(const Duration(hours: 2)),
        bestBeforeTime: DateTime.now().add(const Duration(hours: 2)),
        pickupAddress: '100ft Road, Indiranagar, Bengaluru',
        latitude: 12.9784,
        longitude: 77.6408,
        specialInstructions: 'Contains Rotis, Rice, Dal & Mixed Veg Curry',
        status: 'waiting',
        qrCode: 'QR_FOOD_DON_103',
        timeline: [
          TimelineModel(status: 'requested', time: DateTime.now().subtract(const Duration(hours: 2)), description: 'Awaiting nearby NGO matching'),
        ],
      ),
      DonationModel(
        id: 'don_104',
        donorId: 'user_donor_1',
        donorName: 'Dhoni Super Donor',
        donorPhone: '+91 9876543210',
        foodName: 'Fresh Fruit Baskets & Juices',
        category: 'Fruits & Groceries',
        membersServed: 15,
        imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
        preparedTime: DateTime.now().subtract(const Duration(hours: 5)),
        bestBeforeTime: DateTime.now().add(const Duration(hours: 12)),
        pickupAddress: 'MG Road, Bengaluru',
        latitude: 12.9716,
        longitude: 77.5946,
        specialInstructions: 'Delivered directly to Community Shelter',
        status: 'completed',
        assignedNgoId: 'ngo_201',
        assignedNgoName: 'Asha Food Rescue Foundation',
        qrCode: 'QR_FOOD_DON_104',
        timeline: [
          TimelineModel(status: 'requested', time: DateTime.now().subtract(const Duration(hours: 5)), description: 'Donation listed'),
          TimelineModel(status: 'completed', time: DateTime.now().subtract(const Duration(hours: 1)), description: 'Successfully handed over to shelter'),
        ],
      ),
    ];
  }

  static List<DonationModel> getSeedNgoAssignedDonations() {
    return getSeedDonations().where((d) => d.status != 'waiting').toList();
  }

  static List<EmergencyRequestModel> getSeedEmergencyRequests() {
    return [
      EmergencyRequestModel(
        id: 'emg_01',
        ngoId: 'ngo_201',
        ngoName: 'Asha Relief Foundation',
        title: 'Emergency Flood Relief Shelter Needs 100 Meals 🚨',
        reason: 'Severe rain evacuees at Govt School Shelter in desperate need of warm dinner meals.',
        requiredMembers: 100,
        foodType: 'Cooked Meals',
        address: 'Govt Primary School, HSR Sector 7, Bengaluru',
        latitude: 12.9081,
        longitude: 77.6490,
        requiredBefore: DateTime.now().add(const Duration(hours: 3)),
        priority: 'HIGH',
        status: 'active',
      ),
      EmergencyRequestModel(
        id: 'emg_02',
        ngoId: 'ngo_202',
        ngoName: 'City Care Shelter',
        title: 'Night Shelter Shortage: 30 Meals Required 🍲',
        reason: 'Night shelter near Majestic Railway Station short of dinners for 30 homeless individuals.',
        requiredMembers: 30,
        foodType: 'Cooked Meals',
        address: 'City Junction Night Shelter, Bengaluru',
        latitude: 12.9767,
        longitude: 77.5713,
        requiredBefore: DateTime.now().add(const Duration(hours: 2)),
        priority: 'URGENT',
        status: 'active',
      ),
    ];
  }

  static Map<String, dynamic> getSeedAdminStats() {
    return {
      'counts': {
        'totalDonors': 148,
        'totalNGOs': 42,
        'pendingNGOs': 3,
        'completedDonations': 580,
        'activeDonations': 14,
      },
      'impact': {
        'mealsServed': 18450,
        'co2Saved': 4280,
        'foodSavedKg': 6120,
        'membersServed': 18450,
      },
      'charts': {
        'dailyDonations': [
          {'_id': '2026-08-01', 'count': 32},
          {'_id': '2026-08-02', 'count': 45},
          {'_id': '2026-08-03', 'count': 58},
          {'_id': '2026-08-04', 'count': 64},
          {'_id': '2026-08-05', 'count': 72},
          {'_id': '2026-08-06', 'count': 88},
          {'_id': '2026-08-07', 'count': 95},
        ],
        'categories': [
          {'_id': 'Cooked Meals', 'count': 380},
          {'_id': 'Raw Groceries', 'count': 140},
          {'_id': 'Bakery Items', 'count': 60},
          {'_id': 'Fruits & Veggies', 'count': 40},
        ],
      },
      'recentActivity': [
        {
          'foodName': 'Paneer Butter Masala & Naan Box',
          'donorId': {'name': 'Royal Spices Restaurant'},
          'status': 'in_progress',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        },
        {
          'foodName': 'Fresh Vegetable Biryani Packs',
          'donorId': {'name': 'Dhoni Super Donor'},
          'status': 'accepted',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
        },
        {
          'foodName': 'Surplus Event Catering Buffet',
          'donorId': {'name': 'Grand Plaza Event Hall'},
          'status': 'waiting',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'foodName': 'Fresh Fruit Baskets & Juices',
          'donorId': {'name': 'Bakers Delight'},
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ],
    };
  }
}
