# Beacon PHP Instrumentation

Beacon PHP Instrumentation 是 Beacon PHP 使用的原生自动插桩扩展，基于 [OpenTelemetry PHP Instrumentation](https://github.com/open-telemetry/opentelemetry-php-instrumentation) 维护。

本仓库采用非 Fork 的完整源码下游方式，保留官方 Git 历史，并迁移 [GuanceCloud 旧 `gtrace` 分支](https://github.com/GuanceCloud/opentelemetry-php-instrumentation/tree/gtrace) 的跨平台构建与制品经验。当前处于开发和发行准备阶段，尚无 Beacon PHP Instrumentation 正式版本。

## 仓库职责

- 提供 PHP 运行时函数与方法 Hook 所需的 `opentelemetry` 原生扩展。
- 构建 Linux、Windows 和 PECL 兼容源码候选制品。
- 跟踪固定的官方扩展基线，并维护必要的 Beacon 下游差异。
- 不承载框架、数据库或客户端的具体 Span 创建逻辑；这些组件插桩由 [`beacon-php`](https://github.com/beacon-observability/beacon-php) 维护。

手动插桩只依赖 OpenTelemetry PHP API/SDK，不需要加载本扩展。自动插桩需要同时安装本扩展和相应的 Composer 插桩包，因此两种使用方式不会被强制混合。

## 当前基线

- 官方扩展版本：`1.4.2`
- Beacon 开发版本：`0.1.0-dev`
- PHP 验证范围：`8.2` 和 `8.4`，另在 macOS 与 Windows 上进行代表性构建

精确提交及旧代码来源见 [`beacon/upstream.lock.json`](beacon/upstream.lock.json)。

## 开发验证

```shell
python3 beacon/scripts/check-project.py
cd ext
phpize
./configure
make
make test TESTS=--show-diff
```

扩展加载后可确认发行来源：

```shell
php --ri opentelemetry
php -r 'echo constant("OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION"), PHP_EOL;'
```

候选二进制和源码包只用于开发验收。正式发行前必须完成 [`beacon/RELEASING.md`](beacon/RELEASING.md) 中的检查。

## 开发文档

- [工程边界](beacon/README.md)
- [上游同步](beacon/UPSTREAM.md)
- [发行准备](beacon/RELEASING.md)

## Beacon Contributors

<a href="https://github.com/lrwh"><img src="https://github.com/lrwh.png" width="64" height="64" alt="lrwh"><br>lrwh</a>

## License

Apache License 2.0，详见 [LICENSE](LICENSE)。
