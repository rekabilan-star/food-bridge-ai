import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/utils/intent_utils.dart';
import 'package:intl/intl.dart';

class DeliveryMapScreen extends StatefulWidget {
  final DonationModel donation;

  const DeliveryMapScreen({super.key, required this.donation});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      Provider.of<DeliveryViewModel>(context, listen: false)
          .initDelivery(widget.donation, auth.user!.id);
    });
  }

  void _onStatusUpdate(String status) {
    String desc = "";
    switch (status) {
      case 'on_the_way':
        desc = "Volunteer is on the way to pick up food.";
        break;
      case 'arrived':
        desc = "Volunteer has arrived at the donor's location.";
        break;
      case 'picked_up':
        desc = "Food has been picked up and is being delivered.";
        break;
      case 'delivered':
        desc = "Food has been delivered to the NGO.";
        break;
    }
    Provider.of<DeliveryViewModel>(context, listen: false).updateStatus(status, desc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<DeliveryViewModel>(
            builder: (context, model, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(widget.donation.latitude, widget.donation.longitude),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mca_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.donation.latitude, widget.donation.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                      ),
                      if (model.volunteerPosition != null)
                        Marker(
                          point: model.volunteerPosition!,
                          width: 40,
                          height: 40,
                          child: Transform.rotate(
                            angle: model.volunteerHeading * (3.14159 / 180),
                            child: const Icon(Icons.directions_bike, color: Colors.blue, size: 40),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          _buildTopBar(),
          _buildFloatingControls(),
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Consumer<DeliveryViewModel>(
              builder: (context, model, _) => Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.orange),
                  const SizedBox(width: 5),
                  Text(
                    '${model.eta} (${model.distance})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 20,
      bottom: 350,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "loc",
            onPressed: () {
              final model = context.read<DeliveryViewModel>();
              if (model.volunteerPosition != null) {
                _mapController.move(model.volunteerPosition!, 15);
              }
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: "nav",
            onPressed: () => IntentUtils.openMapNavigation(widget.donation.latitude, widget.donation.longitude),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.navigation, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 20),
              _buildDeliveryHeader(),
              const Divider(height: 30),
              _buildActionButtons(),
              const SizedBox(height: 20),
              const Text('Delivery Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _buildTimeline(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(image: NetworkImage(widget.donation.imageUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.donation.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(widget.donation.donorName ?? "Donor", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Column(
          children: [
            const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Consumer<DeliveryViewModel>(
              builder: (context, model, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  model.currentDonation?.status.toUpperCase() ?? "WAITING",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _circleAction(Icons.phone, "Call", Colors.green, () => IntentUtils.makePhoneCall(widget.donation.donorPhone ?? '')),
        _circleAction(Icons.message, "Chat", Colors.blue, () => _sendWhatsApp(widget.donation.donorPhone ?? '')),
        _circleAction(Icons.check_circle, "Update", Colors.orange, () => _showStatusUpdateDialog()),
        _circleAction(Icons.error, "Emergency", Colors.red, () {}),
      ],
    );
  }

  Widget _circleAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: widget.donation.timeline.map((item) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                Container(width: 2, height: 30, color: Colors.grey[200]),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(DateFormat('hh:mm a').format(item.time), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showStatusUpdateDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Delivery Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Start Delivery'),
                onTap: () { _onStatusUpdate('on_the_way'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Arrived at Donor'),
                onTap: () { _onStatusUpdate('arrived'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Picked Up'),
                onTap: () { _onStatusUpdate('picked_up'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Delivered to NGO'),
                onTap: () { _onStatusUpdate('delivered'); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    final String message = "Hello, I am the volunteer for your food donation: ${widget.donation.foodName}. I am on my way.";
    await IntentUtils.sendWhatsAppMessage(phoneNumber, message);
  }
}
