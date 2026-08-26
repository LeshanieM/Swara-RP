import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/core/constants/app_constants.dart';

// Demo users for demo mode
final _demoUsers = {
  'parent@demo.com': UserModel(
    id: 'demo_parent_1',
    name: 'Demo Parent',
    email: 'parent@demo.com',
    role: AppConstants.roleParent,
    token: 'demo_token',
  ),
  'therapist@demo.com': UserModel(
    id: 'demo_therapist_1',
    name: 'Dr. Demo Therapist',
    email: 'therapist@demo.com',
    role: AppConstants.roleTherapist,
    token: 'demo_token',
  ),
};

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  String get role => user?.role ?? '';

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final token = await StorageService.getToken();
    final userData = await StorageService.getString(AppConstants.userKey);
    if (token != null && userData != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userData));
        state = AuthState(user: user);
      } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Demo Mode check
    if (StorageService.isDemoMode()) {
      final demoUser = _demoUsers[email];
      if (demoUser != null) {
        await StorageService.saveToken('demo_token');
        await StorageService.saveString(AppConstants.userKey, jsonEncode(demoUser.toJson()));
        state = AuthState(user: demoUser);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Invalid demo credentials');
      return false;
    }

    try {
      final response = await _apiClient.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      final user = UserModel.fromJson(data);
      await StorageService.saveToken(user.token ?? '');
      await StorageService.saveString(AppConstants.userKey, jsonEncode(user.toJson()));
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      final data = response.data;
      final user = UserModel.fromJson(data);
      await StorageService.saveToken(user.token ?? '');
      await StorageService.saveString(AppConstants.userKey, jsonEncode(user.toJson()));
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    await StorageService.remove(AppConstants.userKey);
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
