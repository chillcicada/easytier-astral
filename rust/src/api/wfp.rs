use serde::{Deserialize, Serialize};
use std::ffi::{CString, OsStr};
use std::os::windows::ffi::OsStrExt;
use std::ptr;
use windows::Win32::NetworkManagement::WindowsFilteringPlatform::{
    FWPM_ACTION0_0, FWPM_FILTER_FLAGS, FWP_BYTE_BLOB, FWP_CONDITION_VALUE0_0, FWP_VALUE0,
    FWP_VALUE0_0,
};
use windows::Win32::System::Rpc::RPC_C_AUTHN_DEFAULT;
use windows::Win32::System::Threading::GetCurrentProcessId;
use windows::{
    core::*,
    Win32::{
        Foundation::*,
        NetworkManagement::WindowsFilteringPlatform::{
            FwpmEngineClose0,
            FwpmEngineOpen0,
            FwpmFilterAdd0,
            FwpmFilterCreateEnumHandle0,
            FwpmFilterDeleteById0,
            FwpmFilterDestroyEnumHandle0,
            FwpmFilterEnum0,
            FwpmFreeMemory0,
            FWPM_ACTION0,
            FWPM_CONDITION_ALE_APP_ID,
            FWPM_DISPLAY_DATA0,
            FWPM_FILTER0,
            FWPM_FILTER_CONDITION0,
            FWPM_FILTER_ENUM_TEMPLATE0,
            // 注意：FWP_ACTION_PERMIT 和 FWP_ACTION_BLOCK 可能需要手动定义
            FWPM_LAYER_ALE_AUTH_CONNECT_V4,
            FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4,
            FWPM_SESSION0,
            FWPM_SUBLAYER_UNIVERSAL,
            FWP_BYTE_BLOB_TYPE,
            FWP_CONDITION_VALUE0,
            FWP_MATCH_EQUAL,
            FWP_UINT64,
        },
    },
};

// 手动定义缺失的常量（如果导入失败）
const FWP_ACTION_PERMIT: u32 = 1;
const FWP_ACTION_BLOCK: u32 = 2;

/// WFP过滤器管理器
/// 用于管理Windows Filtering Platform的过滤器规则
pub struct WfpManager {
    /// WFP引擎句柄
    engine_handle: HANDLE,
}

/// 网络流量方向枚举
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TrafficDirection {
    /// 入站流量
    Inbound,
    /// 出站流量
    Outbound,
    /// 双向流量
    Both,
}

/// 过滤器动作枚举
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FilterAction {
    /// 允许通过
    Allow,
    /// 阻止通过
    Block,
}

/// 应用程序过滤规则
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppFilterRule {
    /// 规则名称
    pub name: String,
    /// 应用程序路径
    pub app_path: String,
    /// 流量方向
    pub direction: TrafficDirection,
    /// 过滤动作
    pub action: FilterAction,
    /// 是否启用
    pub enabled: bool,
    /// 规则描述
    pub description: Option<String>,
}

/// WFP过滤器信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WfpFilterInfo {
    /// 过滤器ID
    pub filter_id: u64,
    /// 过滤器名称
    pub name: String,
    /// 应用程序路径
    pub app_path: String,
    /// 流量方向
    pub direction: TrafficDirection,
    /// 过滤动作
    pub action: FilterAction,
    /// 权重（优先级）
    pub weight: u64,
}

