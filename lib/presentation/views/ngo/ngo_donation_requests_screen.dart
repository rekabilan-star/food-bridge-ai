import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'donation_details_screen.dart';

class NgoDonationRequestsScreen extends StatefulWidget {
  const NgoDonationRequestsScreen({super.key});

  @override
  State<NgoDonationRequestsScreen> createState() => _NgoDonationRequestsScreenState();
}

class _NgoDonationRequestsScreenState extends State<NgoDonationRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dVM = context.read<DonationViewModel>();
      dVM.initSocket();
      dVM.fetchAvailableDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Opportunities"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by food name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                context.read<DonationViewModel>().fetchAvailableDonations(search: value);
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DonationViewModel>().fetchAvailableDonations(search: _searchController.text.trim());
        },
        child: Column(
          children: [
            _buildAiBanner(),
            Expanded(
              child: Consumer<DonationViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading && viewModel.donations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (viewModel.donations.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(child: Text("No donations available at the moment.")),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.donations.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(viewModel.donations[index]).animate().fadeIn(duration: 350.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 300))).slideY(begin: 0.08, end: 0, duration: 350.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 300)), curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBanner() {
    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "AI is recommending these based on your location and food preferences.",
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveFoodImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (File(trimmed).existsSync()) {
      return trimmed;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootServer$cleanPath';
  }

  Widget _buildRequestCard(DonationModel donation) {
    final rawUrl = donation.imageUrl;
    final resolvedUrl = _resolveFoodImageUrl(rawUrl);
    final isLocalFile = rawUrl.isNotEmpty && File(rawUrl).existsSync();

    final user = context.watch<AuthViewModel>().user;
    final double userLat = user?.latitude ?? 0;
    final double userLng = user?.longitude ?? 0;
    String distBadge = "WITHIN 20 KM";
    if (userLat != 0 && userLng != 0 && donation.latitude != 0 && donation.longitude != 0) {
      final meters = Geolocator.distanceBetween(userLat, userLng, donation.latitude, donation.longitude);
      distBadge = "${(meters / 1000).toStringAsFixed(1)} KM AWAY";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation))
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: resolvedUrl.isEmpty
                          ? Icon(Icons.fastfood_rounded, color: Colors.grey[400], size: 32)
                          : (isLocalFile
                              ? Image.file(File(rawUrl), fit: BoxFit.cover)
                              : Image.network(
                                  resolvedUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.fastfood_rounded, color: Colors.grey[400], size: 32),
                                )),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                              child: const Text("98% AI Score", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.ngoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(distBadge, style: const TextStyle(color: AppColors.ngoColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(donation.foodName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(donation.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("Serves ${donation.membersServed} Members", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    "Best before ${donation.bestBeforeTime.hour}:${donation.bestBeforeTime.minute.toString().padLeft(2, '0')}", 
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _acceptDonationDirectly(donation),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text("ACCEPT DONATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ngoColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acceptDonationDirectly(DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Accept Donation?"),
        content: Text("Accept '${donation.foodName}' and add it to your Rescue Control dashboard?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final viewModel = context.read<DonationViewModel>();
              final success = await viewModel.updateDonationStatus(donation.id, 'accepted');
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Donation Accepted! Navigating to Rescue Control..."))
                );
                Navigator.pushNamedAndRemoveUntil(context, '/ngo-dashboard', (route) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(viewModel.errorMessage ?? "Failed to accept donation"))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ngoColor),
            child: const Text("ACCEPT & GO TO DASHBOARD"),
          ),
        ],
      ),
    );
  }
}
