pub use std::collections::BTreeMap;
//use BTreeMap
use dashmap::DashMap;

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



static INSTANCE_MAP: Lazy<DashMap<String, NetworkInstance>> = Lazy::new(DashMap::new);
// 创建一个 NetworkInstance 类型变量 储存当前服务器
lazy_static! {
    static ref RT: Runtime = Runtime::new().expect("创建 Tokio 运行时失败");
}

fn create_config() -> TomlConfigLoader {
    let mut cfg = TomlConfigLoader::default();
    // 构造 PeerConfig 实例并设置 peers


    // cfg.set_inst_name("default".to_string());
    // cfg.set_inst_name(name);
    cfg
}



// 添加一个函数来获取对等节点和路由信息
pub fn get_peers_and_routes() -> Result<(Vec<PeerInfo>, Vec<Route>), String> {
    if let Some(instance) = INSTANCE_MAP.iter().next() {
        // 获取运行信息
        if let Some(info) = instance.get_running_info() {
            return Ok((info.peers, info.routes));
        }
        return Err("无法获取运行信息".to_string());
    }
    Err("没有运行中的网络实例".to_string())
}

// 如果需要获取配对后的信息，可以使用这个函数
pub fn get_peer_route_pairs() -> Result<Vec<PeerRoutePair>, String> {
    if let Some(instance) = INSTANCE_MAP.iter().next() {
        // 获取运行信息
        if let Some(info) = instance.get_running_info() {
            let mut pairs = info.peer_route_pairs;

            // 如果存在本地节点信息，添加到结果中
            if let Some(my_node_info) = &info.my_node_info {
                // 获取本地节点ID
                let my_peer_id = info
                    .peers
                    .iter()
                    .find(|p| p.conns.iter().any(|c| c.is_client == false))
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
                    inst_id: "local".to_string(),
                    version: my_node_info.version.clone(),
                    feature_flag: None,
                    next_hop_peer_id_latency_first: None,
                    cost_latency_first: None,
                    path_latency_latency_first: None,
                };

                // 创建一个表示本地节点的PeerInfo，包含网络统计信息
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

// 获取节点信息
pub fn get_node_info() -> Result<MyNodeInfo, String> {
    if let Some(instance) = INSTANCE_MAP.iter().next() {
        // 获取运行信息
        if let Some(info) = instance.get_running_info() {
            if let Some(node_info) = info.my_node_info {
                return Ok(node_info);
            }
            return Err("无法获取节点信息".to_string());
        }
        return Err("无法获取运行信息".to_string());
    }
    Err("没有运行中的网络实例".to_string())
}

async fn create_and_store_network_instance(cfg: TomlConfigLoader) -> Result<(), String> {
    println!("Starting easytier with config:");
    println!("############### TOML ###############\n");
    println!("{}", cfg.dump());
    println!("-----------------------------------");
    // 在移动 cfg 之前先获取 ID
    let name = cfg.get_id().to_string();
    // 创建网络实例
    let mut instance = NetworkInstance::new(cfg).set_fetch_node_info(true);
    // 启动网络实例，并处理可能的错误
    instance.start().unwrap();
    println!("instance {} started", name);
    // 将实例存储到 INSTANCE_MAP 中
    INSTANCE_MAP.insert(name, instance);

    Ok(())
}

// 返回EasyTier的版本号
pub fn easytier_version() -> Result<String, String> {
    Ok(easytier::VERSION.to_string())
}

// 是否在运行
pub fn is_easytier_running() -> bool {
    if let Some(instance) = INSTANCE_MAP.iter().next() {
        instance.is_easytier_running()
    } else {
        false
    }
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
pub fn get_all_ips() -> Vec<String> {
    let mut result = Vec::new();
    if let Some(instance) = INSTANCE_MAP.iter().next() {
        if let Some(info) = instance.get_running_info() {
            
            // 添加所有远程节点IP
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
                        // 避免重复添加
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
    // 遍历所有实例并设置TUN文件描述符
    for mut instance in INSTANCE_MAP.iter_mut() {
        instance.set_tun_fd(fd);
    }
    Ok(())
}



pub fn get_running_info() -> String {
    INSTANCE_MAP
        .iter()
        .next()
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
    /// string ipv6_listener = 14; \[deprecated = true\]; use -l udp://\[::\]:12345 instead
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
    flag:FlagsC,
) {
    RT.spawn(async move {
        // 创建一个示例配置
        let cfg = create_config();
        // 使用传入的onurl参数设置监听地址
        let mut listeners = Vec::new();
        for url in onurl {
            listeners.push(url.parse().unwrap());
        }
        cfg.set_listeners(listeners);
        cfg.set_hostname(Option::from(username));
        cfg.set_dhcp(enable_dhcp);
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
        // flags.dev_name = "astral".to_string();
        cfg.set_flags(flags);
        // 创建TCP和UDP连接配置列表
        let mut peer_configs = Vec::new();
        // 为每个服务器URL创建TCP和UDP配置
        for url in severurl {
            peer_configs.push(PeerConfig {
                uri: format!("{}", url).parse().unwrap(),
            });
        }
        
        cfg.set_peers(peer_configs);
        if enable_dhcp == false {
            // 使用完整路径引用 cidr 模块的 Ipv4Inet
            // 解析IP地址和子网掩码
            let ip = format!("{}/24", specified_ip).parse().unwrap();
            cfg.set_ipv4(Some(ip));
        }
        cfg.set_network_identity(NetworkIdentity::new(
            room_name.to_string(),
            room_password.to_string(),
        ));

        // 并行启动网络实例
        let handle1 = tokio::spawn(async move {
            if let Err(e) = create_and_store_network_instance(cfg).await {
                eprintln!("创建网络实例失败: {}", e);
            }
        });

        // 等待所有任务完成
        let _ = tokio::join!(handle1);
    });
}

// 获取INSTANCE_MAP所有的服务器然后关闭
pub fn close_all_server() {
    RT.spawn(async {
        println!("关闭前实例数: {}", INSTANCE_MAP.len()); // 添加关闭前日志
        let keys: Vec<_> = INSTANCE_MAP.iter().map(|e| e.key().clone()).collect();
        println!("待关闭实例键: {:?}", keys); // 增加键列表输出

        for key in keys {
            if let Some((_, mut instance)) = INSTANCE_MAP.remove(&key) {
                //丢弃 instance
                drop(instance);
            } else {
                println!("未找到实例: {}", key); // 增加错误处理
            }
        }
        println!("关闭后剩余实例数: {}", INSTANCE_MAP.len()); // 添加关闭后日志
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


//给INSTANCE_MAP所有的网卡设置跃点
pub fn set_network_interface_hops(hop: i32) -> bool {
    // 遍历所有实例
    #[cfg(target_os = "windows")]
    {
        use std::process::Command;
        // 导入Windows特定的CommandExt特性和CREATE_NO_WINDOW标志
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x08000000;
        
        let mut success = true;
        
        // 从INSTANCE_MAP获取所有实例
        for instance in INSTANCE_MAP.iter() {
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
        }
        
        // 如果INSTANCE_MAP为空，则返回失败
        if INSTANCE_MAP.is_empty() {
            println!("没有找到任何EasyTier网络实例");
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
