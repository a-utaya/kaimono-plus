// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_page_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignUpPageViewModel)
final signUpPageViewModelProvider = SignUpPageViewModelProvider._();

final class SignUpPageViewModelProvider
    extends $NotifierProvider<SignUpPageViewModel, SignUpState> {
  SignUpPageViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpPageViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpPageViewModelHash();

  @$internal
  @override
  SignUpPageViewModel create() => SignUpPageViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpState>(value),
    );
  }
}

String _$signUpPageViewModelHash() =>
    r'03584d6700be648ed2e1dea112331cc251eeef71';

abstract class _$SignUpPageViewModel extends $Notifier<SignUpState> {
  SignUpState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SignUpState, SignUpState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignUpState, SignUpState>,
              SignUpState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
