import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/authenticator_provider.dart';

part 'sign_in_page_view_model.g.dart';

/// サインイン画面の状態
@immutable
class SignInState extends Equatable {
  const SignInState({this.isLoading = false});

  final bool isLoading;

  @override
  List<Object?> get props => [isLoading];

  SignInState copyWith({bool? isLoading}) =>
      SignInState(isLoading: isLoading ?? this.isLoading);
}

@riverpod
class SignInPageViewModel extends _$SignInPageViewModel {
  @override
  SignInState build() => const SignInState();

  /// サインインを実行する。
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await ref
          .read(authenticatorProvider)
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
