import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// User preferences model to store filtering options
class UserPreferences {
  bool vegetarian;
  bool vegan;
  bool glutenFree;
  bool dairyFree;
  int maxCalories;

  UserPreferences({
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
    this.dairyFree = false,
    this.maxCalories = 1000,
  });

  // Convert to query parameters for API
  String toQueryString() {
    List<String> params = [];
    if (vegetarian) params.add('diet=vegetarian');
    if (vegan) params.add('diet=vegan');
    if (glutenFree) params.add('intolerances=gluten');
    if (dairyFree) params.add('intolerances=dairy');
    if (maxCalories > 0) params.add('maxCalories=$maxCalories');

    return params.join('&');
  }

  // Save preferences to local storage
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('vegetarian', vegetarian);
    prefs.setBool('vegan', vegan);
    prefs.setBool('glutenFree', glutenFree);
    prefs.setBool('dairyFree', dairyFree);
    prefs.setInt('maxCalories', maxCalories);
  }

  // Load preferences from local storage
  static Future<UserPreferences> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences(
      vegetarian: prefs.getBool('vegetarian') ?? false,
      vegan: prefs.getBool('vegan') ?? false,
      glutenFree: prefs.getBool('glutenFree') ?? false,
      dairyFree: prefs.getBool('dairyFree') ?? false,
      maxCalories: prefs.getInt('maxCalories') ?? 1000,
    );
  }
}

