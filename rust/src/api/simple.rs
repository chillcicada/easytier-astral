pub use std::collections::BTreeMap;
use std::sync::Mutex;

use easytier::common::scoped_task::ScopedTask;
pub use easytier::{
    common::{
        self,
        config::{NetworkIdentity, PeerConfig,ConfigLoader, TomlConfigLoader},
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
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use once_cell::sync::Lazy;
use serde_json::json;
use tokio::runtime::Runtime;
pub use tokio::task::JoinHandle;



static INSTANCE: Mutex<Option<NetworkInstance>> = Mutex::new(None);
// 创建一个 NetworkInstance 类型变量 储存当前服务器
lazy_static! {
    static ref RT: Runtime = Runtime::new().expect("创建 Tokio 运行时失败");
}

fn peer_conn_info_to_string(p: proto::cli::PeerConnInfo) -> String {
    format!(
        "my_peer_id: {}, dst_peer_id: {}, tunnel_info: {:?}",
        p.my_peer_id, p.peer_id, p.tunnel
    )
}

pub fn handle_event(mut events: EventBusSubscriber) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        loop {
            match events.recv().await {
                Ok(e) => {
                    //  println!("Received event: {:?}", e);
                    match e {
                        GlobalCtxEvent::PeerAdded(p) => {
                            println!("{}",format!("新节点已添加。节点ID: {}", p));
                        }

                        GlobalCtxEvent::PeerRemoved(p) => {
                            println!("{}",format!("节点已移除。节点ID: {}", p));
                        }

                        GlobalCtxEvent::PeerConnAdded(p) => {
                            println!("{}",format!(
                                "新节点连接已添加。连接信息: {}",
                                peer_conn_info_to_string(p)
                            ));
                        }
                        GlobalCtxEvent::PeerConnRemoved(p) => {
                            println!("{}",format!(
                                "节点连接已移除。连接信息: {}",
                                peer_conn_info_to_string(p)
                            ));
                        }
                        GlobalCtxEvent::ListenerAddFailed(p, msg) => {
                            println!("{}",format!(
                                "监听器添加失败。监听器: {}, 消息: {}",
                                p, msg
                            ));
                        }
                        GlobalCtxEvent::ListenerAcceptFailed(p, msg) => {
                            println!("{}",format!(
                                "监听器接受失败。监听器: {}, 消息: {}",
                                p, msg
                            ));
                        }
                        GlobalCtxEvent::ListenerAdded(p) => {
                            if p.scheme() == "ring" {
                                continue;
                            }
                            println!("{}",format!("新监听器已添加。监听器: {}", p));
                        }
                        GlobalCtxEvent::ConnectionAccepted(local, remote) => {
                            println!("{}",format!(
                                "新连接已接受。本地: {}, 远程: {}",
                                local, remote
                            ));
                        }
                        GlobalCtxEvent::ConnectionError(local, remote, err) => {
                            println!("{}",format!(
                                "连接错误。本地: {}, 远程: {}, 错误: {}",
                                local, remote, err
                            ));
                        }
                        GlobalCtxEvent::TunDeviceReady(dev) => {
                            println!("{}",format!("TUN 设备就绪。设备: {}", dev));
                        }
                        GlobalCtxEvent::TunDeviceError(err) => {
                            println!("{}",format!("TUN 设备错误。错误: {}", err));
                        }
                        GlobalCtxEvent::Connecting(dst) => {
                            println!("{}",format!("正在连接到节点。目标: {}", dst));
                        }
                        GlobalCtxEvent::ConnectError(dst, ip_version, err) => {
                            println!("{}",format!(
                                "连接到节点错误。目标: {}, IP版本: {}, 错误: {}",
                                dst, ip_version, err
                            ));
                        }
                        GlobalCtxEvent::VpnPortalClientConnected(portal, client_addr) => {
                            println!("{}",format!(
                                "VPN 门户客户端已连接。门户: {}, 客户端地址: {}",
                                portal, client_addr
                            ));
                        }
                        GlobalCtxEvent::VpnPortalClientDisconnected(portal, client_addr) => {
                            println!("{}",format!(
                                "VPN 门户客户端已断开连接。门户: {}, 客户端地址: {}",
                                portal, client_addr
                            ));
                        }
                        GlobalCtxEvent::DhcpIpv4Changed(old, new) => {
                            println!("{}",format!("DHCP IP 已更改。旧: {:?}, 新: {:?}", old, new));
                        }
                        GlobalCtxEvent::DhcpIpv4Conflicted(ip) => {
                            println!("{}",format!("DHCP IP 冲突。IP: {:?}", ip));
                        }
                        GlobalCtxEvent::PortForwardAdded(cfg) => {
                            println!("{}",format!(
                                "端口转发已添加。本地: {}, 远程: {}, 协议: {}",
                                cfg.bind_addr.unwrap().to_string(),
                                cfg.dst_addr.unwrap().to_string(),
                                cfg.socket_type().as_str_name()
                            ));
                        }

                    }
                }
                Err(err) => {
                    eprintln!("接收事件错误: {:?}", err);
                    // 根据错误类型决定是否中断循环
                    match err {
                        tokio::sync::broadcast::error::RecvError::Closed => {
                            println!("事件通道已关闭，停止事件处理。");
                            break; // Exit the loop if the channel is closed
                        }
                        tokio::sync::broadcast::error::RecvError::Lagged(n) => {
                            eprintln!("事件处理滞后，丢失了 {} 个事件。", n);
                            // Decide if lagging is critical enough to break or just log
                        }
                    }
                    
                }
            }
        }
    })
}


