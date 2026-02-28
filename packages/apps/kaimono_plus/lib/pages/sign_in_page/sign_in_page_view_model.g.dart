// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_page_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignInPageViewModel)
final signInPageViewModelProvider = SignInPageViewModelProvider._();

final class SignInPageViewModelProvider
    extends $NotifierProvider<SignInPageViewModel, SignInState> {
  SignInPageViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInPageViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInPageViewModelHash();

  @$internal
  @override
  SignInPageViewModel create() => SignInPageViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInState>(value),
    );
  }
}

String _$signInPageViewModelHash() =>
    r'02feedad2522380ea981d75f72c00e317281458b';

abstract class _$SignInPageViewModel extends $Notifier<SignInState> {
  SignInState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SignInState, SignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignInState, SignInState>,
              SignInState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