class GroceryPage extends StatefulWidget {
  @override
  _GroceryPageState createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  final String apiKey = '6cc047ebf7264623b2c64b0ac21c2499';
  List<dynamic> recipes = [];
  String query = '';
  int offset = 0;
  final int limit = 10;
  bool isLoading = false;
  bool hasMore = true;
  bool isFirstVisit = true; // Add this flag
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  UserPreferences userPrefs = UserPreferences();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchRecipes();
      }
    });
  }

  Future<void> _loadUserPreferences() async {
    userPrefs = await UserPreferences.loadFromPrefs();
    setState(() {});
    // Don't automatically fetch recipes on first load
    // fetchRecipes() - Remove this line
  }

  Future<void> fetchRecipes({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      offset = 0;
      recipes.clear();
      hasMore = true;
    }

    // Build URL with user preferences
    final prefsQuery = userPrefs.toQueryString();
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/complexSearch?query=$query&number=$limit&offset=$offset&apiKey=$apiKey&addNutrition=true&$prefsQuery',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newRecipes = data['results'];

      setState(() {
        recipes.addAll(newRecipes);
        offset += limit;
        if (newRecipes.length < limit) {
          hasMore = false;
        }
      });
    } else {
      print('Failed to load recipes: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    setState(() => isLoading = false);
  }

  void _onSearch(String value) {
    if (value.trim().isEmpty) return; // Don't search if empty

    setState(() {
      query = value.trim();
      isFirstVisit = false; // No longer first visit after search
    });
    fetchRecipes(reset: true);
  }

  void _openPreferences() async {
    final result = await showDialog<UserPreferences>(
      context: context,
      builder: (context) => PreferencesDialog(initialPrefs: userPrefs),
    );

    if (result != null) {
      setState(() {
        userPrefs = result;
      });
      await userPrefs.saveToPrefs();
      fetchRecipes(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes'),
        actions: [
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: _openPreferences,
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _onSearch(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Active filters display
          if (userPrefs.vegetarian || userPrefs.vegan || userPrefs.glutenFree || userPrefs.dairyFree)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (userPrefs.vegetarian)
                      Chip(label: Text('Vegetarian')),
                    if (userPrefs.vegan)
                      Chip(label: Text('Vegan')),
                    if (userPrefs.glutenFree)
                      Chip(label: Text('Gluten-Free')),
                    if (userPrefs.dairyFree)
                      Chip(label: Text('Dairy-Free')),
                    Chip(label: Text('Max ${userPrefs.maxCalories} cal')),
                  ],
                ),
              ),
            ),
          Expanded(
            child: !isFirstVisit && recipes.isEmpty && !isLoading
                ? Center(child: Text('No recipes found.'))
                : isFirstVisit && recipes.isEmpty && !isLoading
                ? _buildWelcomeScreen() // Add a welcome screen for first visit
                : GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: recipes.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < recipes.length) {
                  final recipe = recipes[index];
                  // Extract calories if available
                  final nutrients = recipe['nutrition']?['nutrients'];
                  String calories = "N/A";
                  if (nutrients != null) {
                    final calorieInfo = nutrients.firstWhere(
                          (n) => n['name'] == 'Calories',
                      orElse: () => {'amount': 0},
                    );
                    calories = "${calorieInfo['amount'].toInt()} cal";
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipeId: recipe['id']),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  recipe['image'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      calories,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              recipe['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Diet indicators
                          Padding(
                            padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: Wrap(
                              spacing: 4,
                              children: [
                                if (recipe['vegetarian'] == true)
                                  _buildDietBadge('V', Colors.green),
                                if (recipe['vegan'] == true)
                                  _buildDietBadge('Ve', Colors.green[700]!),
                                if (recipe['glutenFree'] == true)
                                  _buildDietBadge('GF', Colors.orange),
                                if (recipe['dairyFree'] == true)
                                  _buildDietBadge('DF', Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Welcome to PlannerHut!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Search for food or recipes above or set your dietary preferences using the filter button.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.food_bank),
            label: Text('Browse Popular Food and Recipes'),
            onPressed: () {
              setState(() {
                query = 'popular';
                isFirstVisit = false;
              });
              fetchRecipes(reset: true);
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Preferences Dialog
class PreferencesDialog extends StatefulWidget {
  final UserPreferences initialPrefs;

  PreferencesDialog({required this.initialPrefs});

  @override
  _PreferencesDialogState createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  late UserPreferences prefs;

  @override
  void initState() {
    super.initState();
    // Create a copy of the preferences to avoid modifying the original
    prefs = UserPreferences(
      vegetarian: widget.initialPrefs.vegetarian,
      vegan: widget.initialPrefs.vegan,
      glutenFree: widget.initialPrefs.glutenFree,
      dairyFree: widget.initialPrefs.dairyFree,
      maxCalories: widget.initialPrefs.maxCalories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Dietary Preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Vegetarian'),
              value: prefs.vegetarian,
              onChanged: (value) => setState(() => prefs.vegetarian = value),
            ),
            SwitchListTile(
              title: Text('Vegan'),
              value: prefs.vegan,
              onChanged: (value) => setState(() => prefs.vegan = value),
            ),
            SwitchListTile(
              title: Text('Gluten-Free'),
              value: prefs.glutenFree,
              onChanged: (value) => setState(() => prefs.glutenFree = value),
            ),
            SwitchListTile(
              title: Text('Dairy-Free'),
              value: prefs.dairyFree,
              onChanged: (value) => setState(() => prefs.dairyFree = value),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Maximum Calories per Serving'),
            ),
            Slider(
              value: prefs.maxCalories.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              label: '${prefs.maxCalories} cal',
              onChanged: (value) => setState(() => prefs.maxCalories = value.toInt()),
            ),
            Center(
              child: Text(
                '${prefs.maxCalories} calories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, prefs),
          child: Text('Apply'),
        ),
      ],
    );
  }
}

// Detail Page (enhanced with nutrition information)
class RecipeDetailPage extends StatefulWidget {
  final int recipeId;

  RecipeDetailPage({required this.recipeId});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetail;
  final String apiKey = '6cc047ebf7264623b2c64b0ac21c2499';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipeDetail();
  }

  Future<void> fetchRecipeDetail() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey&includeNutrition=true',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        recipeDetail = data;
        isLoading = false;
      });
    } else {
      print('Failed to load recipe detail: ${response.statusCode}');
      print('Response body: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipe Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipeDetail == null
          ? Center(child: Text('Failed to load recipe details'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipeDetail!['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),

            // Title and badges
            Text(
              recipeDetail!['title'],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Diet badges
            Wrap(
              spacing: 8,
              children: [
                if (recipeDetail!['vegetarian'] == true)
                  _buildInfoBadge('Vegetarian', Colors.green),
                if (recipeDetail!['vegan'] == true)
                  _buildInfoBadge('Vegan', Colors.green[700]!),
                if (recipeDetail!['glutenFree'] == true)
                  _buildInfoBadge('Gluten-Free', Colors.orange),
                if (recipeDetail!['dairyFree'] == true)
                  _buildInfoBadge('Dairy-Free', Colors.blue),
                _buildInfoBadge('${recipeDetail!['readyInMinutes']} min', Colors.purple),
                _buildInfoBadge('Serves ${recipeDetail!['servings']}', Colors.teal),
              ],
            ),
            SizedBox(height: 16),

            // Nutrition section
            _buildNutritionSection(),

            Divider(height: 32),

            // Ingredients section
            Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ...List<Widget>.from(
              recipeDetail!['extendedIngredients'].map(
                    (ing) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          ing['original'],
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(height: 32),

            // Instructions section
            Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            if (recipeDetail!['analyzedInstructions'].isNotEmpty &&
                recipeDetail!['analyzedInstructions'][0]['steps'].isNotEmpty)
              ...List<Widget>.from(
                recipeDetail!['analyzedInstructions'][0]['steps'].map(
                      (step) => Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${step['number']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step['step'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Text(
                recipeDetail!['instructions'] ?? 'No instructions available.',
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    if (recipeDetail == null || recipeDetail!['nutrition'] == null) {
      return SizedBox.shrink();
    }

    final nutrients = recipeDetail!['nutrition']['nutrients'];

    // Extract main nutrients
    Map<String, dynamic> mainNutrients = {};
    List<String> keyNutrients = ['Calories', 'Fat', 'Carbohydrates', 'Protein', 'Sugar', 'Fiber', 'Cholesterol', 'Sodium'];

    for (var nutrient in nutrients) {
      if (keyNutrients.contains(nutrient['name'])) {
        mainNutrients[nutrient['name']] = {
          'amount': nutrient['amount'],
          'unit': nutrient['unit'],
          'percentOfDailyNeeds': nutrient['percentOfDailyNeeds'],
        };
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Information (per serving):',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),

        // Calories bar
        if (mainNutrients.containsKey('Calories'))
          _buildMainNutrientTile(
            'Calories',
            mainNutrients['Calories']['amount'].toInt(),
            mainNutrients['Calories']['unit'],
            mainNutrients['Calories']['percentOfDailyNeeds'],
            Colors.red,
          ),

        // Macronutrients group
        Row(
          children: [
            if (mainNutrients.containsKey('Protein'))
              Expanded(
                child: _buildNutrientTile(
                  'Protein',
                  mainNutrients['Protein']['amount'].toStringAsFixed(1),
                  mainNutrients['Protein']['unit'],
                  mainNutrients['Protein']['percentOfDailyNeeds'],
                  Colors.blue,
                ),
              ),
            if (mainNutrients.containsKey('Fat'))
              Expanded(
                child: _buildNutrientTile(
                  'Fat',
                  mainNutrients['Fat']['amount'].toStringAsFixed(1),
                  mainNutrients['Fat']['unit'],
                  mainNutrients['Fat']['percentOfDailyNeeds'],
                  Colors.orange,
                ),
              ),
            if (mainNutrients.containsKey('Carbohydrates'))
              Expanded(
                child: _buildNutrientTile(
                  'Carbs',
                  mainNutrients['Carbohydrates']['amount'].toStringAsFixed(1),
                  mainNutrients['Carbohydrates']['unit'],
                  mainNutrients['Carbohydrates']['percentOfDailyNeeds'],
                  Colors.green,
                ),
              ),
          ],
        ),

        // Additional nutrients
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            if (mainNutrients.containsKey('Sugar'))
              _buildNutrientTile(
                'Sugar',
                mainNutrients['Sugar']['amount'].toStringAsFixed(1),
                mainNutrients['Sugar']['unit'],
                mainNutrients['Sugar']['percentOfDailyNeeds'],
                Colors.pink,
              ),
            if (mainNutrients.containsKey('Fiber'))
              _buildNutrientTile(
                'Fiber',
                mainNutrients['Fiber']['amount'].toStringAsFixed(1),
                mainNutrients['Fiber']['unit'],
                mainNutrients['Fiber']['percentOfDailyNeeds'],
                Colors.brown,
              ),
            if (mainNutrients.containsKey('Sodium'))
              _buildNutrientTile(
                'Sodium',
                mainNutrients['Sodium']['amount'].toStringAsFixed(0),
                mainNutrients['Sodium']['unit'],
                mainNutrients['Sodium']['percentOfDailyNeeds'],
                Colors.purple,
              ),
            if (mainNutrients.containsKey('Cholesterol'))
              _buildNutrientTile(
                'Cholesterol',
                mainNutrients['Cholesterol']['amount'].toStringAsFixed(0),
                mainNutrients['Cholesterol']['unit'],
                mainNutrients['Cholesterol']['percentOfDailyNeeds'],
                Colors.blueGrey,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainNutrientTile(String name, int amount, String unit, double percent, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$amount $unit (${percent.toInt()}% DV)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientTile(String name, String amount, String unit, double percent, Color color) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '$amount $unit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${percent.toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}