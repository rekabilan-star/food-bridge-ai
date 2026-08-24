import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/constants/app_constants.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          _onSearch(page: _currentPage);
        },
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: isLoading && ngos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ngos.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
    final isLoading = context.watch<AdminViewModel>().isLoading;

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
            _buildDetailRow(Icons.badge_rounded, "Personal ID Type: ${ngo.ngoRegistrationNumber ?? 'Government Certificate'}"),
            const SizedBox(height: 12),
            _buildCertificateSection(ngo),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : () => _handleStatusUpdate(ngo, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 50),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => _handleStatusUpdate(ngo, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 50),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCertificateUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$rootServer$cleanPath';
  }

  Widget _buildCertificateSection(UserModel ngo) {
    final String? certPath = (ngo.ngoCertificateUrl != null && ngo.ngoCertificateUrl!.isNotEmpty)
        ? ngo.ngoCertificateUrl
        : ngo.ngoIdProofUrl;
        
    final fullUrl = _resolveCertificateUrl(certPath);
    final bool isLocalFile = certPath != null && certPath.isNotEmpty && File(certPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_rounded, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            const Text(
              "Government Registration Certificate",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (fullUrl.isNotEmpty || isLocalFile)
          GestureDetector(
            onTap: () => _showFullCertificateDialog(context, ngo.name, fullUrl, isLocalFile ? certPath : null),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLocalFile)
                      Image.file(File(certPath), fit: BoxFit.cover, width: double.infinity, height: 170)
                    else
                      Image.network(
                        fullUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 170,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildUnavailableCertificateCard();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text("Tap to view full document", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _buildUnavailableCertificateCard(),
      ],
    );
  }

  Widget _buildUnavailableCertificateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 22),
          const SizedBox(width: 12),
          Text(
            "Certificate not available",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showFullCertificateDialog(BuildContext context, String ngoName, String url, String? localPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text("$ngoName Certificate", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: localPath != null
                      ? Image.file(File(localPath), fit: BoxFit.contain)
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text("Unable to load full certificate image"),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
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

  void _handleStatusUpdate(UserModel ngo, String status) {
    final bool isApprove = status == 'approved';
    UIUtils.showConfirmationDialog(
      context: context,
      title: isApprove ? "Approve NGO Application?" : "Reject NGO Application?",
      message: isApprove
          ? "Are you sure you want to approve ${ngo.name}? They will be granted access to NGO dashboard features."
          : "Are you sure you want to reject ${ngo.name}'s application?",
      confirmText: isApprove ? "APPROVE" : "REJECT",
      confirmColor: isApprove ? Colors.teal : Colors.red,
      onConfirm: () async {
        final success = await context.read<AdminViewModel>().updateNgoStatus(ngo.id, status);
        if (!mounted) return;
        if (success) {
          UIUtils.showSnackBar(context, "NGO application ${status.toUpperCase()}ED successfully");
        } else {
          UIUtils.showErrorDialog(context, context.read<AdminViewModel>().errorMessage ?? "Verification failed");
        }
      },
    );
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
