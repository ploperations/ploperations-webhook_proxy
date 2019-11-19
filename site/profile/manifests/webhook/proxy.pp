# Proxy external webhook endpoints to internal hosts
class profile::webhook::proxy (
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
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
    include profile::fw::https
  }

  include profile::nginx

  profile::nginx::redirect { 'default':
    destination => "https://${canonical_fqdn}",
    default     => true,
    ssl         => true,
  }

  include ssl

  ssl::cert { 'webhook.puppet.com': }

  if $facts['classification']['stage'] == 'prod' {
    $ssl_name = 'webhook.puppet.com'
  } else {
    $ssl_name = 'wildcard.ops.puppetlabs.net'
  }

  nginx::resource::vhost { 'webhook':
    server_name          => [$canonical_fqdn],
    spdy                 => 'on',
    listen_port          => '443',
    ssl                  => true,
    ssl_cert             => "${ssl::cert_dir}/${ssl_name}_combined.crt",
    ssl_key              => "${ssl::key_dir}/${ssl_name}.key",
    use_default_location => false,
    client_max_body_size => '10M',
    format_log           => 'logstash_json',
    access_log           => '/var/log/nginx/webhook.access.log',
    error_log            => '/var/log/nginx/webhook.error.log',
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
    'jenkins.puppetlabs.com',
    'jenkins-cinext.delivery.puppetlabs.net',
    'jenkins-master-prod-1.delivery.puppetlabs.net',
    'cinext-jenkinsmaster-enterprise-prod-1.delivery.puppetlabs.net',
    'cinext-jenkinsmaster-sre-prod-1.delivery.puppetlabs.net',
    'jenkins-sre.delivery.puppetlabs.net',
    'cinext-jenkinsmaster-pipeline-prod-1.delivery.puppetlabs.net',
    'jenkins-pipeline.delivery.puppetlabs.net',
    'jenkins-pipeline-dev.delivery.puppetlabs.net',
  ].each |$host| {
    profile::webhook::endpoint {
      # Handle pushes to a branch
      "https://${host}/github-webhook/": ;
      # Handle changes to a PR
      "https://${host}/ghprbhook/": ;
    }
  }

  profile::webhook::endpoint {
    # Code Manager
    'https://yoda.puppetlabs.com:8170/code-manager/v1/webhook/': ;
    'https://puppet.ops.puppetlabs.net:8170/code-manager/v1/webhook': ;
    'https://pe-infranext-prod.infc-aws.puppet.net:8170/code-manager/v1/webhook': ;
    'https://pe-infranext-test.infc-aws.puppet.net:8170/code-manager/v1/webhook': ;
    'http://pe-cd4pe-infranext-prod-1.infc-aws.puppet.net:8000/github/push': ;
    'http://pe-cd4pe-infranext-test-1.infc-aws.puppet.net:8000/github/push': ;
    # Argo CD
    'https://argocd.k8s.infracore.puppet.net/api/webhook': ;
    # Atlantis Endpoint
    'http://forge-ci-prod-1.ops.puppetlabs.net:4141/events':;
  }
}
