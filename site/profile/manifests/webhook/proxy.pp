# Proxy external webhook endpoints to internal hosts
class profile::webhook::proxy (
  String[1] $canonical_fqdn = $facts['fqdn'],
) {
  profile::metadata::service { $title:
    human_name        => 'GitHub webhook proxy',
    owner_uid         => 'daniel.parks',
    team              => infracore,
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => '24x7',
    downtime_impact   => "Internal services aren't notfied about repo changes.",
    other_fqdns       => ['webhook.puppet.com'],
    notes             => @("NOTES"),
      This allows Github webhooks to access our internal servers. For example:

      ~~~ puppet
      profile::webhook::endpoint { 'https://jenkins.puppetlabs.com/github-webhook/': }
      ~~~

      Creates a webhook proxy so that GitHub can send notifications to the
      internal Ops Jenkins. The external URL will be
      `https://webhook.puppet.com/jenkins.puppetlabs.com/github-webhook/`.
      |-NOTES
  }

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

  # Endpoints for Jenkins instances
  [
    'jenkins.ops.puppetlabs.net',
    'jenkins-compose.delivery.puppetlabs.net',
    'jenkins-imaging.delivery.puppetlabs.net',
    'jenkins-perf.delivery.puppetlabs.net',
    'jenkins-release.delivery.puppetlabs.net',
    'jenkins.puppetlabs.com',
    'jenkins-cinext.delivery.puppetlabs.net',
    'jenkins-master01-blueocean-dev.delivery.puppetlabs.net',
    'jenkins-master-prod-1.delivery.puppetlabs.net',
    'cinext-jenkinsmaster-enterprise-prod-1.delivery.puppetlabs.net',
    'cinext-jenkinsmaster-sre-prod-1.delivery.puppetlabs.net',
    'jenkins-sre.delivery.puppetlabs.net'
  ].each |$host| {
    profile::webhook::endpoint {
      # Handle pushes to a branch
      "https://${host}/github-webhook/": ;
      # Handle changes to a PR
      "https://${host}/ghprbhook/": ;
    }
  }

  # Endpoints for Code Manager
  ['yoda.puppetlabs.com'].each |$host| {
    profile::webhook::endpoint {
      "https://${host}:8170/code-manager/v1/webhook/": ;
    }
  }

  profile::webhook::endpoint {
    # GitHub mirror
    "https://github-mirror.ops.puppetlabs.net/github-webhook/": ;
  }
}
