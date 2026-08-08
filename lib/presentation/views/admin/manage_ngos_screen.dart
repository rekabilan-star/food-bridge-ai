import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageNgosScreen extends StatefulWidget {
  const ManageNgosScreen({super.key});

  @override
  State<ManageNgosScreen> createState() => _ManageNgosScreenState();
}

class _ManageNgosScreenState extends State<ManageNgosScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchNgos(status: 'pending');
    });
  }

  void _onSearch({int page = 1}) {
    _currentPage = page;
    context.read<AdminViewModel>().fetchNgos(
      status: 'pending',
      search: _searchController.text.trim(),
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final ngos = viewModel.ngos;
    final isLoading = viewModel.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("NGO Approvals", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ngos.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: ngos.length,
                              itemBuilder: (context, index) {
                                final ngo = ngos[index];
                                return _buildNgoCard(ngo).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                              },
                            ),
                          ),
                          _buildPaginationControls(viewModel),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onSubmitted: (v) => _onSearch(),
        decoration: InputDecoration(
          hintText: "Search NGO name or email...",
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildNgoCard(UserModel ngo) {
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange[50],
                  child: Text(ngo.name[0], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ngo.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      Text("ID: ${ngo.id.substring(ngo.id.length - 8).toUpperCase()}", style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildStatusTag("PENDING", Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.email_rounded, ngo.email),
            _buildDetailRow(Icons.phone_rounded, ngo.phoneNumber),
            _buildDetailRow(Icons.location_on_rounded, ngo.address ?? 'No physical address'),
            _buildDetailRow(Icons.badge_rounded, "Personal ID Document: ${ngo.ngoRegistrationNumber ?? 'Aadhaar Card'}"),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleStatusUpdate(ngo.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 50),
                    ),
                    child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStatusUpdate(ngo.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 50),
                    ),
                    child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500))),
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
                      onTap: vm.ngos.length == 10 ? () => _onSearch(page: _currentPage + 1) : null,
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

  void _handleStatusUpdate(String id, String status) async {
    final success = await context.read<AdminViewModel>().updateNgoStatus(id, status);
    if (success) {
      if (mounted) UIUtils.showSuccessDialog(context, "NGO effectively ${status.toUpperCase()}ed");
    } else {
      if (mounted) UIUtils.showErrorDialog(context, context.read<AdminViewModel>().errorMessage ?? "Verification failed");
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No pending NGO applications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
