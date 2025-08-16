import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  final DatabaseService _databaseService = DatabaseService();

  UserProvider() {
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    print('=== UserProvider: 开始加载用户会话 ===');
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    print('UserProvider: SharedPreferences中的登录状态: $_isLoggedIn');

    if (_isLoggedIn) {
      final userId = prefs.getInt(_userIdKey);
      print('UserProvider: SharedPreferences中的用户ID: $userId');
      if (userId != null) {
        _currentUser = await _databaseService.getUserById(userId);
        print('UserProvider: 从数据库获取的用户: $_currentUser');
        if (_currentUser == null) {
          // User not found, clear session
          print('UserProvider: 用户未找到，清除会话');
          await logout();
        } else {
          print('UserProvider: 用户登录成功，用户名: ${_currentUser!.username}');
        }
      }
    } else {
      print('UserProvider: 用户未登录');
    }
    print('UserProvider: 最终登录状态: $_isLoggedIn, 当前用户: $_currentUser');
    notifyListeners();
    print('UserProvider: notifyListeners() 已调用，UI应该重新构建');
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> register({
    required String username,
    required String password,
    required String email,
    String? phone,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user already exists
      print('Checking if email exists: $email');
      final existingUserByEmail = await _databaseService.getUserByEmail(email);
      print('Existing user by email: $existingUserByEmail');
      if (existingUserByEmail != null) {
        print('Email already exists');
        _isLoading = false;
        notifyListeners();
        return false; // Email already exists
      }

      print('Checking if username exists: $username');
      final existingUserByUsername = await _databaseService.getUserByUsername(
        username,
      );
      print('Existing user by username: $existingUserByUsername');
      if (existingUserByUsername != null) {
        print('Username already exists');
        _isLoading = false;
        notifyListeners();
        return false; // Username already exists
      }

      // Create new user
      final hashedPassword = _hashPassword(password);
      final newUser = User(
        username: username,
        passwordHash: hashedPassword,
        email: email,
        phone: phone,
        gender: gender,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userId = await _databaseService.insertUser(newUser);
      _currentUser = newUser.copyWith(userId: userId);
      _isLoggedIn = true;

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, userId);
      await prefs.setBool(_isLoggedInKey, true);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final hashedPassword = _hashPassword(password);

      // Try to find user by email first, then by username
      User? user = await _databaseService.getUserByEmail(emailOrUsername);
      user ??= await _databaseService.getUserByUsername(emailOrUsername);

      if (user != null && user.passwordHash == hashedPassword) {
        _currentUser = user.copyWith(
          lastLoginTime: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Update last login time
        await _databaseService.updateUser(_currentUser!);

        _isLoggedIn = true;

        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userIdKey, user.userId!);
        await prefs.setBool(_isLoggedInKey, true);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false; // Invalid credentials
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.setBool(_isLoggedInKey, false);

    notifyListeners();
  }

  Future<bool> updateProfile({
    String? username,
    String? phone,
    String? gender,
    String? avatarUrl,
    DateTime? birthday,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        username: username ?? _currentUser!.username,
        phone: phone ?? _currentUser!.phone,
        gender: gender ?? _currentUser!.gender,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
        birthday: birthday ?? _currentUser!.birthday,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    final currentHashedPassword = _hashPassword(currentPassword);
    if (_currentUser!.passwordHash != currentHashedPassword) {
      return false; // Current password is incorrect
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newHashedPassword = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(
        passwordHash: newHashedPassword,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
