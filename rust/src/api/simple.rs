use easytier::common::config::PortForwardConfig;
pub use easytier::{
    common::{
        self,
        config::{ConfigLoader, NetworkIdentity, PeerConfig, TomlConfigLoader},
        global_ctx::{EventBusSubscriber, GlobalCtxEvent},
    },
    launcher::NetworkInstance,
    proto,
    proto::{
        cli::{
            list_peer_route_pair, ConnectorManageRpc, ConnectorManageRpcClientFactory,
            DumpRouteRequest, GetVpnPortalInfoRequest, ListConnectorRequest,
            ListForeignNetworkRequest, ListGlobalForeignNetworkRequest, ListPeerRequest,
            ListPeerResponse, ListRouteRequest, ListRouteResponse, NodeInfo, PeerInfo,
            PeerManageRpc, PeerManageRpcClientFactory, PeerRoutePair, Route, ShowNodeInfoRequest,
            TcpProxyEntryState, TcpProxyEntryTransportType, TcpProxyRpc, TcpProxyRpcClientFactory,
            VpnPortalRpc, VpnPortalRpcClientFactory,
        },
        common::NatType,
        peer_rpc::{GetGlobalPeerMapRequest, PeerCenterRpc, PeerCenterRpcClientFactory},
        rpc_impl::standalone::StandAloneClient,
        rpc_types::controller::BaseController,
        web::MyNodeInfo,
    },
    utils::cost_to_str,
};
use lazy_static::lazy_static;
use serde_json::json;
pub use std::collections::BTreeMap;
use std::{collections::HashMap, future, sync::Mutex};
use tokio::runtime::Runtime;
pub use tokio::task::JoinHandle;
use tokio::time::interval;
use std::env;
use std::io::{self, Write};

use crate::api::{astral_wfp::{Direction, FilterAction, FilterRule, WfpController}, nt::get_nt_path};

static INSTANCE: Mutex<Option<NetworkInstance>> = Mutex::new(None);
// 创建一个 NetworkInstance 类型变量 储存当前服务器
lazy_static! {
    static ref RT: Runtime = Runtime::new().expect("创建 Tokio 运行时失败");
    static ref RT2: Runtime = Runtime::new().expect("创建 Tokio 运行时失败");
}


fn peer_conn_info_to_string(p: proto::cli::PeerConnInfo) -> String {
    format!(
        "my_peer_id: {}, dst_peer_id: {}, tunnel_info: {:?}",
        p.my_peer_id, p.peer_id, p.tunnel
    )
}

pub fn send_udp_to_localhost(message: &str) -> Result<(), String> {
    use std::net::UdpSocket;

    let socket = match UdpSocket::bind("0.0.0.0:0") {
        Ok(s) => s,
        Err(e) => return Err(format!("绑定UDP套接字失败: {}", e)),
    };

    match socket.send_to(message.as_bytes(), "127.0.0.1:9999") {
        Ok(_) => Ok(()),
        Err(e) => Err(format!("发送UDP数据失败: {}", e)),
    }
}

