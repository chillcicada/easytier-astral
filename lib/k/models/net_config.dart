import 'dart:io';

import 'package:isar/isar.dart';
part 'net_config.g.dart';

@collection
class NetConfig {
  /// 主键ID，固定为1因为只需要一个实例
  Id id = 1;

  String netns = ''; // 网络命名空间

  String hostname = Platform.localHostname; // 主机名

  String instance_name = 'default'; // 实例名称

  String ipv4 = ''; // IPv4地址

  bool dhcp = false; // 是否使用DHCP
  String network_name = ''; // 网络名称
  String network_secret = ''; // 网络密钥

  List<String> listeners = []; // 监听端口

  List<String> peer = []; // 服务器节点地址

  String default_protocol = '';

  String dev_name = '';

  bool enable_encryption = true;

  bool enable_ipv6 = true;

  int mtu = 1400;

  bool latency_first = false;

  bool enable_exit_node = false;

  bool no_tun = false;

  bool use_smoltcp = false;

  String relay_network_whitelist = '';

  bool disable_p2p = false;

  bool relay_all_peer_rpc = false;

  bool disable_udp_hole_punching = false;

  bool multi_thread = true;

  int data_compress_algo = 0;

  bool bind_device = false;

  bool enable_kcp_proxy = false;

  bool disable_kcp_input = false;

  bool disable_relay_kcp = false;

  bool proxy_forward_by_system = false;
}
