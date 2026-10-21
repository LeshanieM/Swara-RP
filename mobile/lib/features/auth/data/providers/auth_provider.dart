import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/network/parent_mode.dart';
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
    child: ChildRef(childId: 'CH-001', firstName: 'Amal', age: 7),
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
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  String get role => user?.role ?? '';

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState(isInitialized: false)) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final token = await StorageService.getToken();
      final userData = await StorageService.getString(AppConstants.userKey);
      if (token != null && token.isNotEmpty && userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData)).copyWith(token: token);
        state = AuthState(user: user, isInitialized: true);
        if (!StorageService.isDemoMode()) _refreshUser(user);
        return;
      }
    } catch (_) {}
    state = const AuthState(isInitialized: true);
  }

  /// Picks up account changes (e.g. the child's age) and signs out when the session has expired.
  Future<void> _refreshUser(UserModel saved) async {
    try {
      final response = await _apiClient.get('/api/auth/me');
      final user = UserModel.fromJson(response.data['user']).copyWith(token: saved.token);
      await StorageService.saveString(AppConstants.userKey, jsonEncode(user.toJson()));
      if (mounted && state.user?.id == saved.id) state = AuthState(user: user, isInitialized: true);
    } catch (e) {
      if (ApiException.from(e).isUnauthorized && mounted) await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Demo Mode check
    if (StorageService.isDemoMode()) {
      final demoUser = _demoUsers[email];
      if (demoUser != null) {
        await StorageService.saveToken('demo_token');
        await StorageService.saveString(
            AppConstants.userKey, jsonEncode(demoUser.toJson()));
        state = AuthState(user: demoUser, isInitialized: true);
        return true;
      }
      state =
          state.copyWith(isLoading: false, error: 'Invalid demo credentials');
      return false;
    }

    try {
      final response = await _apiClient.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _saveSession(response.data);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  /// Registers a child account (set up by a parent, who also sets the parent-mode PIN)
  /// or a therapist account (needs the server's therapist code).
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? childFirstName,
    int? childAge,
    String? parentPin,
    String? signupCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    if (StorageService.isDemoMode()) {
      state = state.copyWith(isLoading: false, error: 'Demo mode uses the demo accounts; turn it off to register.');
      return false;
    }
    try {
      final response = await _apiClient.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (role == AppConstants.roleChild) ...{
          'child': {'firstName': childFirstName, 'age': childAge},
          'parentPin': parentPin,
        },
        if (role == AppConstants.roleTherapist) 'signupCode': signupCode,
      });
      await _saveSession(response.data);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  /// Asks the server to start parent mode; the token lives in memory until it expires.
  Future<String?> enterParentMode(String pin) async {
    if (StorageService.isDemoMode()) return null;
    try {
      final response = await _apiClient.post('/api/auth/parent-mode', data: {'pin': pin});
      ParentMode.start(response.data['parentToken'], (response.data['expiresInSec'] as num).toInt());
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final user = UserModel.fromJson(data['user']).copyWith(token: data['token']);
    await StorageService.saveToken(user.token ?? '');
    await StorageService.saveString(AppConstants.userKey, jsonEncode(user.toJson()));
    state = AuthState(user: user, isInitialized: true);
  }

  Future<void> logout() async {
    ParentMode.end();
    await StorageService.removeToken();
    await StorageService.remove(AppConstants.userKey);
    state = const AuthState(isInitialized: true);
  }

  Future<bool> updateProfile({
    required String name,
    String? childFirstName,
    int? childAge,
  }) async {
    final current = state.user;
    if (current == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      UserModel updated;
      if (StorageService.isDemoMode()) {
        updated = current.copyWith(
          name: name.trim(),
          child: current.child == null
              ? null
              : current.child!.copyWith(
                  firstName: childFirstName?.trim(), age: childAge),
        );
      } else {
        final response = await _apiClient.patch('/api/auth/me', data: {
          'name': name.trim(),
          if (current.child != null) ...{
            if (childFirstName != null) 'childFirstName': childFirstName.trim(),
            if (childAge != null) 'childAge': childAge,
          },
        });
        updated = UserModel.fromJson(response.data['user'])
            .copyWith(token: current.token);
      }
      await StorageService.saveString(
          AppConstants.userKey, jsonEncode(updated.toJson()));
      state = AuthState(user: updated, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> updateProfilePhoto(XFile image) async {
    final current = state.user;
    if (current == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bytes = await image.readAsBytes();
      final lowerName = image.name.toLowerCase();
      final mimeType = image.mimeType ??
          (lowerName.endsWith('.png')
              ? 'image/png'
              : lowerName.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      String photoUrl;
      if (StorageService.isDemoMode()) {
        photoUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      } else {
        final form = FormData.fromMap({
          'photo': MultipartFile.fromBytes(
            bytes,
            filename: image.name,
            contentType: MediaType.parse(mimeType),
          ),
        });
        final response = await _apiClient.postMultipart('/api/profile/photo', form);
        photoUrl = response.data['photoUrl'] as String;
      }
      final updated = current.copyWith(photoUrl: photoUrl);
      await StorageService.saveString(AppConstants.userKey, jsonEncode(updated.toJson()));
      state = AuthState(user: updated, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(Object e) {
    final error = ApiException.from(e);
    if (error.code == 'validation_error') return 'Please check the details and try again.';
    return error.message;
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