async fn create_and_store_network_instance(cfg: TomlConfigLoader) -> Result<(), String> {
    println!("Starting easytier with config:");
    println!("############### TOML ###############\n");
    println!("{}", cfg.dump());
    println!("-----------------------------------");
    // 在移动 cfg 之前先获取 ID
    let name = cfg.get_id().to_string();
    // 创建网络实例
    let mut network = NetworkInstance::new(cfg).set_fetch_node_info(true);
    // 启动网络实例，并处理可能的错误
    handle_event(network.start().unwrap());

    println!("instance {} started", name);
    // 将实例存储到 INSTANCE 中
    let mut instance_guard = INSTANCE.lock().map_err(|e| format!("获取互斥锁失败: {}", e))?;
    
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
    pub target_ip: String,         // 目标节点IP
    pub latency_ms: f64,          // 延迟(毫秒)
    pub packet_loss: f32,         // 丢包率
    pub node_name: String,        // 节点名称
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
                    "path_latency_latency_first": route.path_latency_latency_first
                })).collect::<Vec<_>>(),
                "peers": info.peers.iter().map(|peer| json!({
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
                Err(e) => return Err(format!("Invalid listener URL: {}, error: {}", url, e))
            }
        }
        cfg.set_listeners(listeners);
        
        // Set hostname and other settings
        cfg.set_hostname(Some(username));
        cfg.set_dhcp(enable_dhcp);
        
        // Set flags more efficiently by directly mapping from input
        let mut flags = cfg.get_flags();
        flags.default_protocol = flag.default_protocol;
        flags.dev_name = flag.dev_name;
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
        cfg.set_flags(flags);
        
        // Configure peer connections with proper error handling
        let mut peer_configs = Vec::new();
        for url in severurl {
            match url.parse() {
                Ok(uri) => peer_configs.push(PeerConfig { uri }),
                Err(e) => return Err(format!("Invalid server URL: {}, error: {}", url, e))
            }
        }
        cfg.set_peers(peer_configs);
        
        // Set IP if DHCP is disabled
        if !enable_dhcp && !specified_ip.is_empty() {
            let ip_str = format!("{}/24", specified_ip);
            match ip_str.parse() {
                Ok(ip) => cfg.set_ipv4(Some(ip)),
                Err(e) => return Err(format!("Invalid IP address: {}, error: {}", specified_ip, e))
            }
        }
        
        // Set network identity
        cfg.set_network_identity(NetworkIdentity::new(room_name, room_password));

        // Start network instance directly without nesting spawns
        create_and_store_network_instance(cfg).await
    })
}

// 关闭服务器实例
pub fn close_server() {
    RT.spawn(async {
        // 获取mutex锁
        let mut locked_instance = INSTANCE.lock().unwrap();
        
        println!("关闭前实例状态: {}", if locked_instance.is_some() { "存在" } else { "不存在" }); // 添加关闭前日志
        
        // 如果实例存在，则丢弃它
        if let Some(instance) = locked_instance.take() {
            println!("正在关闭实例");
            // 丢弃实例
            drop(instance);
            println!("实例已成功关闭");
        } else {
            println!("没有找到需要关闭的实例");
        }
        
        println!("关闭后实例状态: {}", if locked_instance.is_some() { "存在" } else { "不存在" }); // 添加关闭后日志
    });
}

// 创建一个网卡跃点数据结构 
// 网卡跃点数据结构
pub struct NetworkInterfaceHop {
    // 网卡名称
    pub interface_name: String,
    // 跃点数
    pub hop_count: u32,
}

// 网卡跃点集合
pub struct NetworkInterfaceHops {
    // 网卡跃点列表
    pub hops: Vec<NetworkInterfaceHop>,
}


