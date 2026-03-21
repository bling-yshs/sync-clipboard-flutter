// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerConfigNotifier)
const serverConfigProvider = ServerConfigNotifierProvider._();

final class ServerConfigNotifierProvider
    extends $AsyncNotifierProvider<ServerConfigNotifier, ServerConfigState> {
  const ServerConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverConfigNotifierHash();

  @$internal
  @override
  ServerConfigNotifier create() => ServerConfigNotifier();
}

String _$serverConfigNotifierHash() =>
    r'44bc5bf61a481c276b74555a9080cbc82a8a40d1';

abstract class _$ServerConfigNotifier
    extends $AsyncNotifier<ServerConfigState> {
  FutureOr<ServerConfigState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<ServerConfigState>, ServerConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerConfigState>, ServerConfigState>,
              AsyncValue<ServerConfigState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
