# Beacon PHP Instrumentation 工程说明

本仓库负责 PHP 自动插桩所需的原生 Hook 扩展。组件级 Span 创建逻辑和 Beacon Composer 聚合包由 [`beacon-php`](https://github.com/beacon-observability/beacon-php) 负责。

## 维护模型

- 官方主来源：`open-telemetry/opentelemetry-php-instrumentation`。
- Beacon 主线：官方完整历史之上的非 Fork 下游仓库。

初始化开发分支以官方 `1.4.2` 为代码基线。跨平台构建、校验和示例均按当前官方代码重新适配。

## 使用边界

- 手动插桩：应用直接使用 OpenTelemetry PHP API/SDK，不要求本扩展。
- 自动插桩：本扩展提供 Hook 能力，Composer 插桩包负责创建 Span。
- Beacon 发行标识：扩展保持上游模块名 `opentelemetry` 与兼容版本，同时公开 `OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION` 常量和 phpinfo 发行来源。

正式制品通过 [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases) 发布；二进制扩展必须与 PHP 版本、线程安全模式、操作系统和架构完全匹配。
