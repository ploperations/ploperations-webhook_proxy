# @summary Proxy external webhook endpoints to internal hosts
#
# Proxy external webhook endpoints to internal hosts
#
# @param [Stdlib::Fqdn] cert_fqdn
#   The FQDN of the certificate to be used by the proxy
#
# @param [Array[Stdlib::Fqdn]] jenkins_fqdns
#   An array of FQDN's of Jenkins instances that need to receive
#   webhooks from GitHub
#
# @param [Array[Stdlib::Httpurl]] endpoints
#   An array of url's that webhook will be able to be delivered to
#
# @param [String[1]] canonical_fqdn
#   The FQDN to be used by Nginx as the server name.
#
# @param [String[1]] ssl_name
#   The FQDN of the associated cert. Genrally this is the same as
#   `$cert_fqdn` but may also be something like `wildcard.example.com`
#   when you are using a wildcard cert to cover `webhooks.example.com`.
#
# @param [Optional[String[1]]] format_log
#   The log format to be passed through to `nginx::resource::server`
#
# @param [Optional[Hash]] server_cfg_append
#   Any additional configuration you wish to passed through to
#   `nginx::resource::server`
#
# @example Proxy a Jenkins server, Code Manager, and CD4PE
#   class { 'webhook_proxy':
#     cert_fqdn     => 'webhook.example.com',
#     jenkins_fqdns => [ 'jenkins.internal.example.com' ],
#     endpoints     => [
#       'https://pe-prod.internal.example.com:8170/code-manager/v1/webhook',
#       'http://cd4pe-prod.internal.example.com:8000/github/push',
#     ],
#   }
#
# @example A profile that provides additional configuration for Nginx
#   class profile::webhook::proxy (
#     String[1] $canonical_fqdn = $facts['networking']['fqdn'],
#   ) {
#     include profile::nginx
#
#     profile::nginx::redirect { 'default':
#       destination => "https://${canonical_fqdn}",
#       default     => true,
#       ssl         => true,
#     }
#
#     class { 'webhook_proxy':
#       cert_fqdn         => 'webhook.example.com',
#       jenkins_fqdns     => [
#         'jenkins-prod.internal.example.com',
#         'jenkins-test.internal.example.com',
#       ],
#       endpoints         => [
#         'https://pe-prod.internal.example.com:8170/code-manager/v1/webhook',
#         'http://cd4pe-prod.internal.example.com:8000/github/push',
#       ],
#       canonical_fqdn    => $canonical_fqdn,
#       format_log        => 'logstash_json',
#       server_cfg_append => {
#         error_page             => '502 503 504 /private-maintenance.html',
#         proxy_intercept_errors => 'on',
#       },
#       ssl_name          => 'webhook.example.com',
#     }
#
#     nginx::resource::location { 'webhook __maintenance':
#       server   => 'webhook',
#       ssl      => true,
#       ssl_only => true,
#       location => '= /private-maintenance.html',
#       internal => true,
#       www_root => '/var/nginx/maintenance',
#     }
#   }
#
class webhook_proxy (
  Stdlib::Fqdn $cert_fqdn,
  Array[Stdlib::Fqdn] $jenkins_fqdns = [],
  Array[Stdlib::Httpurl] $endpoints = [],
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
  String[1] $ssl_name = $cert_fqdn,
  Optional[String[1]] $format_log = undef,
  Optional[Hash] $server_cfg_append = undef,
) {
  include nginx
  include ssl

  ssl::cert { $cert_fqdn: }

  nginx::resource::server { 'webhook':
    server_name          => [$canonical_fqdn],
    http2                => 'on',
    listen_port          => 443,
    ssl                  => true,
    ssl_cert             => "${ssl::cert_dir}/${ssl_name}_combined.crt",
    ssl_key              => "${ssl::key_dir}/${ssl_name}.key",
    use_default_location => false,
    client_max_body_size => '10M',
    format_log           => $format_log,
    access_log           => '/var/log/nginx/webhook.access.log',
    error_log            => '/var/log/nginx/webhook.error.log',
    server_cfg_append    => $server_cfg_append,
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
