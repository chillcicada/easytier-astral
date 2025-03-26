// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerConfig _$ServerConfigFromJson(Map<String, dynamic> json) => ServerConfig(
      url: json['url'] as String,
      name: json['name'] as String,
      selected: json['selected'] as bool? ?? false,
      tcp: json['tcp'] as bool? ?? true,
      udp: json['udp'] as bool? ?? true,
      ws: json['ws'] as bool? ?? false,
      wss: json['wss'] as bool? ?? false,
      quic: json['quic'] as bool? ?? false,
    );

Map<String, dynamic> _$ServerConfigToJson(ServerConfig instance) =>
    <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
      'selected': instance.selected,
      'tcp': instance.tcp,
      'udp': instance.udp,
      'ws': instance.ws,
      'wss': instance.wss,
      'quic': instance.quic,
    };

ConfigModel _$ConfigModelFromJson(Map<String, dynamic> json) => ConfigModel(
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      seedColor: json['seedColor'] == null
          ? const Color(0xFF2196F3)
          : const ColorConverter().fromJson((json['seedColor'] as num).toInt()),
      defaultProtocol: json['defaultProtocol'] as String? ?? "tcp",
      devName: json['devName'] as String? ?? "",
      enableEncryption: json['enableEncryption'] as bool? ?? true,
      enableIpv6: json['enableIpv6'] as bool? ?? true,
      mtu: (json['mtu'] as num?)?.toInt() ?? 1360,
      latencyFirst: json['latencyFirst'] as bool? ?? true,
      enableExitNode: json['enableExitNode'] as bool? ?? false,
      proxyForwardBySystem: json['proxyForwardBySystem'] as bool? ?? false,
      noTun: json['noTun'] as bool? ?? false,
      useSmoltcp: json['useSmoltcp'] as bool? ?? false,
      relayNetworkWhitelist: json['relayNetworkWhitelist'] as String? ?? "*",
      disableP2p: json['disableP2p'] as bool? ?? false,
      relayAllPeerRpc: json['relayAllPeerRpc'] as bool? ?? false,
      disableUdpHolePunching: json['disableUdpHolePunching'] as bool? ?? false,
      multiThread: json['multiThread'] as bool? ?? true,
      dataCompressAlgo: json['dataCompressAlgo'] as String? ?? "None",
      bindDevice: json['bindDevice'] as bool? ?? true,
      enableKcpProxy: json['enableKcpProxy'] as bool? ?? false,
      disableKcpInput: json['disableKcpInput'] as bool? ?? false,
      disableRelayKcp: json['disableRelayKcp'] as bool? ?? true,
      servers: (json['servers'] as List<dynamic>?)
              ?.map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            ServerConfig(
                url: 'public.easytier.cn:11010',
                name: '公共服务器',
                selected: true,
                tcp: true,
                udp: true,
                ws: false,
                wss: false,
                quic: false)
          ],
    );

Map<String, dynamic> _$ConfigModelToJson(ConfigModel instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'seedColor': const ColorConverter().toJson(instance.seedColor),
      'defaultProtocol': instance.defaultProtocol,
      'devName': instance.devName,
      'enableEncryption': instance.enableEncryption,
      'enableIpv6': instance.enableIpv6,
      'mtu': instance.mtu,
      'latencyFirst': instance.latencyFirst,
      'enableExitNode': instance.enableExitNode,
      'proxyForwardBySystem': instance.proxyForwardBySystem,
      'noTun': instance.noTun,
      'useSmoltcp': instance.useSmoltcp,
      'relayNetworkWhitelist': instance.relayNetworkWhitelist,
      'disableP2p': instance.disableP2p,
      'relayAllPeerRpc': instance.relayAllPeerRpc,
      'disableUdpHolePunching': instance.disableUdpHolePunching,
      'multiThread': instance.multiThread,
      'dataCompressAlgo': instance.dataCompressAlgo,
      'bindDevice': instance.bindDevice,
      'enableKcpProxy': instance.enableKcpProxy,
      'disableKcpInput': instance.disableKcpInput,
      'disableRelayKcp': instance.disableRelayKcp,
      'servers': instance.servers,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
