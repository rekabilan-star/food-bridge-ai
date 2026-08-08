import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;
  String? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch({int page = 1}) {
    _currentPage = page;
    context.read<AdminViewModel>().fetchUsers(
      search: _searchController.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("User Manager", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _onSearch(page: _currentPage),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.users.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(child: _buildUserList(viewModel.users)),
                          _buildPaginationControls(viewModel),
                        ],
                      ),
          ),
        ],
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
              hintText: "Search name, email, or phone...",
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
                  "All Roles",
                  ['donor', 'ngo', 'volunteer'],
                  _selectedRole,
                  (v) {
                    setState(() => _selectedRole = v);
                    _onSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  "All Status",
                  ['approved', 'pending', 'rejected'],
                  _selectedStatus,
                  (v) {
                    setState(() => _selectedStatus = v);
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(value: null, child: Text(hint)),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
              child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role), size: 20),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                _buildStatusChip(user.status ?? 'pending'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
                // Show detail sheet
            },
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
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
                      onTap: vm.users.length == 10 ? () => _onSearch(page: _currentPage + 1) : null,
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

  Widget _buildStatusChip(String status) {
    final color = status == 'approved' ? Colors.teal : (status == 'pending' ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.donor: return Colors.green;
      case UserRole.ngo: return Colors.orange;
      case UserRole.volunteer: return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.donor: return Icons.volunteer_activism_rounded;
      case UserRole.ngo: return Icons.business_rounded;
      case UserRole.volunteer: return Icons.directions_bike_rounded;
      default: return Icons.person_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No matches found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
