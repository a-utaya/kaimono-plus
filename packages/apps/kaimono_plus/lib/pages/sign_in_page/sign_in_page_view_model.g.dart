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
    extends $AsyncNotifierProvider<SignInPageViewModel, void> {
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
}

String _$signInPageViewModelHash() =>
    r'7a7f09a15e283dcefaaea8fc7b602ca344f28804';

abstract class _$SignInPageViewModel extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
