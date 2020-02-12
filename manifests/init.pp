# Proxy external webhook endpoints to internal hosts
class webhook_proxy (
  Stdlib::Fqdn $cert_fqdn,
  Array[Stdlib::Fqdn] $jenkins_fqdns = [],
  Array[Stdlib::Http] $endpoints = [],
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
  String[1] $ssl_name = $cert_fqdn,
) {
  include nginx
  include ssl

  ssl::cert { $cert_fqdn: }

  nginx::resource::server { 'webhook':
    server_name          => [$canonical_fqdn],
    spdy                 => 'on',
    listen_port          => 443,
    ssl                  => true,
    ssl_cert             => "${ssl::cert_dir}/${ssl_name}_combined.crt",
    ssl_key              => "${ssl::key_dir}/${ssl_name}.key",
    use_default_location => false,
    client_max_body_size => '10M',
    format_log           => 'logstash_json',
    access_log           => '/var/log/nginx/webhook.access.log',
    error_log            => '/var/log/nginx/webhook.error.log',
    server_cfg_append    => {
      error_page             => '502 503 504 /puppet-private-maintenance.html',
      proxy_intercept_errors => 'on',
    },
  }

  nginx::resource::location { 'webhook __maintenance':
    server   => 'webhook',
    ssl      => true,
    ssl_only => true,
    location => '= /puppet-private-maintenance.html',
    internal => true,
    www_root => '/var/nginx/maintenance',
  }

  nginx::resource::location { 'webhook /':
    server              => 'webhook',
    ssl                 => true,
    ssl_only            => true,
    location            => '/',
    location_custom_cfg => { 'return' => '404' },
  }

  # General endpoints
  $endpoints.each |$endpoint| {
    webhook_proxy::endpoint { $endpoint: }
  }

  # Shortcut for Jenkins instances
  $jenkins_fqdns.each |$host| {
    # Handle pushes to a branch
    webhook_proxy::endpoint { "https://${host}/github-webhook/": }

    # Handle changes to a PR
    webhook_proxy::endpoint { "https://${host}/ghprbhook/": }
  }
}
