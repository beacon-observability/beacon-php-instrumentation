# Beacon PHP Instrumentation

Beacon PHP Instrumentation is the native auto-instrumentation extension used by Beacon PHP, maintained as a downstream of [OpenTelemetry PHP Instrumentation](https://github.com/open-telemetry/opentelemetry-php-instrumentation).

This repository is a downstream repository containing the complete source tree, rather than a GitHub fork. It preserves the official Git history and incorporates existing experience with cross-platform builds and artifacts.

## Repository Scope

- Provide the native `opentelemetry` extension for hooking PHP runtime functions and methods.
- Build Linux and Windows binaries and PECL-compatible source artifacts.
- Track a pinned official extension baseline and maintain the necessary Beacon-specific downstream changes.
- Keep framework, database, and client span creation logic in official OpenTelemetry Composer instrumentation packages. [`beacon-php`](https://github.com/beacon-observability/beacon-php) handles Agent orchestration and installs those packages directly.

Manual instrumentation requires only the OpenTelemetry PHP API/SDK and does not require loading this extension. Auto-instrumentation requires this extension, the `beacon-php` Agent package, and the official Composer instrumentation packages for the components used by the application. Beacon does not maintain a complete downstream mirror of PHP Contrib.

## Current Baseline

- Official extension version: `1.4.2`
- Beacon version: `1.0.1`
- PHP versions covered by validation and binary artifacts: `8.2`, `8.3`, and `8.4`

| Platform | Architecture | PHP Mode | Release Artifacts |
| --- | --- | --- | --- |
| Linux | x86_64, arm64 | NTS | PHP 8.2, 8.3, 8.4 |
| macOS | arm64 | NTS | PHP 8.2, 8.3, 8.4 |
| Windows | x86_64 | NTS, TS | PHP 8.2, 8.3, 8.4 |

For other platforms or combinations, build from the PECL-compatible source package. Binary extensions must match the PHP major and minor version, thread-safety mode, operating system, and CPU architecture.

See [`beacon/upstream.lock.json`](beacon/upstream.lock.json) for the exact official baseline commit.

## Development Validation

```shell
python3 beacon/scripts/check-project.py
cd ext
phpize
./configure
make
make test TESTS=--show-diff
```

After loading the extension, verify its distribution:

```shell
php --ri opentelemetry
php -r 'echo constant("OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION"), PHP_EOL;'
```

Official artifacts are available from [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases). Before installing a binary, match the PHP version, thread-safety mode, operating system, and architecture, and verify it against the `SHA256SUMS` file provided with the release.

## Development Documentation

- [Project Scope](beacon/README.md)
- [Upstream Synchronization](beacon/UPSTREAM.md)
- [Release Preparation](beacon/RELEASING.md)

## Beacon Contributors

<a href="https://github.com/lrwh"><img src="https://github.com/lrwh.png" width="64" height="64" alt="lrwh"><br>lrwh</a>

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.

## Usage

The `pre` method starts and activates a span. The `post` method ends the span after the observed method has finished.

```php
<?php

$tracer = new Tracer(...);

OpenTelemetry\Instrumentation\hook(
    DemoClass::class,
    'run',
    pre: static function (DemoClass $demo, array $params, string $class, string $function, ?string $filename, ?int $lineno) use ($tracer) {
        $span = $tracer->spanBuilder($class)
            ->startSpan();
        Context::storage()->attach($span->storeInContext(Context::getCurrent()));
    },
    post: static function (DemoClass $demo, array $params, $returnValue, ?Throwable $exception) use ($tracer) {
        $scope = Context::storage()->scope();
        $scope?->detach();
        $span = Span::fromContext($scope->context());
        $exception && $span->recordException($exception);
        $span->setStatus($exception ? StatusCode::STATUS_ERROR : StatusCode::STATUS_OK);
        $span->end();
    }
);
```

There are more examples in the [tests directory](ext/tests/)

### Static methods

Note that if hooking a static class method, the first parameter to `pre` and `post` callbacks is a `string` containing the method's class name.

### Caveats

- Be aware that trivial functions are candidates for optimizations.
Optimizer can optimize them out and replace user function call with more optimal set of instructions (inlining).
In this case hooks will not be invoked as there will be no function.
- Hooks must be registered _before_ a function is first executed. You may encounter race conditions where
the composer autoloader runs code that uses functions you wish to hook prior to the hooks being registered.

# Modifying parameters, exceptions and return values of the observed function

## Parameters

From a `pre` hook function, you may modify the parameters before they are received by the observed function.
The arguments are passed in as a numerically-indexed array. The returned array from the `pre` hook is used
to modify (_not_ replace) the existing parameters:

```php
<?php
OpenTelemetry\Instrumentation\hook(
    null,
    'hello',
     function($obj, array $params) {
        return [
          0 => null,  //make first param null
          2 => 'baz', //replace 3rd param
          3 => 'bat', //add 4th param
        ];
    }
);
function hello($one = null, $two = null, $three = null, $four = null) {
  var_dump(func_get_args());
}

hello('a', 'b', 'c');
```

gives output:
```
array(4) {
  [0]=>
  NULL
  [1]=>
  string(1) "b"
  [2]=>
  string(3) "baz"
  [3]=>
  string(3) "bat"
}
```

## Return values

`post` hook methods can modify the observed function's return value:

```php
<?php
\OpenTelemetry\Instrumentation\hook(null, 'hello', post: fn(mixed $object, array $params, string $return): int => ++$return);

function hello(int $val) {
    return $val;
}

var_dump(hello(1));
```

gives output:
```
int(2)
```

*Important*: the post method _must_ provide a return type-hint, otherwise the return value will be ignored. The return type
hint in the example above is `: int`.

## Exceptions

`post` hook methods can modify an exception thrown from the observed function:

```php
<?php
\OpenTelemetry\Instrumentation\hook(null, 'hello', post: function(mixed $object, array $params, mixed $return, ?Throwable $throwable) {
    throw new Exception('new', previous: $throwable);
});

function hello() {
    throw new Exception('original');
}

try {
    hello();
} catch (\Throwable $t) {
    var_dump($t->getMessage());
    var_dump($t->getPrevious()?->getMessage());
}
```

gives output:
```php
string(3) "new"
string(8) "original"
```

## Attribute-based hooking

By applying attributes to source code, the OpenTelemetry extension can add hooks at runtime.

Default pre and post hook methods are provided by the OpenTelemetry API: `OpenTelemetry\API\Instrumentation\Handler::pre`
and `::post`.

This feature is disabled by default, but can be enabled by setting `opentelemetry.attr_hooks_enabled = On` in php.ini

## Restrictions

Attribute-based hooks can only be applied to a function/method that does not already have
hooks applied.
Only one hook can be applied to a function/method, including via interfaces.

Since the attributes are evaluated at runtime, the extension checks whether a hook already
exists to decide whether it should apply a new runtime hook.

## Configuration

This feature can be configured via `.ini` by modifying the following entries:

- `opentelemetry.attr_hooks_enabled` - boolean, default Off
- `opentelemetry.attr_pre_handler_function` - FQN of pre method/function
- `opentelemetry.attr_post_handler_function` - FQN of post method/function

## `OpenTelemetry\API\Instrumentation\WithSpan` attribute

This attribute is provided by the OpenTelemetry API can be applied to a function or class method.

You can also provide optional parameters to the attribute, which control:
- span name
- span kind
- attributes

```php
use OpenTelemetry\API\Instrumentation\WithSpan

class MyClass
{
    #[WithSpan]
    public function trace_me(): void
    {
        /* ... */
    }

    #[WithSpan('custom_span_name', SpanKind::KIND_INTERNAL, ['my-attr' => 'value'])]
    public function trace_me_with_customization(): void
    {
        /* ... */
    }
}

#[WithSpan]
function my_function(): void
{
    /* ... */
}
```

## `OpenTelemetry\API\Instrumentation\SpanAttribute` attribute

This attribute should be used in conjunction with `WithSpan`. It is applied to function/method
parameters, and causes those parameters and values to be passed through to the `pre` hook function
where they can be added as trace attributes.
There is one optional parameter, which controls the attribute key. If not set, the parameter name
is used.

```php
use OpenTelemetry\API\Instrumentation\WithSpan
use OpenTelemetry\API\Instrumentation\SpanAttribute

class MyClass
{
    #[WithSpan]
    public function add_user(
        #[SpanAttribute] string $username,
        string $password,
        #[SpanAttribute('a_better_attribute_name')] string $foo_bar_baz,
    ): void
    {
        /* ... */
    }
```

### Attribute key evaluation

The key does not have to be a literal. `#[SpanAttribute(SomeClass::KEY)]` is valid, and the
constant is resolved at runtime, on every call to the annotated function.

If that key cannot be resolved — an unresolvable constant from an optional dependency that is
not installed, or an autoloader that throws — **the attribute is dropped** rather than recorded
under the parameter name, and a warning naming the class, function and underlying error is
emitted. The warning is emitted once per function per request, and re-armed by a call that
evaluates cleanly, so a repeatedly-failing declaration does not flood the log while a later,
genuinely different failure is still reported.

Dropping is deliberate. Falling back to the parameter name would record the correct value under
a key nobody queries: `#[SpanAttribute('db.user.id')] int $id` would silently export `id`, which
looks like deliberate configuration. A missing attribute is diagnosable; a renamed one is not.

A *bare* `#[SpanAttribute]` is unaffected — it has no key argument and is defined to use the
parameter name, which is not a fallback. Only parameters whose declared key fails to resolve are
dropped; others on the same function are unaffected.

Note that resolution happens per call because a constant expression is not necessarily constant:
`new` in an attribute argument runs its constructor on every evaluation, so results are not
cached.

### Known limitation: throwing exception destructors

Only the first exception from attribute evaluation is kept, to be reported; any further ones are
released as they arrive. Releasing an exception runs its userland `__destruct`, and if that
destructor throws, the new exception is absorbed and discarded — it ran only because the
extension was cleaning up, so there is no frame it can fairly be attributed to.

Absorption is bounded at 32 consecutive throwing destructors. Beyond that the last exception
object is deliberately leaked rather than released outside its isolation window, which would
surface a fatal error against a function that never threw. The leak is **152 bytes per affected
call**, measured on a PHP 8.3.10 debug build, and is not reclaimed at request shutdown.

Reaching it requires a chain of more than 32 exceptions whose destructors each throw, per call,
which does not arise accidentally. It is documented as a known trade-off, not a recommended
configuration.

## Contributing
See [DEVELOPMENT.md](DEVELOPMENT.md) and https://github.com/open-telemetry/opentelemetry-php/blob/main/CONTRIBUTING.md

### Maintainers

- [OpenTelemetry PHP Maintainers](https://github.com/open-telemetry/opentelemetry-php/blob/main/CONTRIBUTING.md#maintainers)

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

- [OpenTelemetry PHP Approvers](https://github.com/open-telemetry/opentelemetry-php/blob/main/CONTRIBUTING.md#approvers)

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).

### Emeritus

- [Ago Allikmaa](https://github.com/agoallikmaa), Approver
- [Amber Sistla](https://github.com/zsistla), Triager
- [Beniamin](https://github.com/beniamin), Triager
- [Cedric Ziel](https://github.com/cedricziel), Approver
- [Fahmy Mohammed](https://github.com/Fahmy-Mohammed), Triager
- [Jodee Varney](https://github.com/jodeev), Triager
- [Kishan Sangani](https://github.com/kishannsangani), Triager
- [Levi Morrison](https://github.com/morrisonlevi), Triager
- [Przemyslaw Delewski](https://github.com/pdelewski), Triager
- [Timo Michna](https://github.com/tidal), Triager

For more information about the emeritus role, see the
[community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#emeritus-maintainerapprovertriager).
