# 上游同步

## 远程仓库

- `origin`：`beacon-observability/beacon-php-instrumentation`，Beacon 下游。
- `upstream`：`open-telemetry/opentelemetry-php-instrumentation`，官方只读来源。

## 同步步骤

1. 从 `main` 创建独立同步分支，抓取 `upstream` 的标签和提交。
2. 核对目标官方 Release、完整提交、PHP 支持范围、扩展 ABI 变化和安全修复。
3. 合并目标官方提交，不使用目录覆盖或改写历史。
4. 保留并重新验证 Beacon 发行标识、项目校验、制品构建和组件联调。
5. 更新 `beacon/upstream.lock.json` 中的官方标签、提交和扩展版本。
6. 运行项目校验、PHPT、跨平台构建以及 `beacon-php` 自动插桩联调。
7. 通过 PR 合并；不直接向 `upstream` 推送。
