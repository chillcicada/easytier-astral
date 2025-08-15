//! AstralWFP - 跨平台网络流量管理库
//! 
//! 本模块提供了网络流量过滤功能：
//! - Windows: 基于 Windows Filtering Platform (WFP) 的完整实现
//! - 其他平台: 提供模拟接口防止编译错误

pub use std::net::IpAddr;
use std::fmt;
use std::str::FromStr;
use flutter_rust_bridge::frb;

// Windows 平台特定导入
#[cfg(target_os = "windows")]
use std::{ffi::OsStr, os::windows::ffi::OsStringExt};
#[cfg(target_os = "windows")]
use std::os::windows::ffi::OsStrExt;
#[cfg(target_os = "windows")]
use std::ptr;
#[cfg(target_os = "windows")]
use windows::{
    Win32::Foundation::*, Win32::NetworkManagement::WindowsFilteringPlatform::*,
    Win32::System::Rpc::*, core::*,
};
#[cfg(target_os = "windows")]
pub use windows::core::GUID;

// 非Windows平台的GUID模拟
#[cfg(not(target_os = "windows"))]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GUID {
    pub data1: u32,
    pub data2: u16,
    pub data3: u16,
    pub data4: [u8; 8],
}


// Windows 平台特定常量
#[cfg(target_os = "windows")]
const FWP_ACTION_BLOCK: u32 = 0x00000001 | 0x00001000;
#[cfg(target_os = "windows")]
const FWP_ACTION_PERMIT: u32 = 0x00000002 | 0x00001000;

// 跨平台句柄类型
#[cfg(target_os = "windows")]
pub type PlatformHandle = HANDLE;

#[cfg(not(target_os = "windows"))]
pub type PlatformHandle = i32;
/// CIDR网段结构体，用于表示IP地址范围
#[derive(Debug, Clone)]
pub struct IpNetwork {
    pub ip: IpAddr,
    pub prefix_len: u8,
}

impl IpNetwork {
    /// 从CIDR格式字符串创建IP网段
    pub fn from_cidr(cidr: &str) -> std::result::Result<Self, String> {
        let parts: Vec<&str> = cidr.split('/').collect();
        if parts.len() != 2 {
            return Err("Invalid CIDR format".to_string());
        }
        
        let ip: IpAddr = parts[0].parse().map_err(|_| "Invalid IP address")?;
        let prefix_len: u8 = parts[1].parse().map_err(|_| "Invalid prefix length")?;
        
        let max_prefix = match ip {
            IpAddr::V4(_) => 32,
            IpAddr::V6(_) => 128,
        };
        
        if prefix_len > max_prefix {
            return Err(format!("Prefix length {} exceeds maximum {}", prefix_len, max_prefix));
        }
        
        // 将IP地址转换为正确的网络地址
        let network_ip = match ip {
            IpAddr::V4(ipv4) => {
                let ip_bytes = ipv4.octets();
                let ip_u32 = u32::from_be_bytes(ip_bytes);
                let mask = if prefix_len == 0 {
                    0u32
                } else if prefix_len == 32 {
                    u32::MAX
                } else {
                    !((1u32 << (32 - prefix_len)) - 1)
                };
                let network_u32 = ip_u32 & mask;
                let network_bytes = network_u32.to_be_bytes();
                IpAddr::V4(std::net::Ipv4Addr::from(network_bytes))
            },
            IpAddr::V6(_) => ip,
        };
        
        Ok(Self { ip: network_ip, prefix_len })
    }
}

/// 网络过滤规则结构体
#[derive(Debug, Clone)]
#[frb(opaque)]
pub struct FilterRule {
    pub name: String,
    pub app_path: Option<String>,
    pub local: Option<String>,
    pub remote: Option<String>,
    pub local_port: Option<u16>,
    pub remote_port: Option<u16>,
    pub local_port_range: Option<(u16, u16)>,
    pub remote_port_range: Option<(u16, u16)>,
    pub protocol: Option<Protocol>,
    pub direction: Direction,
    pub action: FilterAction,
    pub priority: u32,
    pub filter_ids: Vec<u64>,
}

/// 网络协议类型
#[derive(Debug, Clone, PartialEq)]
pub enum Protocol {
    Tcp,
    Udp,
}

impl fmt::Display for Protocol {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Protocol::Tcp => write!(f, "TCP"),
            Protocol::Udp => write!(f, "UDP"),
        }
    }
}

impl FromStr for Protocol {
    type Err = String;
    
    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "tcp" => Ok(Protocol::Tcp),
            "udp" => Ok(Protocol::Udp),
            _ => Err(format!("未知协议: {}", s)),
        }
    }
}

/// 网络流量方向
#[derive(Debug, Clone, PartialEq)]
pub enum Direction {
    Inbound,
    Outbound,
    Both,
}

/// 过滤动作类型
#[derive(Debug, Clone, PartialEq)]
pub enum FilterAction {
    Allow,
    Block,
}

impl FilterRule {
    // 带完整参数的构造函数，方便Dart端使用
    pub fn new_with_params(
        name: &str,
        app_path: Option<String>,
        local: Option<String>,
        remote: Option<String>,
        local_port: Option<u16>,
        remote_port: Option<u16>,
        local_port_range: Option<(u16, u16)>,
        remote_port_range: Option<(u16, u16)>,
        protocol: Option<Protocol>,
        direction: Direction,
        action: FilterAction,
        priority: Option<u32>,
        _description: Option<String>,
    ) -> Self {
        Self {
            name: name.to_string(),
            app_path,
            local,
            remote,
            local_port,
            remote_port,
            local_port_range,
            remote_port_range,
            protocol,
            direction,
            action,
            priority: priority.unwrap_or(200),
            filter_ids: Vec::new(),
        }
    }
    // 验证规则
    pub fn validate(&self) -> std::result::Result<(), String> {
        // 验证远程 IP
        if let Some(remote) = &self.remote {
            if remote.parse::<IpAddr>().is_err() && IpNetwork::from_cidr(remote).is_err() {
                return Err(format!("无法解析的 IP 地址格式: {}", remote));
            }
        }
        
        // 骮证本地 IP
        if let Some(local) = &self.local {
            if local.parse::<IpAddr>().is_err() && IpNetwork::from_cidr(local).is_err() {
                return Err(format!("无法解析的本地 IP 地址格式: {}", local));
            }
        }
        
        Ok(())
    }
}

