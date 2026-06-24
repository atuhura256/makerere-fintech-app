import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:makerere_fintech_app/core/security/secure_storage_vault.dart';
import 'package:makerere_fintech_app/features/auth/domain/entities/session_profile.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }

class AuthAuthenticated extends AuthState {
  final SessionProfile profile;
  const AuthAuthenticated(this.profile);
  @override
  List<Object?> get props => [profile.userId];
}

class AuthFailureState extends AuthState {
  final String errorMessage;
  const AuthFailureState(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class AuthSignedOut extends AuthState { const AuthSignedOut(); }

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;
  const LoginSubmitted({required this.identifier, required this.password});
  @override
  List<Object?> get props => [identifier];
}

class CheckAuthSession extends AuthEvent { const CheckAuthSession(); }
class LogoutRequested extends AuthEvent { const LogoutRequested(); }

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<CheckAuthSession>(_onCheckAuthSession);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthSession(CheckAuthSession event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final session = SupabaseService.currentSession;
      final user = session?.user;
      if (user != null) {
        final profile = SessionProfile.fromSupabaseUser(user.toJson(), session!.accessToken);
        await SecureStorageVault.write('session_profile', jsonEncode(profile.toJson()));
        emit(AuthAuthenticated(profile));
        return;
      }
      final saved = await SecureStorageVault.read('session_profile');
      if (saved != null && saved.isNotEmpty) {
        final profile = SessionProfile.fromJson(jsonDecode(saved) as Map<String, dynamic>);
        if (profile.isValid) { emit(AuthAuthenticated(profile)); return; }
      }
      emit(const AuthSignedOut());
    } catch (_) {
      emit(const AuthSignedOut());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await SupabaseService.signInWithPassword(
        email: event.identifier,
        password: event.password,
      );
      final profile = SessionProfile.fromSupabaseUser(
        response.user!.toJson(),
        response.session!.accessToken,
      );
      await SecureStorageVault.write('session_profile', jsonEncode(profile.toJson()));
      await SecureStorageVault.write(SecureStorageVault.kPhoneKey, event.identifier);
      emit(AuthAuthenticated(profile));
    } on Exception catch (e) {
      emit(AuthFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await SupabaseService.signOut();
    await SecureStorageVault.deleteAll();
    emit(const AuthSignedOut());
  }
}
