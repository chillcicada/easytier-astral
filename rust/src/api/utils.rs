/// 定义自动启动参数常量
pub const AUTOSTART_ARG: &str = "--autostart";

/// 检查是否具有管理员/sudo权限的函数
/// 在非Android系统上可用
#[cfg(not(target_os = "android"))]
pub fn check_sudo() -> bool {
    let is_elevated = elevated_command::Command::is_elevated();
    if !is_elevated {
        let exe_path = std::env::current_exe()
            .unwrap_or_default()
            .display()
            .to_string();

        let args: Vec<String> = std::env::args().collect();
        let mut stdcmd = std::process::Command::new(&exe_path);
        if args.contains(&AUTOSTART_ARG.to_owned()) {
            stdcmd.arg(AUTOSTART_ARG);
        }
        elevated_command::Command::new(stdcmd)
            .output()
            .expect("Failed to run elevated command");
    }
    is_elevated
}