impl WfpManager {
    /// 创建新的WFP管理器实例
    ///
    /// # 返回值
    /// * `Result<Self>` - 成功返回WfpManager实例，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// let wfp_manager = WfpManager::new()?;
    /// ```
    pub fn new() -> Result<Self> {
        unsafe {
            let mut engine_handle = INVALID_HANDLE_VALUE;

            // 创建WFP引擎会话
            let session = FWPM_SESSION0 {
                sessionKey: std::mem::zeroed(),
                displayData: FWPM_DISPLAY_DATA0 {
                    name: PWSTR::null(),
                    description: PWSTR::null(),
                },
                flags: 0,
                txnWaitTimeoutInMSec: 0,
                processId: GetCurrentProcessId(),
                sid: ptr::null_mut(),
                username: PWSTR::null(),
                kernelMode: BOOL(0),
            };

            // 打开WFP引擎
            let result = FwpmEngineOpen0(
                PCWSTR::null(),
                RPC_C_AUTHN_DEFAULT as u32,
                None,
                Some(&session),
                &mut engine_handle,
            );

            if result != ERROR_SUCCESS.0 {
                return Err(windows::core::Error::from_win32());
            }

            Ok(WfpManager { engine_handle })
        }
    }

    /// 为指定应用程序添加过滤规则
    ///
    /// # 参数
    /// * `rule` - 应用程序过滤规则
    ///
    /// # 返回值
    /// * `Result<u64>` - 成功返回过滤器ID，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// let rule = AppFilterRule {
    ///     name: "Block Chrome Outbound".to_string(),
    ///     app_path: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe".to_string(),
    ///     direction: TrafficDirection::Outbound,
    ///     action: FilterAction::Block,
    ///     enabled: true,
    ///     description: Some("阻止Chrome的出站连接".to_string()),
    /// };
    /// let filter_id = wfp_manager.add_app_filter(&rule)?;
    /// ```
    pub fn add_app_filter(&self, rule: &AppFilterRule) -> Result<u64> {
        if !rule.enabled {
            return Err(windows::core::Error::from_win32());
        }

        unsafe {
            let mut filter_id = 0u64;

            // 转换应用程序路径为宽字符
            let app_path_wide = self.string_to_wide(&rule.app_path)?;

            // 创建过滤条件
            let mut conditions = Vec::new();

            // 添加应用程序路径条件
            let app_condition = FWPM_FILTER_CONDITION0 {
                fieldKey: FWPM_CONDITION_ALE_APP_ID,
                matchType: FWP_MATCH_EQUAL,
                conditionValue: FWP_CONDITION_VALUE0 {
                    r#type: FWP_BYTE_BLOB_TYPE,
                    Anonymous: FWP_CONDITION_VALUE0_0 {
                        byteBlob: &FWP_BYTE_BLOB {
                            size: (app_path_wide.len() * 2) as u32,
                            data: app_path_wide.as_ptr() as *mut u8,
                        } as *const FWP_BYTE_BLOB
                            as *mut FWP_BYTE_BLOB,
                    },
                },
            };
            conditions.push(app_condition);

            // 确定过滤层
            let layer_key = match rule.direction {
                TrafficDirection::Inbound => FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4,
                TrafficDirection::Outbound => FWPM_LAYER_ALE_AUTH_CONNECT_V4,
                TrafficDirection::Both => FWPM_LAYER_ALE_AUTH_CONNECT_V4,
            };

            // 确定过滤动作
            let action_type = match rule.action {
                FilterAction::Allow => FWP_ACTION_PERMIT,
                FilterAction::Block => FWP_ACTION_BLOCK,
            };

            // 转换规则名称和描述
            let name_wide = self.string_to_wide(&rule.name)?;
            let desc_wide = if let Some(ref desc) = rule.description {
                self.string_to_wide(desc)?
            } else {
                self.string_to_wide("")?
            };

            // 创建过滤器
            let filter = FWPM_FILTER0 {
                filterKey: std::mem::zeroed(),
                displayData: FWPM_DISPLAY_DATA0 {
                    name: PWSTR(name_wide.as_ptr() as *mut u16),
                    description: PWSTR(desc_wide.as_ptr() as *mut u16),
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
                        uint64: Box::into_raw(Box::new(0x1000u64)),
                    },
                },
                numFilterConditions: conditions.len() as u32,
                filterCondition: conditions.as_ptr() as *mut _,
                action: FWPM_ACTION0 {
                    r#type: action_type,
                    Anonymous: FWPM_ACTION0_0 {
                        filterType: std::mem::zeroed(),
                    },
                },
                // 移除了不存在的字段 providerContextKey
                reserved: ptr::null_mut(),
                filterId: 0, // Add this field
                effectiveWeight: FWP_VALUE0 {
                    // Add this field
                    r#type: FWP_UINT64,
                    Anonymous: FWP_VALUE0_0 {
                        uint64: Box::into_raw(Box::new(0u64)),
                    },
                },
                Anonymous: std::mem::zeroed(), // Add this field
            };

            // 添加过滤器到WFP引擎
            let result = FwpmFilterAdd0(self.engine_handle, &filter, None, Some(&mut filter_id));

            if result != ERROR_SUCCESS.0 {
                return Err(windows::core::Error::from_win32());
            }

            // 如果是双向规则，还需要添加入站规则
            if matches!(rule.direction, TrafficDirection::Both) {
                let inbound_filter = FWPM_FILTER0 {
                    layerKey: FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4,
                    ..filter
                };

                let mut inbound_filter_id = 0u64;
                let result = FwpmFilterAdd0(
                    self.engine_handle,
                    &inbound_filter,
                    None,
                    Some(&mut inbound_filter_id),
                );

                if result != ERROR_SUCCESS.0 {
                    // 如果入站规则添加失败，删除已添加的出站规则
                    let _ = self.remove_filter(filter_id);
                    return Err(windows::core::Error::from_win32());
                }
            }

            Ok(filter_id)
        }
    }

    /// 移除指定的过滤器
    ///
    /// # 参数
    /// * `filter_id` - 过滤器ID
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回()，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// wfp_manager.remove_filter(filter_id)?;
    /// ```
    pub fn remove_filter(&self, filter_id: u64) -> Result<()> {
        unsafe {
            let result = FwpmFilterDeleteById0(self.engine_handle, filter_id);

            if result != ERROR_SUCCESS.0 {
                return Err(windows::core::Error::from_win32());
            }

            Ok(())
        }
    }

    /// 获取所有应用程序过滤器列表
    ///
    /// # 返回值
    /// * `Result<Vec<WfpFilterInfo>>` - 成功返回过滤器信息列表，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// let filters = wfp_manager.list_app_filters()?;
    /// for filter in filters {
    ///     println!("过滤器: {} - {}", filter.name, filter.app_path);
    /// }
    /// ```
    pub fn list_app_filters(&self) -> Result<Vec<WfpFilterInfo>> {
        unsafe {
            let mut enum_handle = ptr::null_mut();
            let mut filters = Vec::new();

            // 创建枚举句柄
            let result =
                FwpmFilterCreateEnumHandle0(self.engine_handle, None, enum_handle);

            if result != ERROR_SUCCESS.0 {
                return Err(windows::core::Error::from_win32());
            }

            // 枚举过滤器
            let mut entries = ptr::null_mut();
            let mut num_entries = 0u32;

            let result = FwpmFilterEnum0(
                self.engine_handle,
                HANDLE(enum_handle as isize),
                100, // 每次最多获取100个
                &mut entries,
                &mut num_entries,
            );

            if result == ERROR_SUCCESS.0 && num_entries > 0 {
                let filter_array = std::slice::from_raw_parts(entries, num_entries as usize);

                for filter_ptr in filter_array {
                    if let Some(filter_info) = self.parse_filter_info(*filter_ptr) {
                        filters.push(filter_info);
                    }
                }

                // 释放内存
                FwpmFreeMemory0(entries as *mut *mut std::ffi::c_void);
            }

            // 销毁枚举句柄
            FwpmFilterDestroyEnumHandle0(self.engine_handle, unsafe { *enum_handle });

            Ok(filters)
        }
    }

    /// 清除指定应用程序的所有过滤规则
    ///
    /// # 参数
    /// * `app_path` - 应用程序路径
    ///
    /// # 返回值
    /// * `Result<u32>` - 成功返回清除的规则数量，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// let removed_count = wfp_manager.clear_app_filters(
    ///     "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    /// )?;
    /// println!("已清除 {} 条规则", removed_count);
    /// ```
    pub fn clear_app_filters(&self, app_path: &str) -> Result<u32> {
        let filters = self.list_app_filters()?;
        let mut removed_count = 0u32;

        for filter in filters {
            if filter.app_path.eq_ignore_ascii_case(app_path) {
                if self.remove_filter(filter.filter_id).is_ok() {
                    removed_count += 1;
                }
            }
        }

        Ok(removed_count)
    }

    /// 检查指定应用程序是否被阻止
    ///
    /// # 参数
    /// * `app_path` - 应用程序路径
    /// * `direction` - 流量方向
    ///
    /// # 返回值
    /// * `Result<bool>` - 成功返回是否被阻止，失败返回错误
    ///
    /// # 示例
    /// ```rust
    /// let is_blocked = wfp_manager.is_app_blocked(
    ///     "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    ///     &TrafficDirection::Outbound
    /// )?;
    /// ```
    pub fn is_app_blocked(&self, app_path: &str, direction: &TrafficDirection) -> Result<bool> {
        let filters = self.list_app_filters()?;

        for filter in filters {
            if filter.app_path.eq_ignore_ascii_case(app_path) {
                let direction_match = match (&filter.direction, direction) {
                    (TrafficDirection::Both, _) => true,
                    (d1, d2) => std::mem::discriminant(d1) == std::mem::discriminant(d2),
                };

                if direction_match && matches!(filter.action, FilterAction::Block) {
                    return Ok(true);
                }
            }
        }

        Ok(false)
    }

    /// 将字符串转换为宽字符（UTF-16）
    fn string_to_wide(&self, s: &str) -> Result<Vec<u16>> {
        use std::ffi::OsStr;
        use std::os::windows::ffi::OsStrExt;

        let wide: Vec<u16> = OsStr::new(s)
            .encode_wide()
            .chain(std::iter::once(0))
            .collect();
        Ok(wide)
    }

    /// 解析过滤器信息
    fn parse_filter_info(&self, filter: *const FWPM_FILTER0) -> Option<WfpFilterInfo> {
        unsafe {
            if filter.is_null() {
                return None;
            }

            let filter_ref = &*filter;

            // 解析过滤器名称
            let name = if !filter_ref.displayData.name.is_null() {
                self.wide_to_string(filter_ref.displayData.name.0)
            } else {
                "Unknown".to_string()
            };

            // 解析应用程序路径（从过滤条件中提取）
            let app_path = self
                .extract_app_path_from_conditions(
                    filter_ref.filterCondition,
                    filter_ref.numFilterConditions,
                )
                .unwrap_or_else(|| "Unknown".to_string());

            // 解析流量方向
            let direction = if filter_ref.layerKey == FWPM_LAYER_ALE_AUTH_CONNECT_V4 {
                TrafficDirection::Outbound
            } else if filter_ref.layerKey == FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4 {
                TrafficDirection::Inbound
            } else {
                TrafficDirection::Both
            };

            // 解析过滤动作
            let action = if filter_ref.action.r#type == FWP_ACTION_BLOCK {
                FilterAction::Block
            } else {
                FilterAction::Allow
            };

            // 解析权重
            let weight = if filter_ref.weight.r#type == FWP_UINT64 {
                unsafe { *filter_ref.weight.Anonymous.uint64 }
            } else {
                0
            };

            Some(WfpFilterInfo {
                filter_id: 0, // 需要从其他地方获取
                name,
                app_path,
                direction,
                action,
                weight,
            })
        }
    }

    /// 将宽字符转换为字符串
    fn wide_to_string(&self, wide_ptr: *const u16) -> String {
        if wide_ptr.is_null() {
            return String::new();
        }

        unsafe {
            let mut len = 0;
            while *wide_ptr.add(len) != 0 {
                len += 1;
            }

            let slice = std::slice::from_raw_parts(wide_ptr, len);
            String::from_utf16_lossy(slice)
        }
    }

    /// 从过滤条件中提取应用程序路径
    fn extract_app_path_from_conditions(
        &self,
        conditions: *const FWPM_FILTER_CONDITION0,
        count: u32,
    ) -> Option<String> {
        if conditions.is_null() || count == 0 {
            return None;
        }

        unsafe {
            let conditions_slice = std::slice::from_raw_parts(conditions, count as usize);

            for condition in conditions_slice {
                if condition.fieldKey == FWPM_CONDITION_ALE_APP_ID {
                    if condition.conditionValue.r#type == FWP_BYTE_BLOB_TYPE {
                        let blob_ptr = condition.conditionValue.Anonymous.byteBlob;
                        if !blob_ptr.is_null() {
                            let blob = unsafe { &*blob_ptr };
                            if !blob.data.is_null() && blob.size > 0 {
                                let wide_slice = std::slice::from_raw_parts(
                                    blob.data as *const u16,
                                    (blob.size / 2) as usize,
                                );
                                return Some(String::from_utf16_lossy(wide_slice));
                            }
                        }
                    }
                }
            }
        }

        None
    }
}

