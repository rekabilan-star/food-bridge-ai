import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Donating Made Smart',
      'desc': 'Upload surplus food details and let our AI find the best-suited NGO nearby instantly.',
      'icon': 'Icons.eco',
    },
    {
      'title': 'Optimized Deliveries',
      'desc': 'Our volunteers use smart route optimization to ensure food reaches beneficiaries fresh and fast.',
      'icon': 'Icons.directions_bike',
    },
    {
      'title': 'Track Your Impact',
      'desc': 'Monitor your CO2 reduction and see exactly how many meals you have provided to the community.',
      'icon': 'Icons.analytics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(
                        index == 0 ? Icons.eco : index == 1 ? Icons.directions_bike : Icons.analytics,
                        size: 100,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _pages[index]['title']!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _pages[index]['desc']!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(_pages.length, (index) => 
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Colors.green : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    if (_currentIndex < _pages.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    }
                  },
                  backgroundColor: Colors.green,
                  child: Icon(_currentIndex == _pages.length - 1 ? Icons.check : Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
