# 快速参考：Android构建故障排除

## 常见错误与解决方案

### 1. ❌ "No space left on device"

**原因**：磁盘空间不足

**解决**：
```yaml
# 构建前清理
- run: |
    flutter clean
    cargo clean
    rm -rf android/.gradle

# 构建后清理
- run: |
    rm -rf rust/target
    rm -rf ~/.gradle
```

**推荐**：使用分架构构建而不是全架构构建

---

### 2. ❌ "Execution failed for task ':app:packageRelease'"

**原因**：通常是磁盘空间、内存或Gradle问题

**解决**：
```yaml
- run: flutter build apk --release --verbose
```

---

### 3. ❌ "Could not add entry to cache executionHistory.bin"

**原因**：Gradle缓存损坏或磁盘空间不足

**解决**：
```yaml
- run: |
    rm -rf android/.gradle
    rm -rf ~/.gradle
    flutter build apk --release
```

---

### 4. ❌ "Rust target installation failed"

**原因**：网络问题或Rust工具链配置

**解决**：
```yaml
- run: |
    rustup update stable
    rustup target add armv7-linux-androideabi
    rustup target add aarch64-linux-android
```

---

## 构建选项

### 单架构构建（推荐）
```bash
# ARM64
flutter build apk --release --target-platform android-arm64

# ARMv7
flutter build apk --release --target-platform android-arm

# x86_64
flutter build apk --release --target-platform android-x64
```

### 全架构构建（需要更多资源）
```bash
flutter build apk --release
# 或
flutter build aab --release  # 生成AAB而不是APK，更小
```

---

## 工作流选择指南

| 需求 | 推荐工作流 | 原因 |
|------|----------|------|
| 快速测试 | `android-build-arm64.yaml` | 最快，磁盘占用少 |
| 生产发布 | 所有架构分别构建 | 确保兼容性 |
| 单个APK | `android-build-all.yaml` | 包含所有架构 |
| Google Play | 无需使用，用`flutter build aab` | AAB格式更好 |

---

## 磁盘空间检查

### 在工作流中检查
```yaml
- name: 检查磁盘空间
  run: |
    df -h
    du -sh ~/.gradle ~/.cargo rust/target 2>/dev/null
```

### 本地检查
```powershell
# Windows PowerShell
Get-Volume | Select-Object DriveLetter, Size, SizeRemaining

# Linux/Mac
df -h
du -sh ~/{.gradle,.cargo,rust}
```

---

## 环境变量配置

在工作流中添加：
```yaml
env:
  FLUTTER_VERSION: main
  RUST_VERSION: 1.89.0
  JDK_VERSION: 17
  NDK_VERSION: 28.2.13676358
```

修改版本时只需改这一处！

---

## 有用的命令

```bash
# 检查Flutter配置
flutter doctor -v

# 检查Rust工具链
rustc --version
cargo --version

# 检查Android SDK
flutter pub global run android_sdk_installer install

# 清理所有缓存
flutter clean
cargo clean
```

---

## 链接

- [构建优化详细指南](BUILD_OPTIMIZATION_GUIDE.md)
- [工作流版本管理](WORKFLOWS_VERSION_MANAGEMENT.md)
- [Flutter官方文档](https://docs.flutter.dev)
- [Android Build文档](https://gradle.org)

