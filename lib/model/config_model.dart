import 'package:astral/sys/config_core.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

// 添加 Color 类型的 JsonConverter
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) => color.toARGB32();
}

@JsonSerializable()
class ServerConfig {
  final String url;
  final String name;
  final int ms;
  final bool selected;
  final bool tcp;
  final bool udp;
  final bool ws;
  final bool wss;
  final bool quic;

  const ServerConfig({
    required this.url,
    required this.name,
    this.ms = 0,
    this.selected = false,
    this.tcp = true,
    this.udp = true,
    this.ws = false,
    this.wss = false,
    this.quic = false,
  });
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ServerConfigToJson(this);
}

// 配置模型类 - 保持原有结构
@JsonSerializable()
class ConfigModel implements BaseConfigModel {
  @override
  String get configKey => 'config';
  final bool closeToTray; // 添加关闭进入托盘变量
  final bool pingEnabled; // 添加全局ping开关
  final ThemeMode themeMode;
  @ColorConverter() // 使用 ColorConverter
  final Color seedColor;
  final String defaultProtocol;
  final String devName;
  final bool enableEncryption;
  final bool enableIpv6;
  final int mtu;
  final bool latencyFirst;
  final bool enableExitNode;
  final bool proxyForwardBySystem;
  final bool noTun;
  final bool useSmoltcp;
  final String relayNetworkWhitelist;
  final bool disableP2p;
  final bool relayAllPeerRpc;
  final bool disableUdpHolePunching;
  final bool multiThread;
  final String dataCompressAlgo;
  final bool bindDevice;
  final bool enableKcpProxy;
  final bool disableKcpInput;
  final bool disableRelayKcp;
  final List<ServerConfig> servers;

  const ConfigModel({
    this.closeToTray = false,
    this.pingEnabled = true,
    this.themeMode = ThemeMode.system,
    this.seedColor = const Color(0xFF2196F3),
    this.defaultProtocol = "tcp",
    this.devName = "",
    this.enableEncryption = true,
    this.enableIpv6 = true,
    this.mtu = 1360,
    this.latencyFirst = true,
    this.enableExitNode = false,
    this.proxyForwardBySystem = false,
    this.noTun = false,
    this.useSmoltcp = false,
    this.relayNetworkWhitelist = "*",
    this.disableP2p = false,
    this.relayAllPeerRpc = false,
    this.disableUdpHolePunching = false,
    this.multiThread = true,
    this.dataCompressAlgo = "None",
    this.bindDevice = true,
    this.enableKcpProxy = false,
    this.disableKcpInput = false,
    this.disableRelayKcp = true,
    this.servers = const [
      ServerConfig(
        url: 'public.easytier.cn:11010',
        name: '公共服务器',
        selected: true,
        tcp: true,
        udp: true,
        ws: false,
        wss: false,
        quic: false,
      ),
    ],
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ConfigModelFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);
}
