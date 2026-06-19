import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../domain/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final String? email;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.errorMessage,
    this.email,
  });

  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      email: email ?? this.email,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((isAdminLoggedIn) async {
      if (isAdminLoggedIn) {
        final email = await _authRepository.getCurrentUserEmail();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          email: email,
        );
      } else {
        state = AuthState.initial();
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _authRepository.login(email, password);
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check your credentials.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.logout();
    state = AuthState.initial();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
