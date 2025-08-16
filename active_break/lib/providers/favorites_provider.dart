import 'package:flutter/material.dart';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';

class FavoritesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<UserTip> _favorites = [];
  bool _isLoading = false;
  Map<int, bool> _favoriteStatus = {};
  
  List<UserTip> get favorites => _favorites;
  bool get isLoading => _isLoading;
  
  bool isFavorite(int tipId) {
    return _favoriteStatus[tipId] ?? false;
  }
  
  Future<void> loadFavorites(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _favorites = await _databaseService.getUserFavorites(userId);
      // Update favorite status map
      _favoriteStatus.clear();
      for (final tip in _favorites) {
        if (tip.tipId != null) {
          _favoriteStatus[tip.tipId!] = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadFavoriteStatus(int userId, List<UserTip> tips) async {
    try {
      for (final tip in tips) {
        if (tip.tipId != null) {
          final isFav = await _databaseService.isFavorite(userId, tip.tipId!);
          _favoriteStatus[tip.tipId!] = isFav;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorite status: $e');
    }
  }
  
  Future<void> toggleFavorite(int userId, UserTip tip) async {
    if (tip.tipId == null) return;
    
    try {
      final isCurrentlyFavorite = _favoriteStatus[tip.tipId!] ?? false;
      
      if (isCurrentlyFavorite) {
        await _databaseService.removeFromFavorites(userId, tip.tipId!);
        _favoriteStatus[tip.tipId!] = false;
        _favorites.removeWhere((fav) => fav.tipId == tip.tipId);
      } else {
        await _databaseService.addToFavorites(userId, tip.tipId!);
        _favoriteStatus[tip.tipId!] = true;
        _favorites.insert(0, tip); // Add to beginning of list
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }
  
  void clearFavorites() {
    _favorites.clear();
    _favoriteStatus.clear();
    notifyListeners();
  }
}