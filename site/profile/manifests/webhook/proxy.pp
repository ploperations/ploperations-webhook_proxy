# Proxy external webhook endpoints to internal hosts
class profile::webhook::proxy (
  String[1] $canonical_fqdn = $facts['fqdn'],
) {
  if $::profile::server::params::fw {
    include ::profile::fw::https
  }

  include ::profile::nginx

  profile::nginx::redirect { 'default':
    destination => "https://${canonical_fqdn}",
    default     => true,
    ssl         => true,
  }

  $ssl = profile::ssl::host_info($canonical_fqdn)
  nginx::resource::vhost { 'webhook':
    server_name          => [$canonical_fqdn],
    spdy                 => 'on',
    listen_port          => '443',
    ssl                  => true,
    ssl_cert             => $ssl['cert'],
    ssl_key              => $ssl['key'],
    use_default_location => false,
    client_max_body_size => '10M',
    format_log           => 'logstash_json',
    access_log           => "/var/log/nginx/webhook.access.log",
    error_log            => "/var/log/nginx/webhook.error.log",
    vhost_cfg_append     => {
      error_page             => '502 503 504 /puppet-private-maintenance.html',
      proxy_intercept_errors => 'on',
    },
  }

  nginx::resource::location { 'webhook __maintenance':
    vhost    => 'webhook',
    ssl      => true,
    ssl_only => true,
    location => '= /puppet-private-maintenance.html',
    internal => true,
    www_root => '/var/nginx/maintenance',
  }

  nginx::resource::location { 'webhook /':
      vhost               => 'webhook',
      ssl                 => true,
      ssl_only            => true,
      location            => '/',
      location_custom_cfg => { 'return' => '404' },
  }

  profile::webhook::endpoint {
    'https://jenkins.ops.puppetlabs.net/github-webhook/': ;
    'https://jenkins-beaker.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-compose.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-enterprise.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-imaging.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-modules-dev.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-modules.puppetlabs.com/github-webhook/': ;
    'https://jenkins-perf.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-release.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-staging.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins.puppetlabs.com/github-webhook/': ;
    'https://jenkins-qe.delivery.puppetlabs.net/github-webhook/': ;
    'https://jenkins-cinext.delivery.puppetlabs.net/github-webhook/': ;
  }
}
