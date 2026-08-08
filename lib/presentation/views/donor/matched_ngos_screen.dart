import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchedNgosScreen extends StatefulWidget {
  final String? donationId;
  const MatchedNgosScreen({super.key, this.donationId});

  @override
  State<MatchedNgosScreen> createState() => _MatchedNgosScreenState();
}

class _MatchedNgosScreenState extends State<MatchedNgosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.donationId != null && widget.donationId!.isNotEmpty) {
        context.read<DonationViewModel>().fetchDonationRecommendations(widget.donationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("AI Rescue Matching", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (widget.donationId != null && widget.donationId!.isNotEmpty) {
                context.read<DonationViewModel>().fetchDonationRecommendations(widget.donationId!);
              }
            },
          ),
        ],
      ),
      body: Consumer<DonationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildLoadingState();
          }

          if (viewModel.recommendations.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFreshnessBanner(viewModel.currentDonation),
              Expanded(child: _buildNgoList(viewModel.recommendations)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 8, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            "Analyzing Local Partners...",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            "Our AI is evaluating distance, urgency,\nand NGO capacity for the best rescue.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              "No Immediate Matches",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              "We couldn't find active NGOs within 15km matching our high-confidence rescue criteria. Your donation is visible to all partners in the public pool.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text("BACK TO DASHBOARD"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreshnessBanner(DonationModel? donation) {
    if (donation == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final total = donation.bestBeforeTime.difference(donation.preparedTime).inMinutes;
    final left = donation.bestBeforeTime.difference(now).inMinutes;
    final double freshness = (left / total).clamp(0.0, 1.0);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: freshness < 0.3 ? [Colors.red[400]!, Colors.red[700]!] : [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DONATION FRESHNESS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text("${(freshness * 100).toInt()}% Quality Remaining", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(freshness < 0.3 ? Icons.warning_amber_rounded : Icons.eco_rounded, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: freshness,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            freshness < 0.3 ? "Critical: Finding fastest rescue possible" : "Healthy shelf life: Optimizing for best partner",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildNgoList(List<Map<String, dynamic>> ngos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ngos.length,
      itemBuilder: (context, index) {
        final ngo = ngos[index];
        final double score = (ngo['score'] ?? 0).toDouble();
        final int confidence = ngo['confidence'] ?? 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              _buildNgoHeader(ngo, score),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsRow(ngo),
                    const SizedBox(height: 20),
                    _buildAiExplanation(ngo['explanation'] ?? '', confidence),
                    const SizedBox(height: 20),
                    _buildReasonsList(ngo['reasons'] as List? ?? []),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 150).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildNgoHeader(Map<String, dynamic> ngo, double score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.business, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngo['name'] ?? 'NGO Partner',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  ngo['availability'] == 'Available' ? 'Ready for Pickup' : 'Busy (On Route)',
                  style: TextStyle(
                    fontSize: 12, 
                    color: ngo['availability'] == 'Available' ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          _buildScoreBadge(score),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[200],
                color: _getScoreColor(score),
                strokeWidth: 5,
              ),
            ),
            Text(
              score.toInt().toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: _getScoreColor(score)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text("MATCH", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> ngo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem(Icons.location_on_outlined, "${ngo['distanceKm']} km", "Distance"),
        _buildMetricItem(Icons.access_time, ngo['etaText'] ?? '--', "Est. Arrival"),
        _buildMetricItem(Icons.verified_user_outlined, "${confidencePercentage(ngo)}%", "Confidence"),
      ],
    );
  }

  int confidencePercentage(Map<String, dynamic> ngo) => ngo['confidence'] ?? 0;

  Widget _buildMetricItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAiExplanation(String text, int confidence) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text("AI Analysis ($confidence% match confidence)", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.blueGrey[800], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsList(List reasons) {
    return Column(
      children: reasons.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 12, color: Colors.black87))),
          ],
        ),
      )).toList(),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
