use std::io;
use std::process::Command;

/// 获取所有网卡及其跃点数
pub fn get_all_interfaces_metrics() -> io::Result<Vec<(String, u32)>> {
    let output = Command::new("netsh")
        .args(&["interface", "ipv4", "show", "interfaces"])
        .output()?;

    if !output.status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            String::from_utf8_lossy(&output.stderr).to_string(),
        ));
    }

    let output_str = String::from_utf8_lossy(&output.stdout);
    let mut interfaces = Vec::new();

    for line in output_str.lines().skip(3) { // 跳过前两行表头
        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 5 {
            let name = parts[4..].join(" ");
            let metric = parts[1].parse::<u32>().unwrap_or(0);
            interfaces.push((name, metric));
        }
    }

    Ok(interfaces)
}

/// 设置指定网卡的跃点数
pub fn set_interface_metric(interface_name: &str, metric: u32) -> io::Result<()> {
    let output = Command::new("netsh")
        .args(&["interface", "ipv4", "set", "interface", interface_name, "metric=", &metric.to_string()])
        .output()?;

    if output.status.success() {
        Ok(())
    } else {
        Err(io::Error::new(
            io::ErrorKind::Other,
            String::from_utf8_lossy(&output.stderr).to_string(),
        ))
    }
}