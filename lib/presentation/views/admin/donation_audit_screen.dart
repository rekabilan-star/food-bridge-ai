import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../ngo/donation_details_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class DonationAuditScreen extends StatefulWidget {
  const DonationAuditScreen({super.key});

  @override
  State<DonationAuditScreen> createState() => _DonationAuditScreenState();
}

class _DonationAuditScreenState extends State<DonationAuditScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchAllDonations();
    });
  }

  void _onSearch({int page = 1}) {
    _currentPage = page;
    context.read<AdminViewModel>().fetchAllDonations(
      search: _searchController.text.trim(),
      status: _selectedStatus,
      category: _selectedCategory,
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Donation Audit", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _onSearch(page: _currentPage)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _onSearch(page: _currentPage);
        },
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: viewModel.isLoading && viewModel.donations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.donations.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(child: _buildDonationList(viewModel.donations)),
                            _buildPaginationControls(viewModel),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (v) => _onSearch(),
            decoration: InputDecoration(
              hintText: "Search food or location...",
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchController.clear(); _onSearch(); }) : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  "All Status",
                  ['waiting', 'accepted', 'picked_up', 'delivered', 'completed', 'cancelled'],
                  _selectedStatus,
                  (v) {
                    setState(() => _selectedStatus = v);
                    _onSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  "All Categories",
                  ['Cooked Food', 'Raw Materials', 'Bakery', 'Fruits/Veggies'],
                  _selectedCategory,
                  (v) {
                    setState(() => _selectedCategory = v);
                    _onSearch();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(value: null, child: Text(hint)),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDonationList(List<DonationModel> donations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        donation.imageUrl,
                        width: 54, height: 54, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.restaurant_rounded, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(donation.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2)),
                          Text(donation.category, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    _buildStatusChip(donation.status),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.person_rounded, "Donor", donation.donorName ?? 'Anonymous'),
                _buildInfoRow(Icons.business_rounded, "NGO", donation.assignedNgoName ?? 'Unassigned'),
                _buildInfoRow(Icons.calendar_today_rounded, "Posted", DateFormat('MMM dd, yyyy • hh:mm a').format(donation.preparedTime)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAuditLog(donation), 
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: const Text("AUDIT LOG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)),
                          );
                        }, 
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("FULL DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _showAuditLog(DonationModel donation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Donation Audit Log", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Tracking timeline for: ${donation.foodName}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: donation.timeline.length,
                itemBuilder: (context, index) {
                  final log = donation.timeline[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(color: _getStatusColor(log.status), shape: BoxShape.circle),
                          ),
                          if (index != donation.timeline.length - 1)
                            Container(width: 2, height: 40, color: Colors.grey[200]),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(log.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, hh:mm a').format(log.time), style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(AdminViewModel vm) {
      return Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          color: Colors.grey[50],
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  _buildPageButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _currentPage > 1 ? () => _onSearch(page: _currentPage - 1) : null,
                  ),
                  const SizedBox(width: 24),
                  Text("Page $_currentPage", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(width: 24),
                  _buildPageButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: vm.donations.length == 10 ? () => _onSearch(page: _currentPage + 1) : null,
                  ),
              ],
          ),
      );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: onTap == null ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Icon(icon, size: 16, color: onTap == null ? Colors.grey[300] : Colors.black87),
          ),
      );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.teal;
      case 'waiting': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'picked_up': return Colors.purple;
      case 'on_the_way': return Colors.indigo;
      case 'arrived': return Colors.green;
      case 'cancelled':
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No donations found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
