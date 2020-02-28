# @summary An external webhook endpoint
#
# If name is set to the internal webhook endpoint, this will automatically
# generate a path in the form `/$hostname/$url`. For example, the name
# `'https://foo.internal.example.com/github-webhook/'` will result in
# an external endpoint path of `/foo.internal.example.com/github-webhook/`.
#
# @param [Pattern[/^\//]] path
#   The location, or path under this proxy's fqdn, that will have data sent to it
#   for the given target
#
# @param [Pattern[/^https?:\/\/\w.+\//]] target
#   The internal destination for the traffic
#
# @example Send webhooks to Code Manager
#   webhook_proxy::endpoint { 'https://pe-prod.internal.example.com:8170/code-manager/v1/webhook': }
#
define webhook_proxy::endpoint (
  Pattern[/^\//] $path = $name.regsubst('^https?://', '/').regsubst('/*$', '/'),
  Pattern[/^https?:\/\/\w.+\//] $target = $name,
) {
  include nginx

  nginx::resource::location { "webhook = ${path}":
    server           => 'webhook',
    ssl              => true,
    ssl_only         => true,
    location         => "= ${path}",
    proxy            => $target,
    proxy_redirect   => 'default',
    proxy_set_header => [
      'Host               $proxy_host',
      'X-Real-IP          $remote_addr',
      'X-Forwarded-For    $proxy_add_x_forwarded_for',
      'X-Forwarded-Server $host',
      'X-Forwarded-Host   $host',
      'X-Forwarded-Proto  $scheme',
      'X-Forwarded-Ssl    $https',
    ],
  }
}