pub fn handle_event(mut events: EventBusSubscriber) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        loop {
            match events.recv().await {
                Ok(e) => {
                    //  println!("Received event: {:?}", e);
                    match e {
                        GlobalCtxEvent::PeerAdded(p) => {
                                                println!("{}", format!("新节点已添加。节点ID: {}", p));
                                                let _ = send_udp_to_localhost(&format!("新节点已添加。节点ID: {}", p));
                                            }
                        GlobalCtxEvent::PeerRemoved(p) => {
                                                println!("{}", format!("节点已移除。节点ID: {}", p));
                                                let _ = send_udp_to_localhost(&format!("节点已移除。节点ID: {}", p));
                                            }
                        GlobalCtxEvent::PeerConnAdded(p) => {
                                                let conn_info = peer_conn_info_to_string(p);
                                                let msg = format!("新节点连接已添加。连接信息: {}", conn_info);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::PeerConnRemoved(p) => {
                                                let msg = format!(
                                                    "节点连接已移除。连接信息: {}",
                                                    peer_conn_info_to_string(p)
                                                );
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ListenerAddFailed(p, msg) => {
                                                let msg = format!("监听器添加失败。监听器: {}, 消息: {}", p, msg);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ListenerAcceptFailed(p, msg) => {
                                                let msg = format!("监听器接受失败。监听器: {}, 消息: {}", p, msg);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ListenerAdded(p) => {
                                                if p.scheme() == "ring" {
                                                    continue;
                                                }
                                                let msg = format!("新监听器已添加。监听器: {}", p);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ConnectionAccepted(local, remote) => {
                                                let msg = format!("新连接已接受。本地: {}, 远程: {}", local, remote);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ConnectionError(local, remote, err) => {
                                                let msg = format!(
                                                    "连接错误。本地: {}, 远程: {}, 错误: {}",
                                                    local, remote, err
                                                );
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::TunDeviceReady(dev) => {
                                                let msg = format!("TUN 设备就绪。设备: {}", dev);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::TunDeviceError(err) => {
                                                let msg = format!("TUN 设备错误。错误: {}", err);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::Connecting(dst) => {
                                                let msg = format!("正在连接到节点。目标: {}", dst);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::ConnectError(dst, ip_version, err) => {
                                                let msg = format!(
                                                    "连接到节点错误。目标: {}, IP版本: {}, 错误: {}",
                                                    dst, ip_version, err
                                                );
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::VpnPortalClientConnected(portal, client_addr) => {
                                                let msg = format!(
                                                    "VPN 门户客户端已连接。门户: {}, 客户端地址: {}",
                                                    portal, client_addr
                                                );
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::VpnPortalClientDisconnected(portal, client_addr) => {
                                                let msg = format!(
                                                    "VPN 门户客户端已断开连接。门户: {}, 客户端地址: {}",
                                                    portal, client_addr
                                                );
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::DhcpIpv4Changed(old, new) => {
                                                let msg = format!("DHCP IP 已更改。旧: {:?}, 新: {:?}", old, new);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
                        GlobalCtxEvent::DhcpIpv4Conflicted(ip) => {
                                                let msg = format!("DHCP IP 冲突。IP: {:?}", ip);
                                                println!("{}", msg);
                                                let _ = send_udp_to_localhost(&msg);
                                            }
GlobalCtxEvent::PortForwardAdded(port_forward_config_pb) => {
    let msg = format!("端口转发已添加。配置: {:?}", port_forward_config_pb);
    println!("{}", msg);
    let _ = send_udp_to_localhost(&msg);
},
                                            }
                }
                Err(err) => {
                    eprintln!("接收事件错误: {:?}", err);
                    // 根据错误类型决定是否中断循环
                    match err {
                        tokio::sync::broadcast::error::RecvError::Closed => {
                            let msg = "事件通道已关闭，停止事件处理。";
                            println!("{}", msg);
                            let _ = send_udp_to_localhost(msg);
                            break; // Exit the loop if the channel is closed
                        }
                        tokio::sync::broadcast::error::RecvError::Lagged(n) => {
                            let msg = format!("事件处理滞后，丢失了 {} 个事件。", n);
                            eprintln!("{}", msg);
                            let _ = send_udp_to_localhost(&msg);
                            // Decide if lagging is critical enough to break or just log
                        }
                    }
                }
            }
        }
    })
}

async fn create_and_store_network_instance(cfg: TomlConfigLoader) -> Result<(), String> {
    println!("{:?}", cfg);

    // 在移动 cfg 之前先获取 ID
    let name = cfg.get_id().to_string();
    // 创建网络实例
    let mut network = NetworkInstance::new(cfg).set_fetch_node_info(true);
    // 启动网络实例，并处理可能的错误
    handle_event(network.start().unwrap());
    println!("instance {} started", name);
    // 将实例存储到 INSTANCE 中
    let mut instance_guard = INSTANCE
        .lock()
        .map_err(|e| format!("获取互斥锁失败: {}", e))?;
    if instance_guard.is_none() {
        *instance_guard = Some(network);
        println!("实例已成功储存");
    } else {
        println!("网络实例已存在");
    }
    print!("成功储存");

    Ok(())
}



// 返回EasyTier的版本号
pub fn easytier_version() -> Result<String, String> {
    Ok(easytier::VERSION.to_string())
}

// 是否在运行
pub fn is_easytier_running() -> bool {
    let instance = INSTANCE.lock().unwrap();
    instance.is_some()
}
// 定义节点跳跃统计信息结构体
pub struct NodeHopStats {
    pub target_ip: String, // 目标节点IP
    pub latency_ms: f64,   // 延迟(毫秒)
    pub packet_loss: f32,  // 丢包率
    pub node_name: String, // 节点名称
}

// 定义节点连接统计信息结构体
pub struct KVNodeConnectionStats {
    pub conn_type: String, // 连接类型
    pub rx_bytes: u64,
    pub tx_bytes: u64,
    pub rx_packets: u64,
    pub tx_packets: u64,
}
// 定义节点信息结构体
pub struct KVNodeInfo {
    pub hostname: String,
    pub ipv4: String,
    pub latency_ms: f64,
    pub nat: String, // NAT类型
    // NodeHopStats 列表 从近到远
    pub hops: Vec<NodeHopStats>,
    pub loss_rate: f32,
    pub connections: Vec<KVNodeConnectionStats>,

    pub tunnel_proto: String,
    pub conn_type: String, // 连接类型
    pub rx_bytes: u64,
    pub tx_bytes: u64,

    pub version: String,
    pub cost: i32,
}
// 定义节点网络状态结构体
pub struct KVNetworkStatus {
    pub total_nodes: usize,
    pub nodes: Vec<KVNodeInfo>,
}

// 获取网络中所有节点的IP地址列表
pub fn get_ips() -> Vec<String> {
    let mut result = Vec::new();

    // Lock the mutex and access the instance if it exists
    let instance = INSTANCE.lock().unwrap();

    if let Some(instance) = instance.as_ref() {
        if let Some(info) = instance.get_running_info() {
            // Add all remote node IPs
            for route in &info.routes {
                if let Some(ipv4_addr) = &route.ipv4_addr {
                    if let Some(addr) = &ipv4_addr.address {
                        let ip = format!(
                            "{}.{}.{}.{}/{}",
                            (addr.addr >> 24) & 0xFF,
                            (addr.addr >> 16) & 0xFF,
                            (addr.addr >> 8) & 0xFF,
                            addr.addr & 0xFF,
                            ipv4_addr.network_length
                        );
                        // Avoid duplicates
                        if !result.contains(&ip) {
                            result.push(ip);
                        }
                    }
                }
            }
        }
    }
    result
}

// 设置TUN设备的文件描述符
pub fn set_tun_fd(fd: i32) -> Result<(), String> {
    let mut instance = INSTANCE.lock().unwrap();
    if let Some(instance) = instance.as_mut() {
        instance.set_tun_fd(fd);
        Ok(())
    } else {
        Err("No instance available".to_string())
    }
}

pub fn get_running_info() -> String {
    INSTANCE
        .lock()
        .unwrap()
        .as_ref()
        .and_then(|instance| instance.get_running_info())
        .and_then(|info| {
            // 获取并打印节点路由对信息
            serde_json::to_string(&json!({
                "dev_name": info.dev_name,
                "my_node_info": info.my_node_info.as_ref().map(|node| json!({
                    "virtual_ipv4": node.virtual_ipv4.as_ref().map(|addr| json!({
                        "address": addr.address.as_ref().map(|a| json!({ "addr": a.addr })),
                        "network_length": addr.network_length
                    })),
                    "hostname": node.hostname,
                    "version": node.version,
                    "ips": node.ips.as_ref().map(|ips| json!({
                        "public_ipv4": ips.public_ipv4.as_ref().map(|a| json!({ "addr": a.addr })),
                        "interface_ipv4s": ips.interface_ipv4s.iter().map(|a| json!({ "addr": a.addr })).collect::<Vec<_>>(),
                        "public_ipv6": ips.public_ipv6.as_ref().map(|a| json!({
                            "part1": a.part1,
                            "part2": a.part2,
                            "part3": a.part3,
                            "part4": a.part4
                        })),
                        "interface_ipv6s": ips.interface_ipv6s.iter().map(|a| json!({
                            "part1": a.part1,
                            "part2": a.part2,
                            "part3": a.part3,
                            "part4": a.part4
                        })).collect::<Vec<_>>(),
                        "listeners": ips.listeners.iter().map(|l| json!({ "url": l.to_string() })).collect::<Vec<_>>()
                    })),
                    "stun_info": node.stun_info.as_ref().map(|info| json!({
                        "udp_nat_type": info.udp_nat_type,
                        "tcp_nat_type": info.tcp_nat_type,
                        "last_update_time": info.last_update_time,
                        "public_ip": info.public_ip,
                        "min_port": info.min_port,
                        "max_port": info.max_port
                    })),
                    "listeners": node.listeners.iter().map(|l| json!({ "url": l.url })).collect::<Vec<_>>(),
                    "vpn_portal_cfg": node.vpn_portal_cfg
                })),
                "events": info.events,
                "routes": info.routes.iter().map(|route| json!({
                    "peer_id": route.peer_id,
                    "ipv4_addr": route.ipv4_addr.as_ref().map(|addr| json!({
                        "address": addr.address.as_ref().map(|a| json!({ "addr": a.addr })),
                        "network_length": addr.network_length
                    })),
                    "next_hop_peer_id": route.next_hop_peer_id,
                    "cost": route.cost,
                    "path_latency": route.path_latency,
                    "proxy_cidrs": route.proxy_cidrs,
                    "hostname": route.hostname,
                    "stun_info": route.stun_info.as_ref().map(|info| json!({
                        "udp_nat_type": info.udp_nat_type,
                        "tcp_nat_type": info.tcp_nat_type,
                        "last_update_time": info.last_update_time,
                        "public_ip": info.public_ip,
                        "min_port": info.min_port,
                        "max_port": info.max_port
                    })),
                    "inst_id": route.inst_id,
                    "version": route.version,
                    "feature_flag": route.feature_flag.as_ref().map(|flag| json!({
                        "is_public_server": flag.is_public_server,
                        "avoid_relay_data": flag.avoid_relay_data,
                        "kcp_input": flag.kcp_input,
                        "no_relay_kcp": flag.no_relay_kcp
                    })),
                    "next_hop_peer_id_latency_first": route.next_hop_peer_id_latency_first,
                    "cost_latency_first": route.cost_latency_first,
                    "path_latency_latency_first": route.path_latency_latency_first ,
                })).collect::<Vec<_>>(),
                "peers": info.peers.iter().map(|peer| 
                     json!({
                    "peer_id": peer.peer_id,
                    "conns": peer.conns.iter().map(|conn| json!({
                        "conn_id": conn.conn_id,
                        "my_peer_id": conn.my_peer_id,
                        "peer_id": conn.peer_id,
                        "features": conn.features,
                        "tunnel": conn.tunnel.as_ref().map(|t| json!({
                            "tunnel_type": t.tunnel_type,
                            "local_addr": t.local_addr.as_ref().map(|a| json!({ "url": a.url })),
                            "remote_addr": t.remote_addr.as_ref().map(|a| json!({ "url": a.url }))
                        })),
                        "stats": conn.stats.as_ref().map(|s| json!({
                            "rx_bytes": s.rx_bytes,
                            "tx_bytes": s.tx_bytes,
                            "rx_packets": s.rx_packets,
                            "tx_packets": s.tx_packets,
                            "latency_us": s.latency_us
                        })),
                        "loss_rate": conn.loss_rate,
                        "is_client": conn.is_client,
                        "network_name": conn.network_name
                    })).collect::<Vec<_>>()
                })).collect::<Vec<_>>(),
                "peer_route_pairs": info.peer_route_pairs.iter().map(|pair| json!({
                    "route": pair.route.as_ref().map(|route| json!({
                        "peer_id": route.peer_id,
                        "ipv4_addr": route.ipv4_addr.as_ref().map(|addr| json!({
                            "address": addr.address.as_ref().map(|a| json!({ "addr": a.addr })),
                            "network_length": addr.network_length
                        })),
                        "next_hop_peer_id": route.next_hop_peer_id,
                        "cost": route.cost,
                        "path_latency": route.path_latency,
                        "proxy_cidrs": route.proxy_cidrs,
                        "hostname": route.hostname,
                        "stun_info": route.stun_info.as_ref().map(|info| json!({
                            "udp_nat_type": info.udp_nat_type,
                            "tcp_nat_type": info.tcp_nat_type,
                            "last_update_time": info.last_update_time,
                            "public_ip": info.public_ip,
                            "min_port": info.min_port,
                            "max_port": info.max_port
                        })),
                        "inst_id": route.inst_id,
                        "version": route.version,
                        "feature_flag": route.feature_flag.as_ref().map(|flag| json!({
                            "is_public_server": flag.is_public_server,
                            "avoid_relay_data": flag.avoid_relay_data,
                            "kcp_input": flag.kcp_input,
                            "no_relay_kcp": flag.no_relay_kcp
                        })),
                        "next_hop_peer_id_latency_first": route.next_hop_peer_id_latency_first,
                        "cost_latency_first": route.cost_latency_first,
                        "path_latency_latency_first": route.path_latency_latency_first
                    })),
                    "peer": pair.peer.as_ref().map(|peer| json!({
                        "peer_id": peer.peer_id,
                        "conns": peer.conns.iter().map(|conn| json!({
                            "conn_id": conn.conn_id,
                            "my_peer_id": conn.my_peer_id,
                            "peer_id": conn.peer_id,
                            "features": conn.features,
                            "tunnel": conn.tunnel.as_ref().map(|t| json!({
                                "tunnel_type": t.tunnel_type,
                                "local_addr": t.local_addr.as_ref().map(|a| json!({ "url": a.url })),
                                "remote_addr": t.remote_addr.as_ref().map(|a| json!({ "url": a.url }))
                            })),
                            "stats": conn.stats.as_ref().map(|s| json!({
                                "rx_bytes": s.rx_bytes,
                                "tx_bytes": s.tx_bytes,
                                "rx_packets": s.rx_packets,
                                "tx_packets": s.tx_packets,
                                "latency_us": s.latency_us
                            })),
                            "loss_rate": conn.loss_rate,
                            "is_client": conn.is_client,
                            "network_name": conn.network_name
                        })).collect::<Vec<_>>()
                    }))
                })).collect::<Vec<_>>(),

                "running": info.running,
                "error_msg": info.error_msg
            })).ok()
        })
        .unwrap_or_else(|| "{}".to_string())
}

pub struct FlagsC {
    pub default_protocol: String,
    pub dev_name: String,
    pub enable_encryption: bool,
    pub enable_ipv6: bool,
    pub mtu: u32,
    pub latency_first: bool,
    pub enable_exit_node: bool,
    pub no_tun: bool,
    pub use_smoltcp: bool,
    pub relay_network_whitelist: String,
    pub disable_p2p: bool,
    pub relay_all_peer_rpc: bool,
    pub disable_udp_hole_punching: bool,
    pub multi_thread: bool,
    pub data_compress_algo: i32,
    pub bind_device: bool,
    pub enable_kcp_proxy: bool,
    pub disable_kcp_input: bool,
    pub disable_relay_kcp: bool,
    pub proxy_forward_by_system: bool,
    pub accept_dns: bool,
}

pub struct Forward{
    pub bind_addr: String,
    pub dst_addr: String,
    pub proto:String
}



pub fn add_advanced_network_filter_async()-> JoinHandle<Result<(), String>>{
    RT2.spawn(async move {

    let path = r"C:\program files (x86)\microsoft\edge\application\msedge.exe";
        let nt_path = match get_nt_path(path) {
            Some(path) => path,
            None => {
                eprintln!("转换失败");
                return Ok(());
            }
        };

        let nt_path: &'static str = Box::leak(nt_path.into_boxed_str());
        // 创建WFP控制器实例
        let mut wfp_controller = WfpController::new().map_err(|e| e.to_string())?;

        // 初始化WFP引擎
        if let Err(e) = wfp_controller.initialize() {
            eprintln!("WFP引擎初始化失败: {}", e);
            return Err(format!("WFP引擎初始化失败: {}", e));
        }

        println!("🎯 目标应用程序: {:?}", nt_path);
        println!("\n🔧 添加禁止所有网络连接的规则...");
        let advanced_rules = vec![
            // 禁止 Chrome 的所有网络连接（入站和出站，所有协议、所有端口、所有 IP）
            FilterRule::new("禁止 Chrome 所有网络连接")
                .app_path(nt_path)
        ];

        if let Err(e) = wfp_controller.add_advanced_filters(&advanced_rules) {
            eprintln!("添加高级过滤规则失败: {}", e);
            return Err(format!("添加高级过滤规则失败: {}", e));
        }
        println!("✅ 规则已添加。");
        println!("⏳ 等待规则生效...");
        // 永远等待，直到手动停止
        future::pending::<()>().await; // 永远等待
        // 下面这行不会被执行，因为上面 pending 永远不会返回
        println!("✅ 内部规则已添加。");
        Ok(())
    })
   
}



// 创建服务器
pub fn create_server(
    username: String,
    enable_dhcp: bool,
    specified_ip: String,
    room_name: String,
    room_password: String,
    severurl: Vec<String>,
    onurl: Vec<String>,
    cidrs: Vec<String>,
    forwards: Vec<Forward>,
    flag: FlagsC,
) -> JoinHandle<Result<(), String>> {
    print!("{}", format!("创建服务器: {}，启用DHCP: {}, 指定IP: {}, 房间名称: {}, 房间密码: {}, 服务器URL: {:?}, 监听器URL: {:?}", username, enable_dhcp, specified_ip, room_name, room_password, severurl, onurl));
    RT.spawn(async move {
        // Create config with better error handling
        let mut cfg = TomlConfigLoader::default();

        // Set listeners with proper error handling
        let mut listeners = Vec::new();
        for url in onurl {
            match url.parse() {
                Ok(parsed) => listeners.push(parsed),
                Err(e) => return Err(format!("Invalid listener URL: {}, error: {}", url, e)),
            }
        }
        cfg.set_listeners(listeners);

        // Set hostname and other settings
        cfg.set_hostname(Some(username));
        cfg.set_dhcp(enable_dhcp);
        for c in cidrs {
            cfg.add_proxy_cidr(c.parse().unwrap());
        }
        let mut old = cfg.get_port_forwards();

        for c in forwards {
            // 打印
            println!("{}", format!("添加端口转发: {} -> {} -{}", c.bind_addr, c.dst_addr    , c.proto));
            let port_forward_item = PortForwardConfig {
                bind_addr:c.bind_addr.parse().unwrap(),
                dst_addr:c.dst_addr.parse().unwrap(),
                proto: c.proto,
            };
            old.push(port_forward_item);
        }
        
        cfg.set_port_forwards(old);
        // Set flags more efficiently by directly mapping from input
        let mut flags = cfg.get_flags();
        flags.default_protocol = flag.default_protocol;
        flags.dev_name = "astral".to_string();
        flags.enable_encryption = flag.enable_encryption;
        flags.enable_ipv6 = flag.enable_ipv6;
        flags.mtu = flag.mtu;
        flags.latency_first = flag.latency_first;
        flags.enable_exit_node = flag.enable_exit_node;
        flags.no_tun = flag.no_tun;
        flags.use_smoltcp = flag.use_smoltcp;
        flags.relay_network_whitelist = flag.relay_network_whitelist;
        flags.disable_p2p = flag.disable_p2p;
        flags.relay_all_peer_rpc = flag.relay_all_peer_rpc;
        flags.disable_udp_hole_punching = flag.disable_udp_hole_punching;
        flags.multi_thread = flag.multi_thread;
        flags.data_compress_algo = flag.data_compress_algo;
        flags.bind_device = flag.bind_device;
        flags.enable_kcp_proxy = flag.enable_kcp_proxy;
        flags.disable_kcp_input = flag.disable_kcp_input;
        flags.disable_relay_kcp = flag.disable_relay_kcp;
        flags.proxy_forward_by_system = flag.proxy_forward_by_system;
        flags.accept_dns = flag.accept_dns;
        cfg.set_flags(flags);
        // Configure peer connections with proper error handling
        let mut peer_configs = Vec::new();
        for url in severurl {
            match url.parse() {
                Ok(uri) => peer_configs.push(PeerConfig { uri }),
                Err(e) => return Err(format!("Invalid server URL: {}, error: {}", url, e)),
            }
        }
        cfg.set_peers(peer_configs);

        // Set IP if DHCP is disabled
        if !enable_dhcp && !specified_ip.is_empty() {
            let ip_str = format!("{}/24", specified_ip);
            match ip_str.parse() {
                Ok(ip) => cfg.set_ipv4(Some(ip)),
                Err(e) => {
                    return Err(format!(
                        "Invalid IP address: {}, error: {}",
                        specified_ip, e
                    ))
                }
            }
        }

        // Set network identity
        cfg.set_network_identity(NetworkIdentity::new(room_name, room_password));

        // 直接启动网络实例，无需嵌套 spawn
        create_and_store_network_instance(cfg).await
    })
}

// 关闭服务器实例
pub fn close_server() {
    RT.spawn(async {
        // 获取mutex锁
        let mut locked_instance = INSTANCE.lock().unwrap();

        println!(
            "关闭前实例状态: {}",
            if locked_instance.is_some() {
                "存在"
            } else {
                "不存在"
            }
        ); // 添加关闭前日志

        // 如果实例存在，则丢弃它
        if let Some(instance) = locked_instance.take() {
            println!("正在关闭实例");
            // 丢弃实例
            drop(instance);
            println!("实例已成功关闭");
        } else {
            println!("没有找到需要关闭的实例");
        }

        println!(
            "关闭后实例状态: {}",
            if locked_instance.is_some() {
                "存在"
            } else {
                "不存在"
            }
        ); // 添加关闭后日志
    });
}

// 创建一个网卡跃点数据结构
// 网卡跃点数据结构



pub fn get_peer_route_pairs() -> Result<Vec<PeerRoutePair>, String> {
    let instance_guard = INSTANCE
        .lock()
        .map_err(|e| format!("获取互斥锁失败: {}", e))?;

    if let Some(instance) = instance_guard.as_ref() {
        // 获取运行信息
        if let Some(info) = instance.get_running_info() {
            let mut pairs = info.peer_route_pairs;
            // 如果存在本地节点信息，添加到结果中
            if let Some(my_node_info) = &info.my_node_info {
                // 获取本地节点ID
                // 注意：这里的逻辑可能需要根据单例模式调整，假设本地节点信息可以直接从 info 中获取
                // 使用原始逻辑查找本地 peer_id
                let my_peer_id = info
                    .peers
                    .iter()
                    .find(|p| p.conns.iter().any(|c| !c.is_client))
                    .map(|p| p.peer_id)
                    .unwrap_or(0);

                // 创建一个表示本地节点的Route
                let my_route = proto::cli::Route {
                    peer_id: my_peer_id,
                    ipv4_addr: my_node_info.virtual_ipv4.clone(),
                    next_hop_peer_id: my_peer_id, // 指向自己
                    cost: 0,                      // 到自己的成本为0
                    path_latency: 0,              // 到自己的延迟为0
                    proxy_cidrs: vec![],
                    hostname: my_node_info.hostname.clone(),
                    stun_info: my_node_info.stun_info.clone(),
                    inst_id: "local".to_string(), // 标记为本地实例
                    version: my_node_info.version.clone(),
                    feature_flag: None, // 本地节点通常没有特性标志
                    next_hop_peer_id_latency_first: None,
                    cost_latency_first: None,
                    path_latency_latency_first: None,
                };

                // 创建一个表示本地节点的PeerInfo，包含网络统计信息
                // 注意：本地节点的PeerInfo可能需要特殊处理或从其他地方获取
                let my_peer_info = info.peers.iter().find(|p| p.peer_id == my_peer_id).cloned();

                // 创建一个表示本地节点的PeerRoutePair
                let my_pair = proto::cli::PeerRoutePair {
                    route: Some(my_route),
                    peer: my_peer_info, // 使用找到的PeerInfo或None
                };

                // 添加到结果中
                pairs.push(my_pair);
            }

            return Ok(pairs);
        }
        return Err("无法获取运行信息".to_string());
    }
    Err("没有运行中的网络实例".to_string())
}

// 获取网络状态信息
pub fn get_network_status() -> KVNetworkStatus {
    let pairs = get_peer_route_pairs().unwrap_or_default();
    let mut nodes = Vec::new();
    for pair in pairs.iter() {
        if let Some(route) = &pair.route {
            let cost = route.cost;
            // 使用 get_running_info 中的逻辑来获取IPv4地址
            let ipv4 = route
                .ipv4_addr
                .as_ref()
                .and_then(|addr| addr.address.as_ref())
                .map(|a| {
                    format!(
                        "{}.{}.{}.{}",
                        (a.addr >> 24) & 0xFF,
                        (a.addr >> 16) & 0xFF,
                        (a.addr >> 8) & 0xFF,
                        a.addr & 0xFF
                    )
                })
                .unwrap_or_else(|| "0.0.0.0".to_string());
            let mut node_info = KVNodeInfo {
                hostname: route.hostname.clone(),

                hops: {
                    // 新建递归函数收集完整路径
                    fn collect_hops(
                        pairs: &[PeerRoutePair],
                        current_peer_id: u32,
                        mut path: Vec<NodeHopStats>,
                        visited: &mut std::collections::HashSet<u32>,
                    ) -> Vec<NodeHopStats> {
                        if visited.contains(&current_peer_id) {
                            return path;
                        }
                        visited.insert(current_peer_id);

                        // 查找当前节点的信息
                        if let Some(pair) = pairs.iter().find(|p| {
                            p.route
                                .as_ref()
                                .map_or(false, |r| r.peer_id == current_peer_id)
                        }) {
                            if let Some(route) = &pair.route {
                                // 获取IP地址
                                let ip = route
                                    .ipv4_addr
                                    .as_ref()
                                    .and_then(|addr| addr.address.as_ref())
                                    .map(|a| {
                                        format!(
                                            "{}.{}.{}.{}",
                                            (a.addr >> 24) & 0xFF,
                                            (a.addr >> 16) & 0xFF,
                                            (a.addr >> 8) & 0xFF,
                                            a.addr & 0xFF
                                        )
                                    })
                                    .unwrap_or_default();

                                // 计算延迟和丢包率
                                let (latency, loss) = pair.peer.as_ref().map_or((0.0, 0.0), |p| {
                                    let min_latency = p
                                        .conns
                                        .iter()
                                        .filter_map(|c| c.stats.as_ref().map(|s| s.latency_us))
                                        .min()
                                        .unwrap_or(0)
                                        as f64
                                        / 1000.0;

                                    let avg_loss = p.conns.iter().map(|c| c.loss_rate).sum::<f32>()
                                        / p.conns.len().max(1) as f32;

                                    (min_latency, avg_loss as f64)
                                });

                                // 添加当前节点到路径
                                path.push(NodeHopStats {
                                    target_ip: ip,
                                    latency_ms: latency,
                                    packet_loss: loss as f32,
                                    node_name: route.hostname.clone(),
                                });

                                // 如果下一跳不是自己，继续递归
                                if route.next_hop_peer_id != current_peer_id
                                    && route.next_hop_peer_id != 0
                                {
                                    // 查找下一跳节点
                                    return collect_hops(
                                        pairs,
                                        route.next_hop_peer_id,
                                        path,
                                        visited,
                                    );
                                }
                            }
                        }
                        path
                    }

                    // 使用路由表中的next_hop_peer_id构建完整路径
                    let mut hops = Vec::new();
                    if let Some(route) = &pair.route {
                        let mut visited = std::collections::HashSet::new();

                        // 从当前节点开始，收集到目标节点的完整路径
                        // 先添加本地节点信息
                        let instance_guard = INSTANCE.lock().unwrap(); // 使用单例 INSTANCE
                        if let Some(instance) = instance_guard.as_ref() {
                            if let Some(info) = instance.get_running_info() {
                                if let Some(local_node) = &info.my_node_info {
                                    // 添加本地节点作为起点
                                    hops.push(NodeHopStats {
                                        target_ip: local_node
                                            .virtual_ipv4
                                            .as_ref()
                                            .and_then(|addr| addr.address.as_ref())
                                            .map(|a| {
                                                format!(
                                                    "{}.{}.{}.{}",
                                                    (a.addr >> 24) & 0xFF,
                                                    (a.addr >> 16) & 0xFF,
                                                    (a.addr >> 8) & 0xFF,
                                                    a.addr & 0xFF
                                                )
                                            })
                                            .unwrap_or_else(|| local_node.hostname.clone()),
                                        latency_ms: 0.0,
                                        packet_loss: 0.0,
                                        node_name: local_node.hostname.clone(),
                                    });

                                    // 查找从本地到目标节点的路由
                                    if let Some(local_route) =
                                        info.routes.iter().find(|r| r.peer_id == route.peer_id)
                                    {
                                        // 收集中间节点
                                        let mut next_hops = collect_hops(
                                            pairs.as_slice(),
                                            local_route.next_hop_peer_id,
                                            Vec::new(),
                                            &mut visited,
                                        );
                                        hops.append(&mut next_hops);

                                        // 确保目标节点被添加到路径中
                                        // 检查最后一个节点是否是目标节点
                                        let last_node_is_target =
                                            hops.last().map_or(false, |last| {
                                                // 比较 hostname
                                                last.node_name == route.hostname
                                            });

                                        // 如果最后一个节点不是目标节点，则添加目标节点
                                        if !last_node_is_target && !visited.contains(&route.peer_id)
                                        {
                                            let ip = route
                                                .ipv4_addr
                                                .as_ref()
                                                .and_then(|addr| addr.address.as_ref())
                                                .map(|a| {
                                                    format!(
                                                        "{}.{}.{}.{}",
                                                        (a.addr >> 24) & 0xFF,
                                                        (a.addr >> 16) & 0xFF,
                                                        (a.addr >> 8) & 0xFF,
                                                        a.addr & 0xFF
                                                    )
                                                })
                                                .unwrap_or_default();

                                            let (latency, loss) =
                                                pair.peer.as_ref().map_or((0.0, 0.0), |p| {
                                                    let min_latency = p
                                                        .conns
                                                        .iter()
                                                        .filter_map(|c| {
                                                            c.stats.as_ref().map(|s| s.latency_us)
                                                        })
                                                        .min()
                                                        .unwrap_or(0)
                                                        as f64
                                                        / 1000.0;

                                                    let avg_loss = p
                                                        .conns
                                                        .iter()
                                                        .map(|c| c.loss_rate)
                                                        .sum::<f32>()
                                                        / p.conns.len().max(1) as f32;

                                                    (min_latency, avg_loss as f64)
                                                });

                                            hops.push(NodeHopStats {
                                                target_ip: ip,
                                                latency_ms: latency,
                                                packet_loss: loss as f32,
                                                node_name: route.hostname.clone(),
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        // 如果没有收集到任何跳点（可能是直连节点），则直接添加目标节点
                        // 检查 hops 是否只包含本地节点
                        if hops.len() <= 1 {
                            // 确保目标节点不在hops中（避免重复添加）
                            if !hops.iter().any(|h| h.node_name == route.hostname) {
                                let ip = route
                                    .ipv4_addr
                                    .as_ref()
                                    .and_then(|addr| addr.address.as_ref())
                                    .map(|a| {
                                        format!(
                                            "{}.{}.{}.{}",
                                            (a.addr >> 24) & 0xFF,
                                            (a.addr >> 16) & 0xFF,
                                            (a.addr >> 8) & 0xFF,
                                            a.addr & 0xFF
                                        )
                                    })
                                    .unwrap_or_default();

                                let (latency, loss) = pair.peer.as_ref().map_or((0.0, 0.0), |p| {
                                    let min_latency = p
                                        .conns
                                        .iter()
                                        .filter_map(|c| c.stats.as_ref().map(|s| s.latency_us))
                                        .min()
                                        .unwrap_or(0)
                                        as f64
                                        / 1000.0;

                                    let avg_loss = p.conns.iter().map(|c| c.loss_rate).sum::<f32>()
                                        / p.conns.len().max(1) as f32;

                                    (min_latency, avg_loss as f64)
                                });

                                hops.push(NodeHopStats {
                                    target_ip: ip,
                                    latency_ms: latency,
                                    packet_loss: loss as f32,
                                    node_name: route.hostname.clone(),
                                });
                            }
                        }
                    }
                    hops
                },
                latency_ms: if route.cost == 1 {
                    pair.get_latency_ms().unwrap_or(0.0)
                } else {
                    route.path_latency_latency_first() as f64
                },
                ipv4: ipv4,

                loss_rate: if let Some(peer) = &pair.peer {
                    let mut total_loss_rate = 0.0;
                    for conn in &peer.conns {
                        total_loss_rate += conn.loss_rate;
                    }
                    total_loss_rate
                } else {
                    0.0 // 如果没有连接信息，默认为0
                },
                nat: route.stun_info.as_ref().map_or_else(
                    || "Unknown".to_string(),
                    |stun| {
                        // 使用NatType枚举替代直接匹配数字
                        let nat_type =
                            NatType::try_from(stun.udp_nat_type).unwrap_or(NatType::Unknown);
                        format!("{:?}", nat_type)
                    },
                ),
                connections: Vec::new(),
                version: route.version.clone(),
                cost,
                conn_type: pair.get_udp_nat_type(),
                tunnel_proto: pair
                    .get_conn_protos()
                    .unwrap_or_default()
                    .join(",")
                    .to_string(),
                rx_bytes: pair.get_rx_bytes().unwrap_or_default(),
                tx_bytes: pair.get_tx_bytes().unwrap_or_default(),
            };

            // 收集连接统计信息
            if let Some(peer) = &pair.peer {
                for conn in &peer.conns {
                    if let Some(stats) = &conn.stats {
                        let conn_type = if let Some(tunnel) = &conn.tunnel {
                            tunnel.tunnel_type.clone()
                        } else {
                            "未知".to_string()
                        };

                        node_info.connections.push(KVNodeConnectionStats {
                            conn_type,
                            rx_bytes: stats.rx_bytes,
                            tx_bytes: stats.tx_bytes,
                            rx_packets: stats.rx_packets,
                            tx_packets: stats.tx_packets,
                        });
                    }
                }
            }

            nodes.push(node_info);
        }
    }

    KVNetworkStatus {
        total_nodes: nodes.len(),
        nodes,
    }
}

pub fn init_app() {
    lazy_static::initialize(&RT);
}

