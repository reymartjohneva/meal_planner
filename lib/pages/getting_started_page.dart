import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Plan Your Meals",
      description: "Create weekly meal plans with our intuitive drag-and-drop interface. Organize breakfast, lunch, and dinner with ease.",
      image: Icons.restaurant_menu,
    ),
    OnboardingPage(
      title: "Smart Shopping Lists",
      description: "Generate shopping lists automatically based on your meal plan. Never forget an ingredient again!",
      image: Icons.shopping_cart,
    ),
    OnboardingPage(
      title: "Track Nutrition",
      description: "Monitor your calorie intake and nutritional balance. Eat healthier with personalized insights.",
      image: Icons.pie_chart,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return buildPageContent(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      _pages.length,
                          (index) => buildDot(index: index),
                    ),
                  ),

                  // Navigation buttons
                  _currentPage == _pages.length - 1
                      ? ElevatedButton(
                    onPressed: () {
                      // Navigate to your home screen
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CB85C),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : TextButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Row(
                      children: [
                        Text(
                          "Next",
                          style: TextStyle(
                            color: Color(0xFF5CB85C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF5CB85C),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.image,
            size: 150,
            color: const Color(0xFF5CB85C),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5CB85C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF5CB85C)
            : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}