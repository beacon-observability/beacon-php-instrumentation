# Beacon PHP Instrumentation 工程说明

本仓库负责 PHP 自动插桩所需的原生 Hook 扩展。组件级 Span 创建逻辑和 Beacon Composer 聚合包由 [`beacon-php`](https://github.com/beacon-observability/beacon-php) 负责。

## 维护模型

- 官方主来源：`open-telemetry/opentelemetry-php-instrumentation`。
- 历史自有来源：`GuanceCloud/opentelemetry-php-instrumentation` 的 `gtrace` 分支。
- Beacon 主线：官方完整历史之上的非 Fork 下游仓库。

初始化开发分支以官方 `1.4.2` 为代码基线，并将旧 `gtrace` 分支合入 Git 祖先关系。旧分支中的构建、校验和示例按当前官方代码重新适配，不沿用旧 `gtrace` 品牌或旧扩展版本。

## 使用边界

- 手动插桩：应用直接使用 OpenTelemetry PHP API/SDK，不要求本扩展。
- 自动插桩：本扩展提供 Hook 能力，Composer 插桩包负责创建 Span。
- Beacon 发行标识：扩展保持上游模块名 `opentelemetry` 与兼容版本，同时公开 `OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION` 常量和 phpinfo 发行来源。

当前仅提供开发候选制品，不存在正式安装入口或支持承诺。