impl Drop for WfpManager {
    /// 析构函数，自动关闭WFP引擎句柄
    fn drop(&mut self) {
        if self.engine_handle != INVALID_HANDLE_VALUE {
            unsafe {
                FwpmEngineClose0(self.engine_handle);
            }
        }
    }
}

/// 创建WFP管理器实例
///
/// # 返回值
/// * `Result<WfpManager>` - 成功返回WfpManager实例，失败返回错误
///
/// # 示例
/// ```rust
/// let wfp_manager = create_wfp_manager()?;
/// ```
pub fn create_wfp_manager() -> Result<WfpManager> {
    WfpManager::new()
}

/// 为应用程序添加阻止规则的便捷函数
///
/// # 参数
/// * `app_path` - 应用程序路径
/// * `direction` - 流量方向
/// * `rule_name` - 规则名称
///
/// # 返回值
/// * `Result<u64>` - 成功返回过滤器ID，失败返回错误
///
/// # 示例
/// ```rust
/// let filter_id = block_app_traffic(
///     "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
///     TrafficDirection::Outbound,
///     "阻止Chrome出站连接"
/// )?;
/// ```
pub fn block_app_traffic(
    app_path: &str,
    direction: TrafficDirection,
    rule_name: &str,
) -> Result<u64> {
    let wfp_manager = WfpManager::new()?;
    let rule = AppFilterRule {
        name: rule_name.to_string(),
        app_path: app_path.to_string(),
        direction,
        action: FilterAction::Block,
        enabled: true,
        description: Some(format!("阻止应用程序 {} 的网络访问", app_path)),
    };

    wfp_manager.add_app_filter(&rule)
}

/// 为应用程序添加允许规则的便捷函数
///
/// # 参数
/// * `app_path` - 应用程序路径
/// * `direction` - 流量方向
/// * `rule_name` - 规则名称
///
/// # 返回值
/// * `Result<u64>` - 成功返回过滤器ID，失败返回错误
///
/// # 示例
/// ```rust
/// let filter_id = allow_app_traffic(
///     "C:\\Program Files\\MyApp\\myapp.exe",
///     TrafficDirection::Both,
///     "允许MyApp网络访问"
/// )?;
/// ```
pub fn allow_app_traffic(
    app_path: &str,
    direction: TrafficDirection,
    rule_name: &str,
) -> Result<u64> {
    let wfp_manager = WfpManager::new()?;
    let rule = AppFilterRule {
        name: rule_name.to_string(),
        app_path: app_path.to_string(),
        direction,
        action: FilterAction::Allow,
        enabled: true,
        description: Some(format!("允许应用程序 {} 的网络访问", app_path)),
    };

    wfp_manager.add_app_filter(&rule)
}
