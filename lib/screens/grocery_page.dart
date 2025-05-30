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

// Recipe model to handle saving and loading favorites
class Recipe {
  final int id;
  final String title;
  final String image;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool dairyFree;
  final int calories;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.vegetarian,
    required this.vegan,
    required this.glutenFree,
    required this.dairyFree,
    required this.calories,
  });

  // Create from API JSON response
  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Extract calories if available
    final nutrients = json['nutrition']?['nutrients'];
    int calories = 0;
    if (nutrients != null) {
      final calorieInfo = nutrients.firstWhere(
            (n) => n['name'] == 'Calories',
        orElse: () => {'amount': 0},
      );
      calories = calorieInfo['amount'].toInt();
    }

    return Recipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
      glutenFree: json['glutenFree'] ?? false,
      dairyFree: json['dairyFree'] ?? false,
      calories: calories,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'vegetarian': vegetarian,
      'vegan': vegan,
      'glutenFree': glutenFree,
      'dairyFree': dairyFree,
      'calories': calories,
    };
  }
}

// Favorites manager class
class FavoritesManager {
  static const String _prefsKey = 'favorites';

  // Get all favorite recipes
  static Future<List<Recipe>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_prefsKey);

    if (favoritesJson == null) {
      return [];
    }

    final List<dynamic> favoritesData = json.decode(favoritesJson);
    return favoritesData.map((item) => Recipe.fromJson(item)).toList();
  }

  // Check if a recipe is favorited
  static Future<bool> isFavorite(int recipeId) async {
    final favorites = await getFavorites();
    return favorites.any((recipe) => recipe.id == recipeId);
  }

  // Add a recipe to favorites
  static Future<void> addFavorite(Recipe recipe) async {
    final favorites = await getFavorites();

    // Check if already exists
    if (favorites.any((item) => item.id == recipe.id)) {
      return;
    }

    favorites.add(recipe);
    await _saveFavorites(favorites);
  }

  // Remove a recipe from favorites
  static Future<void> removeFavorite(int recipeId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((recipe) => recipe.id == recipeId);
    await _saveFavorites(favorites);
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(Recipe recipe) async {
    final isFav = await isFavorite(recipe.id);

    if (isFav) {
      await removeFavorite(recipe.id);
      return false;
    } else {
      await addFavorite(recipe);
      return true;
    }
  }

  // Save favorites to SharedPreferences
  static Future<void> _saveFavorites(List<Recipe> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String favoritesJson = json.encode(
        favorites.map((recipe) => recipe.toJson()).toList()
    );
    await prefs.setString(_prefsKey, favoritesJson);
  }
}

class GroceryPage extends StatefulWidget {
  @override
  _GroceryPageState createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> with SingleTickerProviderStateMixin {
  final String apiKey = '6cc047ebf7264623b2c64b0ac21c2499';
  List<dynamic> recipes = [];
  String query = '';
  int offset = 0;
  final int limit = 10;
  bool isLoading = false;
  bool hasMore = true;
  bool isFirstVisit = true;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  UserPreferences userPrefs = UserPreferences();

  // Tab controller for search and favorites tabs
  late TabController _tabController;
  List<Recipe> favoriteRecipes = [];
  bool isFavoritesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPreferences();
    _loadFavorites();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore &&
          _tabController.index == 0) { // Only load more for search tab
        fetchRecipes();
      }
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Refresh favorites when tab is selected
        _loadFavorites();
      }
    });
  }

  Future<void> _loadFavorites() async {
    setState(() => isFavoritesLoading = true);

    try {
      final favorites = await FavoritesManager.getFavorites();
      setState(() {
        favoriteRecipes = favorites;
        isFavoritesLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => isFavoritesLoading = false);
    }
  }

  Future<void> _loadUserPreferences() async {
    userPrefs = await UserPreferences.loadFromPrefs();
    setState(() {});
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

  Future<void> _toggleFavorite(Map<String, dynamic> recipeData) async {
    final recipe = Recipe.fromJson(recipeData);
    final isFavorite = await FavoritesManager.toggleFavorite(recipe);

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          isFavorite
              ? '${recipe.title} added to favorites'
              : '${recipe.title} removed from favorites'
      ),
      duration: Duration(seconds: 2),
      action: SnackBarAction(
        label: 'View',
        onPressed: () {
          _tabController.animateTo(1); // Switch to favorites tab
        },
      ),
    ));

    // Refresh favorites if we're on that tab
    if (_tabController.index == 1) {
      _loadFavorites();
    }

    // Force rebuild of the current recipe card to update the icon
    setState(() {});
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.bookmark), text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Search Tab
          _buildSearchTab(),

          // Favorites Tab
          _buildFavoritesTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
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
              ? _buildWelcomeScreen()
              : _buildRecipeGrid(recipes, isFromSearch: true),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (isFavoritesLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (favoriteRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Mark recipes as favorites to see them here',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text('Find Recipes'),
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Your Favorite Recipes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.only(bottom: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: favoriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = favoriteRecipes[index];
                return _buildFavoriteRecipeCard(recipe);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<dynamic> recipeList, {bool isFromSearch = false}) {
    return GridView.builder(
      controller: isFromSearch ? _scrollController : null,
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: recipeList.length + (isFromSearch && hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < recipeList.length) {
          final recipe = recipeList[index];
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
                  builder: (_) => RecipeDetailPage(
                    recipeId: recipe['id'],
                    onFavoriteToggled: () {
                      // Refresh favorites when returning from detail page
                      if (_tabController.index == 1) {
                        _loadFavorites();
                      } else {
                        setState(() {}); // Refresh UI to update favorite icon
                      }
                    },
                  ),
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
                          left: 5,
                          child: FutureBuilder<bool>(
                            future: FavoritesManager.isFavorite(recipe['id']),
                            builder: (context, snapshot) {
                              final isFavorited = snapshot.data ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isFavorited ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorited ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(recipe),
                                  constraints: BoxConstraints.tightFor(width: 36, height: 36),
                                  padding: EdgeInsets.all(4),
                                  iconSize: 20,
                                ),
                              );
                            },
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
    );
  }

  Widget _buildFavoriteRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailPage(
              recipeId: recipe.id,
              onFavoriteToggled: () => _loadFavorites(),
            ),
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
                    recipe.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await FavoritesManager.removeFavorite(recipe.id);
                          _loadFavorites();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${recipe.title} removed from favorites'),
                            duration: Duration(seconds: 2),
                          ));
                        },
                        constraints: BoxConstraints.tightFor(width: 36, height: 36),
                        padding: EdgeInsets.all(4),
                        iconSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                recipe.title,
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
                  if (recipe.vegetarian)
                    _buildDietBadge('V', Colors.green),
                  if (recipe.vegan)
                    _buildDietBadge('Ve', Colors.green[700]!),
                  if (recipe.glutenFree)
                    _buildDietBadge('GF', Colors.orange),
                  if (recipe.dairyFree)
                    _buildDietBadge('DF', Colors.blue),
                ],
              ),
            ),
          ],
        ),
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
    _tabController.dispose();
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

