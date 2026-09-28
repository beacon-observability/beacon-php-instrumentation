<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Http\Adapter\Guzzle7\Client as GuzzleAdapter;
use Nyholm\Psr7\Request;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as ServerRequest;
use Slim\Factory\AppFactory;

$app = AppFactory::create();

$app->get('/', function (ServerRequest $request, Response $response): Response {
    $response->getBody()->write('ok');

    return $response;
});

$app->get('/upstream', function (ServerRequest $request, Response $response): Response {
    $client = new GuzzleAdapter();
    $upstream = $client->sendRequest(new Request('GET', 'http://example.com/'));

    $payload = [
        'status' => 'ok',
        'upstream_status' => $upstream->getStatusCode(),
        'service' => getenv('OTEL_SERVICE_NAME') ?: '',
    ];

    $response->getBody()->write((string) json_encode($payload, JSON_UNESCAPED_SLASHES));

    return $response->withHeader('Content-Type', 'application/json');
});

$app->run();