// 获取网卡跃点信息
pub fn get_network_interface_hops() -> NetworkInterfaceHops {
    // 获取所有网卡信息
    let mut hops = Vec::new();
    
    #[cfg(target_os = "windows")]
    {
        use std::mem;
        use winapi::shared::winerror::ERROR_BUFFER_OVERFLOW;
        use winapi::shared::ws2def::SOCKADDR;
        // Fix: Import GAA_FLAG_INCLUDE_PREFIX from the correct module
        use winapi::um::iphlpapi::GetAdaptersAddresses;
        use winapi::um::iptypes::{IP_ADAPTER_ADDRESSES, IP_ADAPTER_UNICAST_ADDRESS};
        // Fix: Import the flag from the correct location
        use winapi::um::iptypes::GAA_FLAG_INCLUDE_PREFIX;

        // 初始化缓冲区大小
        let mut size = 0;
        let family = winapi::shared::ws2def::AF_UNSPEC;
        // Fix: Ensure flags is u32 as expected by the API
        let flags = GAA_FLAG_INCLUDE_PREFIX as u32;
        
        // 第一次调用获取所需缓冲区大小
        unsafe {
            let result = GetAdaptersAddresses(family as u32, flags, std::ptr::null_mut(), std::ptr::null_mut(), &mut size);
            // Fix: Ensure comparison is with u32
            if result == ERROR_BUFFER_OVERFLOW as u32 {
                // 分配足够的内存
                let mut buffer = vec![0u8; size as usize];
                let addresses = buffer.as_mut_ptr() as *mut IP_ADAPTER_ADDRESSES;
                
                // 再次调用获取实际数据
                let result = GetAdaptersAddresses(family as u32, flags, std::ptr::null_mut(), addresses, &mut size);
                if result == 0 {
                    // 成功获取数据，遍历所有适配器
                    let mut current_addresses = addresses;
                    while !current_addresses.is_null() {
                        let adapter = &*current_addresses;
                        
                        // 获取适配器名称
                        let name = if !adapter.FriendlyName.is_null() {
                            let name_slice = std::slice::from_raw_parts(
                                adapter.FriendlyName,
                                (0..255).find(|&i| *adapter.FriendlyName.offset(i as isize) == 0).unwrap_or(0)
                            );
                            String::from_utf16_lossy(name_slice)
                        } else {
                            String::from("Unknown")
                        };
                        
                        // 获取跃点数
                        let hop_count = adapter.Ipv4Metric;
                        
                        // 添加到结果列表
                        hops.push(NetworkInterfaceHop {
                            interface_name: name,
                            hop_count,
                        });
                        
                        // 移动到下一个适配器
                        current_addresses = adapter.Next;
                    }
                }
            }
        }
    }
    
    #[cfg(not(target_os = "windows"))]
    {
        // 对于非Windows系统，返回一个空列表或实现其他平台的逻辑
        println!("获取网卡跃点信息仅支持Windows系统");
    }
    
    NetworkInterfaceHops { hops }
}

//给INSTANCE网卡设置跃点
pub fn set_network_interface_hops(hop: i32) -> bool {
    // 获取实例
    #[cfg(target_os = "windows")]
    {
        use std::process::Command;
        // 导入Windows特定的CommandExt特性和CREATE_NO_WINDOW标志
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x08000000;
        
        let mut success = true;
        
        // 从INSTANCE获取实例
        let instance = INSTANCE.lock().unwrap();
        
        if let Some(instance) = instance.as_ref() {
            // 获取实例的运行信息
            if let Some(info) = instance.get_running_info() {
                // 获取设备名称
                let dev_name = info.dev_name.clone();
                
                if !dev_name.is_empty() {
                    println!("设置EasyTier网卡 {} 的跃点数为 {}", dev_name, hop);
                    // 使用Windows命令行工具设置网卡跃点数，并添加CREATE_NO_WINDOW标志
                    let output = Command::new("netsh")
                        .args(&[
                            "interface", 
                            "ipv4", 
                            "set", 
                            "interface", 
                            &dev_name, 
                            &format!("metric={}", hop)
                        ])
                        .creation_flags(CREATE_NO_WINDOW) // 添加这一行来隐藏窗口
                        .output();
                        
                    match output {
                        Ok(output) => {
                            if output.status.success() {
                                println!("成功设置EasyTier网卡 {} 的跃点数为 {}", dev_name, hop);
                            } else {
                                let error = String::from_utf8_lossy(&output.stderr);
                                println!("设置EasyTier网卡 {} 跃点数失败: {}", dev_name, error);
                                success = false;
                            }
                        },
                        Err(e) => {
                            println!("执行命令失败: {}", e);
                            success = false;
                        }
                    }
                } else {
                    println!("实例的设备名称为空");
                    success = false;
                }
            } else {
                println!("无法获取实例的运行信息");
                success = false;
            }
        } else {
            println!("没有找到EasyTier网络实例");
            success = false;
        }
        
        success
    }
    
    #[cfg(not(target_os = "windows"))]
    {
        println!("设置网卡跃点数仅支持Windows系统");
        false
    }
}
pub fn init_app() {
    lazy_static::initialize(&RT);
}