// Windows 平台特定的字符串转换函数
#[cfg(target_os = "windows")]
pub fn to_wide_string(s: &str) -> Vec<u16> {
    OsStr::new(s)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect()
}

// 非Windows平台的字符串转换函数（模拟）
#[cfg(not(target_os = "windows"))]
pub fn to_wide_string(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

/// 跨平台网络流量过滤控制器
#[derive(Clone)]
#[frb(opaque)]
pub struct WfpController {
    engine_handle: PlatformHandle,
    pub filter_ids: Vec<u64>,
    #[cfg(not(target_os = "windows"))]
    platform_name: String,
}

impl std::fmt::Debug for WfpController {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("WfpController")
            .field("engine_handle", &"PlatformHandle")
            .field("filter_ids", &self.filter_ids)
            .finish()
    }
}

impl WfpController {
    pub fn new() -> anyhow::Result<Self> {
        Ok(Self {
            #[cfg(target_os = "windows")]
            engine_handle: HANDLE::default(),
            #[cfg(not(target_os = "windows"))]
            engine_handle: 0,
            filter_ids: Vec::new(),
            #[cfg(not(target_os = "windows"))]
            platform_name: std::env::consts::OS.to_string(),
        })
    }

    // 初始化过滤引擎
    pub fn initialize(&mut self) -> anyhow::Result<()> {
        #[cfg(target_os = "windows")]
        {
            self.initialize_windows()
        }
        #[cfg(not(target_os = "windows"))]
        {
            self.initialize_non_windows()
        }
    }

    // Windows 平台初始化
    #[cfg(target_os = "windows")]
    fn initialize_windows(&mut self) -> anyhow::Result<()> {
        unsafe {
            println!("正在初始化 Windows Filtering Platform...");

            let session_name = to_wide_string("AstralWFP Manager");
            let session_desc = to_wide_string("AstralWFP网络流量管理会话");

            let session = FWPM_SESSION0 {
                sessionKey: GUID::zeroed(),
                displayData: FWPM_DISPLAY_DATA0 {
                    name: PWSTR(session_name.as_ptr() as *mut u16),
                    description: PWSTR(session_desc.as_ptr() as *mut u16),
                },
                flags: FWPM_SESSION_FLAG_DYNAMIC,
                txnWaitTimeoutInMSec: 0,
                processId: 0,
                sid: std::ptr::null_mut(),
                username: PWSTR::null(),
                kernelMode: FALSE,
            };

            let result = FwpmEngineOpen0(
                None,
                RPC_C_AUTHN_DEFAULT as u32,
                None,
                Some(&session),
                &mut self.engine_handle,
            );

            if WIN32_ERROR(result) == ERROR_SUCCESS {
                println!("✓ WFP引擎打开成功！");
                Ok(())
            } else {
                println!("❌ 打开WFP引擎失败: {} (可能需要管理员权限)", result);
                Err(anyhow::anyhow!("打开WFP引擎失败"))
            }
        }
    }

    // 非Windows平台初始化
    #[cfg(not(target_os = "windows"))]
    fn initialize_non_windows(&mut self) -> anyhow::Result<()> {
        println!("正在初始化网络过滤器 (平台: {})...", self.platform_name);
        println!("⚠️ 当前平台不支持网络过滤功能，使用模拟模式");
        println!("✓ 模拟模式已启用");
        Ok(())
    }

    // 添加过滤器规则
    pub fn add_filters(&mut self, rules: &[FilterRule]) -> anyhow::Result<Vec<u64>> {
        #[cfg(target_os = "windows")]
        {
            self.add_filters_windows(rules)
        }
        #[cfg(not(target_os = "windows"))]
        {
            self.add_filters_non_windows(rules)
        }
    }

    // Windows 平台添加过滤器
    #[cfg(target_os = "windows")]
    fn add_filters_windows(&mut self, rules: &[FilterRule]) -> anyhow::Result<Vec<u64>> {
        let mut added_ids = Vec::new();
        let mut added_count = 0;
        
        for rule in rules {
            println!("🔍 处理规则: {}", rule.name);
            
            if let Err(e) = rule.validate() {
                println!("❌ 规则验证失败: {}", e);
                continue;
            }
            
            let layers = self.get_layers_for_rule(rule);
            for layer in layers {
                match self.add_network_filter(rule, layer) {
                    Ok(filter_id) => {
                        self.filter_ids.push(filter_id);
                        added_ids.push(filter_id);
                        added_count += 1;
                        println!("✅ 过滤器在层 {} 上添加成功 (ID: {})", self.get_layer_name(&layer), filter_id);
                    },
                    Err(e) => {
                        println!("❌ 过滤器在层 {} 上添加失败: {:?}", self.get_layer_name(&layer), e);
                    }
                }
            }
        }

        if added_count > 0 {
            println!("🔍 网络流量控制已启动，共添加了 {} 个过滤器", added_count);
            Ok(added_ids)
        } else {
            println!("❌ 没有成功添加任何过滤器");
            Err(anyhow::anyhow!("没有成功添加任何过滤器"))
        }
    }

