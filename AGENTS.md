# 仓库协作约定

- 始终使用简体中文沟通。
- 本仓库维护 Beacon PHP 的原生 `opentelemetry` 扩展；组件级自动插桩放在 `beacon-php` 仓库。
- `origin` 是 Beacon 下游仓库，`upstream` 只用于读取 OpenTelemetry 官方历史；禁止向 `upstream` 推送。
- 上游同步必须使用固定标签和完整提交，先在独立分支合并，再更新 `beacon/upstream.lock.json` 并完成扩展测试。
- 保持 `OpenTelemetry\\Instrumentation\\hook()` 的上游兼容性；Beacon 差异必须有测试，不得破坏手动插桩。
- 发行前同时核对 Beacon 产品版本、官方扩展基线、扩展内置版本、跨平台制品和摘要。
- 当前未正式发行，不得把候选制品写成生产安装入口。
