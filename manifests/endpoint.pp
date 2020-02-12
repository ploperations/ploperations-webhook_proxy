# An external webhook endpoint
#
# If name is set to the internal webhook endpoint, this will automatically
# generate a path in the form `/$hostname/$url`. For example, the name
# `'https://jenkins.ops.puppetlabs.net/github-webhook/'` will result in
# an external endpoint path of `/jenkins.ops.puppetlabs.net/github-webhook/`.
define webhook_proxy::endpoint (
  Pattern[/^\//] $path = $name.regsubst('^https?://', '/').regsubst('/*$', '/'),
  Pattern[/^https?:\/\/\w.+\//] $target = $name,
) {
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
