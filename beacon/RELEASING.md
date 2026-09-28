# 发行准备

Beacon 产品版本与官方扩展版本独立：产品版本标识 Beacon 制品，官方扩展版本表示所采用的兼容代码基线。

## 首次发行前

1. 将 `beacon/version.properties` 的 `BEACON_VERSION` 从开发版本改为正式版本，并同步 `beacon/upstream.lock.json`。
2. 确认 `ext/php_opentelemetry.h` 和 `ext/package.xml` 的扩展版本与锁定的官方基线一致，发行来源为 `Beacon`。
3. 运行 `python3 beacon/scripts/check-project.py` 和完整 PHPT。
4. 验证 Linux、Windows、macOS 代表性环境；记录 PHP 版本、线程安全模式、架构和已知限制。
5. 使用同一提交生成 Linux、Windows 和 PECL 兼容源码候选制品，核对文件名、模块信息和 SHA-256。
6. 与 `beacon-php` 固定候选包联调，验证自动插桩和实际接收端数据链路；同时确认不加载扩展时手动插桩仍可使用。
7. 创建与产品版本一致的签名标签 `v<BEACON_VERSION>`。工作流只创建草稿 Release，人工复核后再发布。
8. 从公开 Release 重新下载并安装复验，然后更新产品仓库的固定版本入口。

已发布的标签和制品不可覆盖；修复后发布新版本。带 `-dev` 后缀的版本不能触发正式发行。
