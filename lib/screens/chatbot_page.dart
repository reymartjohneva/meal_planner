import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final String apiKey = '6cc047ebf7264623b2c64b0ac21c2499';

  // Using the same green from your onboarding screen
  final Color _themeColor = const Color(0xFF5CB85C);

  // Creating a custom MaterialColor based on the theme color
  // This allows accessing different shades like .shade700
  MaterialColor get _themeMaterialColor => createMaterialColor(_themeColor);

  // Method to create a MaterialColor from a single Color
  MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 0; i < 10; i++) {
      swatch[(strengths[i] * 1000).round()] = Color.fromRGBO(
        r,
        g,
        b,
        strengths[i],
      );
    }

    // Creating specific shades manually
    swatch[50] = Color.fromRGBO(r, g, b, 0.1);
    swatch[100] = Color.fromRGBO(r, g, b, 0.2);
    swatch[200] = Color.fromRGBO(r, g, b, 0.3);
    swatch[300] = Color.fromRGBO(r, g, b, 0.4);
    swatch[400] = Color.fromRGBO(r, g, b, 0.5);
    swatch[500] = Color.fromRGBO(r, g, b, 0.6);
    swatch[600] = Color.fromRGBO(r, g, b, 0.7);
    swatch[700] = Color.fromRGBO(r, g, b, 0.8);
    swatch[800] = Color.fromRGBO(r, g, b, 0.9);
    swatch[900] = Color.fromRGBO(r, g, b, 1.0);

    return MaterialColor(color.value, swatch);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = _themeColor;
    final secondaryColor = isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF8BC34A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlannerHut Chatbot'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? primaryColor
                            : isDarkMode ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: message.isUser
                            ? null
                            : Border.all(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : isDarkMode ? Colors.white : Colors.grey.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Thinking...',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (text) => _sendMessage(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey.shade800,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ask about food, meal plans, recipes...",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        prefixIcon: Icon(
                          Icons.restaurant,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _sendMessage,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text;
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    // Get response from Spoonacular API
    getSpoonacularResponse(message).then((response) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
      });
    });
  }

  Future<String> getSpoonacularResponse(String input) async {
    try {
      if (input.toLowerCase().contains("meal plan")) {
        // Meal Plan
        final url = Uri.parse(
            'https://api.spoonacular.com/mealplanner/generate?timeFrame=day&apiKey=$apiKey');
        final res = await http.get(url);
        final data = json.decode(res.body);

        if (res.statusCode != 200) {
          return "Sorry, I couldn't get meal plan information right now.";
        }

        final meals = data['meals'];
        return "Here's a meal plan for you:\n" +
            meals.map<String>((meal) => "- ${meal['title']}").join('\n');
      } else {
        // Search recipes
        final query = Uri.encodeComponent(input);
        final url = Uri.parse(
            'https://api.spoonacular.com/recipes/complexSearch?query=$query&number=3&apiKey=$apiKey');
        final res = await http.get(url);

        if (res.statusCode != 200) {
          return "Sorry, I couldn't find recipes at the moment.";
        }

        final data = json.decode(res.body);
        final results = data['results'];

        if (results.isEmpty) return "No recipes found for \"$input\".";

        return "Here are some recipes related to \"$input\":\n" +
            results
                .map<String>((r) => "- ${r['title']}")
                .toList()
                .join('\n');
      }
    } catch (e) {
      return "Sorry, I encountered an error: $e";
    }
  }

  Widget _buildWelcomeMessage() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace the icon with the app logo
            Container(
              width: 140,
              height: 140,
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
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "WELCOME TO THE PLANNERHUT CHATBOT",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _themeColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                "Ask me about recipes, meal plans, or any food-related questions!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.grey.shade700,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 35),
            Text(
              "Try these examples:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildSuggestionChip("Show me a meal plan", Icons.calendar_today),
            const SizedBox(height: 10),
            _buildSuggestionChip("Find pasta recipes", Icons.search),
            const SizedBox(height: 10),
            _buildSuggestionChip("Dinner ideas", Icons.dinner_dining),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              _themeColor.withOpacity(0.2),
              _themeColor.withOpacity(0.1),
            ]
                : [
              _themeColor.withOpacity(0.15),
              _themeColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _themeColor.withOpacity(isDarkMode ? 0.3 : 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: _themeColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : _themeMaterialColor.shade700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: _themeColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}