// Detail Page (enhanced with nutrition information and favorite button)
class RecipeDetailPage extends StatefulWidget {
  final int recipeId;
  final VoidCallback? onFavoriteToggled;

  RecipeDetailPage({required this.recipeId, this.onFavoriteToggled});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetail;
  final String apiKey = '6cc047ebf7264623b2c64b0ac21c2499';
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    fetchRecipeDetail();
    checkFavoriteStatus();
  }

  Future<void> checkFavoriteStatus() async {
    final result = await FavoritesManager.isFavorite(widget.recipeId);
    setState(() => isFavorite = result);
  }

  // Complete the fetchRecipeDetail() function in the RecipeDetailPage
  Future<void> fetchRecipeDetail() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/${widget
          .recipeId}/information?apiKey=$apiKey&includeNutrition=true',
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

// Add toggleFavorite method to RecipeDetailPage
  Future<void> _toggleFavorite() async {
    if (recipeDetail == null) return;

    // Create a Recipe object from the detail data
    final recipe = Recipe(
      id: recipeDetail!['id'],
      title: recipeDetail!['title'],
      image: recipeDetail!['image'],
      vegetarian: recipeDetail!['vegetarian'] ?? false,
      vegan: recipeDetail!['vegan'] ?? false,
      glutenFree: recipeDetail!['glutenFree'] ?? false,
      dairyFree: recipeDetail!['dairyFree'] ?? false,
      calories: _getCaloriesFromNutrients(
          recipeDetail!['nutrition']?['nutrients']),
    );

    // Toggle the favorite status
    final newStatus = await FavoritesManager.toggleFavorite(recipe);

    setState(() {
      isFavorite = newStatus;
    });

    // Notify parent of the change
    if (widget.onFavoriteToggled != null) {
      widget.onFavoriteToggled!();
    }

    // Show feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite
            ? '${recipe.title} added to favorites'
            : '${recipe.title} removed from favorites'
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

// Helper method to extract calories from nutrients
  int _getCaloriesFromNutrients(List? nutrients) {
    if (nutrients == null) return 0;

    final calorieInfo = nutrients.firstWhere(
          (n) => n['name'] == 'Calories',
      orElse: () => {'amount': 0},
    );

    return calorieInfo['amount'].toInt();
  }

// Complete the build method for RecipeDetailPage to add favorite button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
        actions: [
          // Add favorite button to app bar
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
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
                _buildInfoBadge(
                    '${recipeDetail!['readyInMinutes']} min', Colors.purple),
                _buildInfoBadge(
                    'Serves ${recipeDetail!['servings']}', Colors.teal),
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
                    (ing) =>
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                      (step) =>
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
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

// Methods for building nutrition section (reuse from your existing code)
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
    List<String> keyNutrients = [
      'Calories',
      'Fat',
      'Carbohydrates',
      'Protein',
      'Sugar',
      'Fiber',
      'Cholesterol',
      'Sodium'
    ];

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

  Widget _buildMainNutrientTile(String name, int amount, String unit,
      double percent, Color color) {
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

  Widget _buildNutrientTile(String name, String amount, String unit,
      double percent, Color color) {
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