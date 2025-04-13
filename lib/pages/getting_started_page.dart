import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  // Fixed theme color matching your original green
  final Color _themeColor = const Color(0xFF5CB85C);
  final FirestoreService _firestoreService = FirestoreService();

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Plan Your Meals",
      description:
      "Create weekly meal plans with our intuitive drag-and-drop interface. Organize breakfast, lunch, and dinner with ease.",
      image: Icons.restaurant_menu,
      backgroundImage: "assets/app_intro1.jpg",
    ),
    OnboardingPage(
      title: "Smart Shopping Lists",
      description:
      "Generate shopping lists automatically based on your meal plan. Never forget an ingredient again!",
      image: Icons.shopping_cart,
      backgroundImage: "assets/app_intro2.jpg",
    ),
    OnboardingPage(
      title: "Track Nutrition",
      description:
      "Monitor your calorie intake and nutritional balance. Eat healthier with personalized insights.",
      image: Icons.pie_chart,
      backgroundImage: "assets/app_intro3.jpg",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    try {
      await _firestoreService.setOnboardingCompleted();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } catch (e) {
      print('Error completing onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Single PageView for both background and content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  // Background layer
                  buildBackground(_pages[index]),

                  // Content layer
                  SafeArea(
                    child: buildPageContent(_pages[index]),
                  ),
                ],
              );
            },
          ),

          // Bottom navigation stays fixed at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget buildBackground(OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image - each slide has its own image
        Image.asset(
          page.backgroundImage,
          fit: BoxFit.cover,
        ),
        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _themeColor.withOpacity(0.6),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Changed from center to start
        children: [
          // Added top spacing to push content down from the very top
          const SizedBox(height: 60),

          // Enhanced Icon Display
          Container(
            width: 160, // Slightly reduced size
            height: 160, // Slightly reduced size
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _themeColor.withOpacity(0.7),
                  _themeColor.withOpacity(0.3)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _themeColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.image,
              size: 90, // Slightly reduced size
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 40), // Adjusted spacing

          // Enhanced Title
          Text(
            page.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 25),

          // Enhanced Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              page.description,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Removed the extra spacer at the bottom
          // Content will naturally be pushed up
        ],
      ),
    );
  }

  Widget buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Enhanced page indicator
          Row(
            children: List.generate(
              _pages.length,
                  (index) => buildDot(index: index),
            ),
          ),

          // Enhanced navigation buttons
          _currentPage == _pages.length - 1
              ? ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: _themeColor.withOpacity(0.5),
            ),
            child: Row(
              children: [
                const Text(
                  "GET STARTED",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                  ),
                ),
              ],
            ),
          )
              : TextButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "NEXT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot({required int index}) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 8),
        height: 10,
        width: _currentPage == index ? 30 : 10,
        decoration: BoxDecoration(
          color: _currentPage == index
              ? _themeColor
              : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(5),
          boxShadow: _currentPage == index
              ? [
            BoxShadow(
              color: _themeColor.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final String backgroundImage;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundImage,
  });
}