    // 非Windows平台添加过滤器（模拟）
    #[cfg(not(target_os = "windows"))]
    fn add_filters_non_windows(&mut self, rules: &[FilterRule]) -> anyhow::Result<Vec<u64>> {
        let mut added_ids = Vec::new();
        
        for (i, rule) in rules.iter().enumerate() {
            if let Err(e) = rule.validate() {
                println!("❌ 规则验证失败: {}", e);
                continue;
            }
            
            let mock_id = (i + 1) as u64;
            self.filter_ids.push(mock_id);
            added_ids.push(mock_id);
            println!("🔍 模拟添加规则 '{}' (ID: {})", rule.name, mock_id);
        }
        
        println!("✓ 模拟模式：已添加 {} 个过滤器", added_ids.len());
        Ok(added_ids)
    }
    /// 获取适用于规则的WFP层
    /// 
    /// 根据过滤规则的特性选择合适的WFP层：
    /// - 如果有应用程序路径，使用ALE层进行应用程序级别的过滤
    /// - 如果没有应用程序路径，使用传输层进行网络级别的过滤
    /// - 对于包含远程端口条件的规则，避免使用ALE_RESOURCE_ASSIGNMENT层
    ///   因为该层不支持远程端口条件（会导致FWP_E_CONDITION_NOT_FOUND错误）
    #[cfg(target_os = "windows")]
    fn get_layers_for_rule(&self, rule: &FilterRule) -> Vec<GUID> {
        let mut layers = Vec::new();
        let is_ipv6 = rule.local.as_ref().map_or(false, |ip| ip.contains(":")) || 
                     rule.remote.as_ref().map_or(false, |ip| ip.contains(":"));
        
        // 如果有应用程序路径，使用ALE层进行应用程序级别的过滤
        if rule.app_path.is_some() {
            println!("🎯 检测到应用程序路径，使用ALE层+传输层进行应用程序过滤");
            
            // 对于应用程序级别的过滤，使用更全面的层组合
            if !is_ipv6 {
                // IPv4 应用程序过滤
                match rule.direction {
                    Direction::Outbound => {
                        // 出站连接：拦截应用程序发起的连接
                        layers.push(FWPM_LAYER_ALE_AUTH_CONNECT_V4);
                        // 额外的流量控制层
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4);
                        // 端点关闭层（确保连接完全被控制）
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4);
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V4);
                    },
                    Direction::Inbound => {
                        // 入站连接：拦截应用程序接收的连接
                        layers.push(FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4);
                        // 监听层（控制应用程序的监听端口）
                        layers.push(FWPM_LAYER_ALE_AUTH_LISTEN_V4);
                        // 流量控制层
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4);
                        // 端点关闭层
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4);
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V4);
                    },
                    Direction::Both => {
                        // 双向控制：完全控制应用程序的所有网络活动
                        layers.push(FWPM_LAYER_ALE_AUTH_CONNECT_V4);        // 出站连接
                        layers.push(FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4);    // 入站连接
                        layers.push(FWPM_LAYER_ALE_AUTH_LISTEN_V4);         // 监听端口
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4);    // 已建立的流量
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4);    // 端点关闭
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V4);
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V4);
                        
                        // 只有在没有远程端口条件时才添加资源分配层
                        // ALE_RESOURCE_ASSIGNMENT 层不支持远程端口条件
                        if rule.remote_port.is_none() && rule.remote_port_range.is_none() {
                            layers.push(FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4);
                        }
                    }
                }
            } else {
                // IPv6 应用程序过滤
                match rule.direction {
                    Direction::Outbound => {
                        layers.push(FWPM_LAYER_ALE_AUTH_CONNECT_V6);
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6);
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6);
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V6);
                    },
                    Direction::Inbound => {
                        layers.push(FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6);
                        layers.push(FWPM_LAYER_ALE_AUTH_LISTEN_V6);
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6);
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6);
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V6);
                    },
                    Direction::Both => {
                        layers.push(FWPM_LAYER_ALE_AUTH_CONNECT_V6);
                        layers.push(FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6);
                        layers.push(FWPM_LAYER_ALE_AUTH_LISTEN_V6);
                        layers.push(FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6);
                        layers.push(FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6);
                        // 添加传输层以控制已建立连接的数据包
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V6);
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V6);
                        
                        // 只有在没有远程端口条件时才添加资源分配层
                        // ALE_RESOURCE_ASSIGNMENT 层不支持远程端口条件
                        if rule.remote_port.is_none() && rule.remote_port_range.is_none() {
                            layers.push(FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6);
                        }
                    }
                }
            }
        } else {
            println!("🌐 未指定应用程序路径，使用网络层进行IP过滤");
            // 如果没有应用程序路径，使用传输层进行更精确的控制
            match rule.direction {
                Direction::Outbound => {
                    if is_ipv6 {
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V6);
                    } else {
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V4);
                    }
                },
                Direction::Inbound => {
                    if is_ipv6 {
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V6);
                    } else {
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V4);
                    }
                },
                Direction::Both => {
                    if is_ipv6 {
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V6);
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V6);
                    } else {
                        layers.push(FWPM_LAYER_OUTBOUND_TRANSPORT_V4);
                        layers.push(FWPM_LAYER_INBOUND_TRANSPORT_V4);
                    }
                }
            }
        }
        
        println!("📋 选择的WFP层 ({} 个): {:?}", layers.len(), layers.iter().map(|l| self.get_layer_name(l)).collect::<Vec<_>>());
        layers
    }

    // 清理过滤器
    pub fn cleanup(&mut self) -> anyhow::Result<()> {
        #[cfg(target_os = "windows")]
        {
            self.cleanup_windows()
        }
        #[cfg(not(target_os = "windows"))]
        {
            self.cleanup_non_windows()
        }
    }

    // Windows平台清理
    #[cfg(target_os = "windows")]
    fn cleanup_windows(&mut self) -> anyhow::Result<()> {
        unsafe {
            println!("🛑 停止过滤器，正在清理...");

            for filter_id in &self.filter_ids {
                let delete_result = FwpmFilterDeleteById0(self.engine_handle, *filter_id);
                if WIN32_ERROR(delete_result) == ERROR_SUCCESS {
                    println!("✓ 过滤器 {} 已删除", filter_id);
                } else {
                    println!("⚠️ 删除过滤器 {} 失败: {}", filter_id, delete_result);
                }
            }

            let result = FwpmEngineClose0(self.engine_handle);
            if WIN32_ERROR(result) != ERROR_SUCCESS {
                println!("❌ 关闭WFP引擎失败: {}", result);
                return Err(anyhow::anyhow!("关闭WFP引擎失败"));
            }
            println!("✓ WFP引擎已关闭");
            Ok(())
        }
    }

    // 非Windows平台清理（模拟）
    #[cfg(not(target_os = "windows"))]
    fn cleanup_non_windows(&mut self) -> anyhow::Result<()> {
        println!("🛑 停止过滤器，正在清理...");
        for filter_id in &self.filter_ids {
            println!("✓ 模拟删除过滤器 {}", filter_id);
        }
        self.filter_ids.clear();
        println!("✓ 模拟模式清理完成");
        Ok(())
    }

    // 添加网络过滤器的内部方法 - 仅Windows
    #[cfg(target_os = "windows")]
    fn add_network_filter(
        &self,
        rule: &FilterRule,
        layer_key: GUID,
    ) -> anyhow::Result<u64> {
        let filter_name = to_wide_string(&rule.name);
        let filter_desc = to_wide_string(&format!("控制 {} 的网络流量", rule.name));

        let mut conditions = Vec::new();
        
        // 在函数开始处声明这些变量，确保它们在整个函数生命周期内有效
        let mut appid_utf16: Option<Vec<u16>> = None;
        let mut app_id_blob: Option<FWP_BYTE_BLOB> = None;
        let mut local_port_range: Option<FWP_RANGE0> = None;
        let mut remote_port_range: Option<FWP_RANGE0> = None;
        
        // 根据层类型决定是否添加某些条件
        let layer_name = self.get_layer_name(&layer_key);
        let supports_app_id = matches!(layer_key, 
            FWPM_LAYER_ALE_AUTH_CONNECT_V4 | FWPM_LAYER_ALE_AUTH_CONNECT_V6 |
            FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4 | FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6 |
            FWPM_LAYER_ALE_AUTH_LISTEN_V4 | FWPM_LAYER_ALE_AUTH_LISTEN_V6 |
            FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4 | FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6 |
            FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4 | FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6 |
            FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 | FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6
        );
        
        println!("🔧 处理层: {} (支持APP_ID: {})", layer_name, supports_app_id);
        
        // 添加应用程序路径条件
        if let Some(app_path) = &rule.app_path {
            if supports_app_id {
                println!("🔍 处理应用程序路径: {}", app_path);
                
                // 使用to_wide_string函数，它会添加null终止符
                let utf16_path = to_wide_string(app_path);
                
                // 创建FWP_BYTE_BLOB结构，size包含null终止符
                let blob = FWP_BYTE_BLOB {
                    size: (utf16_path.len() * 2) as u32,
                    data: utf16_path.as_ptr() as *mut u8,
                };
                
                println!("📦 应用程序ID blob大小: {} 字节", blob.size);
                println!("📦 应用程序路径UTF-16长度: {} 字符", utf16_path.len());
                
                // 打印十六进制数据用于调试
                println!("📦 应用程序路径十六进制数据:");
                let bytes = unsafe { std::slice::from_raw_parts(blob.data, blob.size as usize) };
                for (i, chunk) in bytes.chunks(16).enumerate() {
                    print!("  {:04x}: ", i * 16);
                    for byte in chunk {
                        print!("{:02x} ", byte);
                    }
                    println!();
                }
                
                // 添加应用程序ID过滤条件
                conditions.push(FWPM_FILTER_CONDITION0 {
                    fieldKey: FWPM_CONDITION_ALE_APP_ID,
                    matchType: FWP_MATCH_EQUAL,
                    conditionValue: FWP_CONDITION_VALUE0 {
                        r#type: FWP_BYTE_BLOB_TYPE,
                        Anonymous: FWP_CONDITION_VALUE0_0 {
                            byteBlob: &blob as *const _ as *mut _,
                        },
                    },
                });
                
                // 保存数据确保生命周期
                appid_utf16 = Some(utf16_path);
                app_id_blob = Some(blob);
                
                println!("✅ 应用程序条件已添加");
            } else {
                println!("⚠️ 层 {} 不支持应用程序ID条件，跳过应用程序路径处理", layer_name);
                // 对于不支持APP_ID的层，如果只有应用程序路径条件，则跳过此层
                if rule.local.is_none() && rule.remote.is_none() && 
                   rule.local_port.is_none() && rule.remote_port.is_none() &&
                   rule.local_port_range.is_none() && rule.remote_port_range.is_none() &&
                   rule.protocol.is_none() {
                    println!("⚠️ 层 {} 上没有其他可用条件，跳过此过滤器", layer_name);
                    return Err(anyhow::anyhow!("层不支持所需条件"));
                }
            }
        } else {
            println!("📝 未指定应用程序路径，规则将应用于所有程序");
        }
        
        // 添加本地IP条件
        if let Some(local) = &rule.local {
            self.add_ip_condition(&mut conditions, local, FWPM_CONDITION_IP_LOCAL_ADDRESS);
        }
        
        // 添加远程IP条件
        if let Some(remote) = &rule.remote {
            self.add_ip_condition(&mut conditions, remote, FWPM_CONDITION_IP_REMOTE_ADDRESS);
        }
        
        // 添加端口条件
        if let Some(local_port) = rule.local_port {
            conditions.push(FWPM_FILTER_CONDITION0 {
                fieldKey: FWPM_CONDITION_IP_LOCAL_PORT,
                matchType: FWP_MATCH_EQUAL,
                conditionValue: FWP_CONDITION_VALUE0 {
                    r#type: FWP_UINT16,
                    Anonymous: FWP_CONDITION_VALUE0_0 {
                        uint16: local_port,
                    },
                },
            });
        } else if let Some((start_port, end_port)) = rule.local_port_range {
            let range = FWP_RANGE0 {
                valueLow: FWP_VALUE0 {
                    r#type: FWP_UINT16,
                    Anonymous: FWP_VALUE0_0 {
                        uint16: start_port,
                    },
                },
                valueHigh: FWP_VALUE0 {
                    r#type: FWP_UINT16,
                    Anonymous: FWP_VALUE0_0 {
                        uint16: end_port,
                    },
                },
            };
            
            local_port_range = Some(range);
            
            conditions.push(FWPM_FILTER_CONDITION0 {
                fieldKey: FWPM_CONDITION_IP_LOCAL_PORT,
                matchType: FWP_MATCH_RANGE,
                conditionValue: FWP_CONDITION_VALUE0 {
                    r#type: FWP_RANGE_TYPE,
                    Anonymous: FWP_CONDITION_VALUE0_0 {
                        rangeValue: local_port_range.as_ref().unwrap() as *const _ as *mut _,
                    },
                },
            });
        }
        
        // 检查层是否支持远程端口条件
        let supports_remote_port = !matches!(layer_key, 
            FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 | FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6
        );
        
        if let Some(remote_port) = rule.remote_port {
            if supports_remote_port {
                conditions.push(FWPM_FILTER_CONDITION0 {
                    fieldKey: FWPM_CONDITION_IP_REMOTE_PORT,
                    matchType: FWP_MATCH_EQUAL,
                    conditionValue: FWP_CONDITION_VALUE0 {
                        r#type: FWP_UINT16,
                        Anonymous: FWP_CONDITION_VALUE0_0 {
                            uint16: remote_port,
                        },
                    },
                });
            } else {
                println!("⚠️ 层 {} 不支持远程端口条件，跳过远程端口 {}", layer_name, remote_port);
            }
        } else if let Some((start_port, end_port)) = rule.remote_port_range {
            if supports_remote_port {
                let range = FWP_RANGE0 {
                    valueLow: FWP_VALUE0 {
                        r#type: FWP_UINT16,
                        Anonymous: FWP_VALUE0_0 {
                            uint16: start_port,
                        },
                    },
                    valueHigh: FWP_VALUE0 {
                        r#type: FWP_UINT16,
                        Anonymous: FWP_VALUE0_0 {
                            uint16: end_port,
                        },
                    },
                };
                
                remote_port_range = Some(range);
                
                conditions.push(FWPM_FILTER_CONDITION0 {
                    fieldKey: FWPM_CONDITION_IP_REMOTE_PORT,
                    matchType: FWP_MATCH_RANGE,
                    conditionValue: FWP_CONDITION_VALUE0 {
                        r#type: FWP_RANGE_TYPE,
                        Anonymous: FWP_CONDITION_VALUE0_0 {
                            rangeValue: remote_port_range.as_ref().unwrap() as *const _ as *mut _,
                        },
                    },
                });
            } else {
                println!("⚠️ 层 {} 不支持远程端口条件，跳过远程端口范围 {}-{}", layer_name, start_port, end_port);
            }
        }
        
        // 添加协议条件
        if let Some(protocol) = &rule.protocol {
            let protocol_value = match protocol {
                Protocol::Tcp => 6u8,
                Protocol::Udp => 17u8,
            };
            
            conditions.push(FWPM_FILTER_CONDITION0 {
                fieldKey: FWPM_CONDITION_IP_PROTOCOL,
                matchType: FWP_MATCH_EQUAL,
                conditionValue: FWP_CONDITION_VALUE0 {
                    r#type: FWP_UINT8,
                    Anonymous: FWP_CONDITION_VALUE0_0 {
                        uint8: protocol_value,
                    },
                },
            });
        }
        
        let num_conditions = conditions.len() as u32;
        let action_type = match rule.action {
            FilterAction::Allow => FWP_ACTION_PERMIT,
            FilterAction::Block => FWP_ACTION_BLOCK,
        };
        
        println!("🔧 过滤器配置:");
        println!("  📝 名称: {}", rule.name);
        println!("  📁 应用程序路径: {:?}", rule.app_path);
        println!("  🏠 本地地址: {:?}", rule.local);
        println!("  🌐 远程地址: {:?}", rule.remote);
        println!("  🔌 本地端口: {:?}", rule.local_port);
        println!("  🔌 远程端口: {:?}", rule.remote_port);
        println!("  📊 本地端口范围: {:?}", rule.local_port_range);
        println!("  📊 远程端口范围: {:?}", rule.remote_port_range);
        println!("  📡 协议: {:?}", rule.protocol);
        println!("  ➡️ 方向: {:?}", rule.direction);
        println!("  🎯 动作: {:?}", rule.action);
        println!("  ⚡ 优先级: {}", rule.priority);
        println!("  🔢 条件数量: {}", num_conditions);
        println!("  🎯 动作类型: {}", if action_type == FWP_ACTION_PERMIT { "允许" } else { "阻止" });

        let filter = FWPM_FILTER0 {
            filterKey: GUID::zeroed(),
            displayData: FWPM_DISPLAY_DATA0 {
                name: PWSTR(filter_name.as_ptr() as *mut u16),
                description: PWSTR(filter_desc.as_ptr() as *mut u16),
            },
            flags: FWPM_FILTER_FLAGS(0),
            providerKey: ptr::null_mut(),
            providerData: FWP_BYTE_BLOB {
                size: 0,
                data: ptr::null_mut(),
            },
            layerKey: layer_key,
            subLayerKey: FWPM_SUBLAYER_UNIVERSAL,
            weight: FWP_VALUE0 {
                r#type: FWP_UINT64,
                Anonymous: FWP_VALUE0_0 {
                    uint64: &(rule.priority as u64) as *const u64 as *mut u64,
                },
            },
            numFilterConditions: num_conditions,
            filterCondition: if num_conditions > 0 {
                conditions.as_ptr() as *mut _
            } else {
                ptr::null_mut()
            },
            action: FWPM_ACTION0 {
                r#type: FWP_ACTION_TYPE(action_type),
                Anonymous: FWPM_ACTION0_0 {
                    calloutKey: GUID::zeroed(),
                },
            },
            Anonymous: FWPM_FILTER0_0 {
                rawContext: 0,
            },
            reserved: ptr::null_mut(),
            filterId: 0,
            effectiveWeight: FWP_VALUE0 {
                r#type: FWP_UINT64,
                Anonymous: FWP_VALUE0_0 {
                    uint64: &(rule.priority as u64) as *const u64 as *mut u64,
                },
            },
        };

        let mut filter_id = 0u64;
        
        // 确保应用程序ID数据在整个过滤器添加过程中有效
        let add_result = unsafe {
            if let (Some(utf16_data), Some(_blob_data)) = (&appid_utf16, &app_id_blob) {
                // 创建新的blob，确保指针有效
                let fresh_blob = FWP_BYTE_BLOB {
                    size: (utf16_data.len() * 2) as u32,
                    data: utf16_data.as_ptr() as *mut u8,
                };
                
                // 重新创建所有条件
                let mut updated_conditions = Vec::new();
                
                for condition in &conditions {
                    if condition.fieldKey == FWPM_CONDITION_ALE_APP_ID {
                        // 重新创建应用程序ID条件
                        updated_conditions.push(FWPM_FILTER_CONDITION0 {
                            fieldKey: FWPM_CONDITION_ALE_APP_ID,
                            matchType: FWP_MATCH_EQUAL,
                            conditionValue: FWP_CONDITION_VALUE0 {
                                r#type: FWP_BYTE_BLOB_TYPE,
                                Anonymous: FWP_CONDITION_VALUE0_0 {
                                    byteBlob: &fresh_blob as *const _ as *mut _,
                                },
                            },
                        });
                    } else {
                        updated_conditions.push(*condition);
                    }
                }
                
                // 创建新的过滤器结构
                let updated_filter = FWPM_FILTER0 {
                    filterKey: GUID::zeroed(),
                    displayData: FWPM_DISPLAY_DATA0 {
                        name: PWSTR(filter_name.as_ptr() as *mut u16),
                        description: PWSTR(filter_desc.as_ptr() as *mut u16),
                    },
                    flags: FWPM_FILTER_FLAGS(0),
                    providerKey: ptr::null_mut(),
                    providerData: FWP_BYTE_BLOB {
                        size: 0,
                        data: ptr::null_mut(),
                    },
                    layerKey: layer_key,
                    subLayerKey: FWPM_SUBLAYER_UNIVERSAL,
                    weight: FWP_VALUE0 {
                        r#type: FWP_UINT64,
                        Anonymous: FWP_VALUE0_0 {
                            uint64: &(rule.priority as u64) as *const u64 as *mut u64,
                        },
                    },
                    numFilterConditions: updated_conditions.len() as u32,
                    filterCondition: if !updated_conditions.is_empty() {
                        updated_conditions.as_ptr() as *mut _
                    } else {
                        ptr::null_mut()
                    },
                    action: FWPM_ACTION0 {
                        r#type: FWP_ACTION_TYPE(action_type),
                        Anonymous: FWPM_ACTION0_0 {
                            calloutKey: GUID::zeroed(),
                        },
                    },
                    Anonymous: FWPM_FILTER0_0 {
                        rawContext: 0,
                    },
                    reserved: ptr::null_mut(),
                    filterId: 0,
                    effectiveWeight: FWP_VALUE0 {
                        r#type: FWP_UINT64,
                        Anonymous: FWP_VALUE0_0 {
                            uint64: &(rule.priority as u64) as *const u64 as *mut u64,
                        },
                    },
                };
                
                // 添加调试信息
                println!("🔍 应用程序ID调试信息:");
                println!("  - 路径: {}", rule.app_path.as_ref().unwrap());
                println!("  - UTF-16字符数: {}", utf16_data.len());
                println!("  - 字节大小: {}", fresh_blob.size);
                println!("  - 数据指针: {:p}", fresh_blob.data);
                
                // 打印实际的字符串内容
                let wide_str = std::ffi::OsString::from_wide(&utf16_data[..utf16_data.len()-1]); // 去掉null终止符
                println!("  - 重建的字符串: {:?}", wide_str);
                
                FwpmFilterAdd0(self.engine_handle, &updated_filter, None, Some(&mut filter_id))
            } else {
                // 没有应用程序路径，使用原始过滤器
                FwpmFilterAdd0(self.engine_handle, &filter, None, Some(&mut filter_id))
            }
        };

        if WIN32_ERROR(add_result) == ERROR_SUCCESS {
            Ok(filter_id)
        } else {
            let error_msg = match add_result {
                0x80320002 => {
                    // FWP_E_CONDITION_NOT_FOUND - 过滤器条件不存在
                    let layer_name = self.get_layer_name(&layer_key);
                    let mut unsupported_conditions = Vec::new();
                    
                    // 检查哪些条件可能不被支持
                    if rule.remote_port.is_some() || rule.remote_port_range.is_some() {
                        if layer_name.contains("RESOURCE_ASSIGNMENT") {
                            unsupported_conditions.push("远程端口条件在ALE_RESOURCE_ASSIGNMENT层不被支持");
                        }
                    }
                    
                    if unsupported_conditions.is_empty() {
                        format!("过滤器条件不存在 - 层 '{}' 不支持指定的条件组合", layer_name)
                    } else {
                        format!("过滤器条件不兼容 - {}", unsupported_conditions.join(", "))
                    }
                },
                _ => {
                    match WIN32_ERROR(add_result) {
                        ERROR_ACCESS_DENIED => "访问被拒绝 - 需要管理员权限",
                        ERROR_INVALID_PARAMETER => "无效参数 - 检查过滤条件组合",
                        ERROR_NOT_SUPPORTED => "不支持的操作 - 检查WFP层和条件兼容性",
                        ERROR_ALREADY_EXISTS => "过滤器已存在",
                        ERROR_NOT_FOUND => "找不到指定的层或条件",
                        _ => "未知错误",
                    }.to_string()
                }
            };
            println!("❌ 添加过滤器 '{}' 失败: {} (错误代码: 0x{:08X})", rule.name, error_msg, add_result);
            Err(anyhow::anyhow!("添加过滤器失败: {}", error_msg))
        }
    }

    // 添加IP条件的辅助方法 - 仅Windows
    #[cfg(target_os = "windows")]
    fn add_ip_condition(&self, conditions: &mut Vec<FWPM_FILTER_CONDITION0>, ip_str: &str, field_key: GUID) {
        if let Ok(ip) = ip_str.parse::<IpAddr>() {
            match ip {
                IpAddr::V4(ipv4) => {
                    let ip_bytes = ipv4.octets();
                    let ip_value = u32::from_be_bytes(ip_bytes);
                    
                    conditions.push(FWPM_FILTER_CONDITION0 {
                        fieldKey: field_key,
                        matchType: FWP_MATCH_EQUAL,
                        conditionValue: FWP_CONDITION_VALUE0 {
                            r#type: FWP_UINT32,
                            Anonymous: FWP_CONDITION_VALUE0_0 {
                                uint32: ip_value,
                            },
                        },
                    });
                },
                IpAddr::V6(ipv6) => {
                    let ip_bytes = ipv6.octets();
                    let byte_array = FWP_BYTE_ARRAY16 {
                        byteArray16: ip_bytes,
                    };
                    
                    conditions.push(FWPM_FILTER_CONDITION0 {
                        fieldKey: field_key,
                        matchType: FWP_MATCH_EQUAL,
                        conditionValue: FWP_CONDITION_VALUE0 {
                            r#type: FWP_BYTE_ARRAY16_TYPE,
                            Anonymous: FWP_CONDITION_VALUE0_0 {
                                byteArray16: &byte_array as *const _ as *mut _,
                            },
                        },
                    });
                }
            }
        } else if let Ok(network) = IpNetwork::from_cidr(ip_str) {
            match network.ip {
                IpAddr::V4(network_ip) => {
                    let network_bytes = network_ip.octets();
                    let mask = if network.prefix_len == 0 {
                        0u32
                    } else if network.prefix_len == 32 {
                        u32::MAX
                    } else {
                        !((1u32 << (32 - network.prefix_len)) - 1)
                    };
                    let network_addr = u32::from_be_bytes(network_bytes) & mask;
                    
                    let range = FWP_RANGE0 {
                        valueLow: FWP_VALUE0 {
                            r#type: FWP_UINT32,
                            Anonymous: FWP_VALUE0_0 {
                                uint32: network_addr,
                            },
                        },
                        valueHigh: FWP_VALUE0 {
                            r#type: FWP_UINT32,
                            Anonymous: FWP_VALUE0_0 {
                                uint32: network_addr | !mask,
                            },
                        },
                    };
                    
                    conditions.push(FWPM_FILTER_CONDITION0 {
                        fieldKey: field_key,
                        matchType: FWP_MATCH_RANGE,
                        conditionValue: FWP_CONDITION_VALUE0 {
                            r#type: FWP_RANGE_TYPE,
                            Anonymous: FWP_CONDITION_VALUE0_0 {
                                rangeValue: &range as *const _ as *mut _,
                            },
                        },
                    });
                },
                IpAddr::V6(_) => {
                    println!("⚠️ IPv6网段过滤暂不支持");
                }
            }
        }
    }

    // 获取层的名称用于调试
    pub fn get_layer_name(&self, layer_key: &GUID) -> &'static str {
        #[cfg(target_os = "windows")]
        {
            match *layer_key {
                // ALE (Application Layer Enforcement) 层
                FWPM_LAYER_ALE_AUTH_CONNECT_V4 => "ALE_AUTH_CONNECT_V4",
                FWPM_LAYER_ALE_AUTH_CONNECT_V6 => "ALE_AUTH_CONNECT_V6",
                FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4 => "ALE_AUTH_RECV_ACCEPT_V4",
                FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6 => "ALE_AUTH_RECV_ACCEPT_V6",
                FWPM_LAYER_ALE_AUTH_LISTEN_V4 => "ALE_AUTH_LISTEN_V4",
                FWPM_LAYER_ALE_AUTH_LISTEN_V6 => "ALE_AUTH_LISTEN_V6",
                FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4 => "ALE_FLOW_ESTABLISHED_V4",
                FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6 => "ALE_FLOW_ESTABLISHED_V6",
                FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4 => "ALE_ENDPOINT_CLOSURE_V4",
                FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6 => "ALE_ENDPOINT_CLOSURE_V6",
                FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 => "ALE_RESOURCE_ASSIGNMENT_V4",
                FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6 => "ALE_RESOURCE_ASSIGNMENT_V6",
                
                // 传输层
                FWPM_LAYER_OUTBOUND_TRANSPORT_V4 => "OUTBOUND_TRANSPORT_V4",
                FWPM_LAYER_OUTBOUND_TRANSPORT_V6 => "OUTBOUND_TRANSPORT_V6",
                FWPM_LAYER_INBOUND_TRANSPORT_V4 => "INBOUND_TRANSPORT_V4",
                FWPM_LAYER_INBOUND_TRANSPORT_V6 => "INBOUND_TRANSPORT_V6",
                
                // 网络层
                FWPM_LAYER_OUTBOUND_IPPACKET_V4 => "OUTBOUND_IPPACKET_V4",
                FWPM_LAYER_OUTBOUND_IPPACKET_V6 => "OUTBOUND_IPPACKET_V6",
                FWPM_LAYER_INBOUND_IPPACKET_V4 => "INBOUND_IPPACKET_V4",
                FWPM_LAYER_INBOUND_IPPACKET_V6 => "INBOUND_IPPACKET_V6",
                
                // DISCARD 层 - 用于检查被丢弃的数据包
                FWPM_LAYER_ALE_AUTH_CONNECT_DISCARD_V4 => "ALE_AUTH_CONNECT_DISCARD_V4",
                FWPM_LAYER_ALE_AUTH_CONNECT_DISCARD_V6 => "ALE_AUTH_CONNECT_DISCARD_V6",
                FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_DISCARD_V4 => "ALE_AUTH_RECV_ACCEPT_DISCARD_V4",
                FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_DISCARD_V6 => "ALE_AUTH_RECV_ACCEPT_DISCARD_V6",
                FWPM_LAYER_ALE_AUTH_LISTEN_DISCARD_V4 => "ALE_AUTH_LISTEN_DISCARD_V4",
                FWPM_LAYER_ALE_AUTH_LISTEN_DISCARD_V6 => "ALE_AUTH_LISTEN_DISCARD_V6",
                
                // STREAM 层 - 用于流数据检查
                FWPM_LAYER_STREAM_V4 => "STREAM_V4",
                FWPM_LAYER_STREAM_V6 => "STREAM_V6",
                FWPM_LAYER_STREAM_V4_DISCARD => "STREAM_V4_DISCARD",
                FWPM_LAYER_STREAM_V6_DISCARD => "STREAM_V6_DISCARD",
                
                // ICMP 错误层
                FWPM_LAYER_OUTBOUND_ICMP_ERROR_V4 => "OUTBOUND_ICMP_ERROR_V4",
                FWPM_LAYER_OUTBOUND_ICMP_ERROR_V6 => "OUTBOUND_ICMP_ERROR_V6",
                FWPM_LAYER_INBOUND_ICMP_ERROR_V4 => "INBOUND_ICMP_ERROR_V4",
                FWPM_LAYER_INBOUND_ICMP_ERROR_V6 => "INBOUND_ICMP_ERROR_V6",
                
                _ => "UNKNOWN_LAYER",
            }
        }
        #[cfg(not(target_os = "windows"))]
        {
            "MOCK_LAYER"
        }
    }

    // 删除过滤器
    pub fn delete_filters(&mut self, filter_ids: &[u64]) -> anyhow::Result<u32> {
        #[cfg(target_os = "windows")]
        {
            self.delete_filters_windows(filter_ids)
        }
        #[cfg(not(target_os = "windows"))]
        {
            self.delete_filters_non_windows(filter_ids)
        }
    }

    // Windows平台删除过滤器
    #[cfg(target_os = "windows")]
    fn delete_filters_windows(&mut self, filter_ids: &[u64]) -> anyhow::Result<u32> {
        unsafe {
            let mut deleted_count = 0;
            
            for &filter_id in filter_ids {
                let delete_result = FwpmFilterDeleteById0(self.engine_handle, filter_id);
                if WIN32_ERROR(delete_result) == ERROR_SUCCESS {
                    if let Some(pos) = self.filter_ids.iter().position(|&id| id == filter_id) {
                        self.filter_ids.remove(pos);
                    }
                    deleted_count += 1;
                    println!("✓ 过滤器 {} 已删除", filter_id);
                } else {
                    println!("⚠️ 删除过滤器 {} 失败: {}", filter_id, delete_result);
                }
            }
            
            if deleted_count > 0 {
                Ok(deleted_count)
            } else {
                Err(anyhow::anyhow!("没有删除任何过滤器"))
            }
        }
    }

    // 非Windows平台删除过滤器（模拟）
    #[cfg(not(target_os = "windows"))]
    fn delete_filters_non_windows(&mut self, filter_ids: &[u64]) -> anyhow::Result<u32> {
        let mut deleted_count = 0;
        
        for &filter_id in filter_ids {
            if let Some(pos) = self.filter_ids.iter().position(|&id| id == filter_id) {
                self.filter_ids.remove(pos);
                deleted_count += 1;
                println!("✓ 模拟删除过滤器 {}", filter_id);
            } else {
                println!("⚠️ 未找到过滤器 {}", filter_id);
            }
        }
        
        Ok(deleted_count)
    }

    /// 验证过滤规则与WFP层的兼容性
    /// 
    /// 检查指定的过滤规则是否与给定的WFP层兼容，
    /// 避免在不支持的层上使用不兼容的条件
    #[cfg(target_os = "windows")]
    fn validate_rule_layer_compatibility(&self, rule: &FilterRule, layer_key: &GUID) -> anyhow::Result<()> {
        let layer_name = self.get_layer_name(layer_key);
        let mut errors = Vec::new();
        
        // 检查ALE_RESOURCE_ASSIGNMENT层的限制
        if matches!(*layer_key, FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 | FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6) {
            if rule.remote_port.is_some() {
                errors.push(format!("层 {} 不支持远程端口条件", layer_name));
            }
            if rule.remote_port_range.is_some() {
                errors.push(format!("层 {} 不支持远程端口范围条件", layer_name));
            }
        }
        
        // 检查应用程序ID支持
        let supports_app_id = matches!(*layer_key, 
            FWPM_LAYER_ALE_AUTH_CONNECT_V4 | FWPM_LAYER_ALE_AUTH_CONNECT_V6 |
            FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4 | FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6 |
            FWPM_LAYER_ALE_AUTH_LISTEN_V4 | FWPM_LAYER_ALE_AUTH_LISTEN_V6 |
            FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4 | FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6 |
            FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4 | FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6 |
            FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 | FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6
        );
        
        if rule.app_path.is_some() && !supports_app_id {
            errors.push(format!("层 {} 不支持应用程序ID条件", layer_name));
        }
        
        if errors.is_empty() {
            Ok(())
        } else {
            Err(anyhow::anyhow!("规则与层不兼容: {}", errors.join("; ")))
        }
    }

}