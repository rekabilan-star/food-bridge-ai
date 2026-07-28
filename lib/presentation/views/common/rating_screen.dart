import 'package:flutter/material.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../core/utils/ui_utils.dart';

class RatingScreen extends StatefulWidget {
  final String donationId;
  final String toUserId;
  final String toUserName;

  const RatingScreen({
    super.key,
    required this.donationId,
    required this.toUserId,
    required this.toUserName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isLoading = false;

  void _submitRating() async {
    if (_rating == 0) {
      UIUtils.showErrorDialog(context, "Please select a star rating");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await RatingRepository().submitRating(
        donationId: widget.donationId,
        toUserId: widget.toUserId,
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      if (mounted) {
        UIUtils.showSuccessDialog(context, "Thank you for your feedback!", onOk: () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate Experience")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.green, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 24),
            Text("How was your experience with", style: TextStyle(color: Colors.grey[600])),
            Text(widget.toUserName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              )),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: "Write a review (optional)",
                hintText: "What did you like or what can be improved?",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRating,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: _isLoading ? const CircularProgressIndicator() : const Text("SUBMIT FEEDBACK"),
            ),
          ],
        ),
      ),
    );
  }
}
