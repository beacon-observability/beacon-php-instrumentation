# Beacon PHP Instrumentation

Beacon PHP Instrumentation 是 Beacon PHP 使用的原生自动插桩扩展，基于 [OpenTelemetry PHP Instrumentation](https://github.com/open-telemetry/opentelemetry-php-instrumentation) 维护。

本仓库采用非 Fork 的完整源码下游方式，保留官方 Git 历史，并吸收既有的跨平台构建与制品经验。

## 仓库职责

- 提供 PHP 运行时函数与方法 Hook 所需的 `opentelemetry` 原生扩展。
- 构建 Linux、Windows 和 PECL 兼容源码制品。
- 跟踪固定的官方扩展基线，并维护必要的 Beacon 下游差异。
- 不承载框架、数据库或客户端的具体 Span 创建逻辑；[`beacon-php`](https://github.com/beacon-observability/beacon-php) 负责 Agent 编排，并直接安装官方 OpenTelemetry Composer 插桩包。

手动插桩只依赖 OpenTelemetry PHP API/SDK，不需要加载本扩展。自动插桩需要同时安装本扩展、`beacon-php` Agent 包和应用实际使用的官方 Composer 插桩包。Beacon 不维护完整的 PHP Contrib 下游镜像。

## 当前基线

- 官方扩展版本：`1.4.2`
- Beacon 版本：`1.0.1`
- PHP 验证与二进制制品范围：`8.2`、`8.3` 和 `8.4`

| 平台 | 架构 | PHP 模式 | 发布制品 |
| --- | --- | --- | --- |
| Linux | x86_64、arm64 | NTS | PHP 8.2、8.3、8.4 |
| macOS | arm64 | NTS | PHP 8.2、8.3、8.4 |
| Windows | x86_64 | NTS、TS | PHP 8.2、8.3、8.4 |

其他平台或组合可使用 PECL 兼容源码包自行构建。二进制扩展必须与 PHP 的主次版本、线程安全模式、操作系统和 CPU 架构全部匹配。

精确的官方基线提交见 [`beacon/upstream.lock.json`](beacon/upstream.lock.json)。

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

正式制品由 [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases) 提供。安装二进制前须匹配 PHP 版本、线程安全模式、操作系统与架构，并使用随 Release 提供的 `SHA256SUMS` 校验文件。

## 开发文档

- [工程边界](beacon/README.md)
- [上游同步](beacon/UPSTREAM.md)
- [发行准备](beacon/RELEASING.md)

## Beacon Contributors

<a href="https://github.com/lrwh"><img src="https://github.com/lrwh.png" width="64" height="64" alt="lrwh"><br>lrwh</a>

## License

Apache License 2.0，详见 [LICENSE](LICENSE)。
