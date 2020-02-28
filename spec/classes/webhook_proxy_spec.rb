# frozen_string_literal: true

require 'spec_helper'
require 'rspec-puppet-utils'

# The file function is used in the ssl module to pull in a string representing
# a certificate that is stored in a site's profile module. We mock it here as
# since the content of that string is not relevant to these tests.
def mock_file_function(return_value)
  MockFunction.new('file').expected.returns(return_value).at_least(:once)
end

describe 'webhook_proxy' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      before(:each) { mock_file_function('pem-formatted-data') }

      let(:node) { 'webhook.example.com' }

      let(:facts) { os_facts }

      let(:pre_condition) do
        "class { ssl:
          cert_source => 'profile/ssl',
          keys        => {
            'webhook.example.com' => 'some-private-key-data',
          },
        }"
      end

      context 'with only cert_fqdn set' do
        let(:params) do
          {
            'cert_fqdn' => 'webhook.example.com',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_nginx__resource__server('webhook').with_server_name(['webhook.example.com']) }
        it { is_expected.to contain_ssl__cert('webhook.example.com') }

        it {
          is_expected.to contain_nginx__resource__location('webhook /')
            .with_location('/')
            .with_location_custom_cfg('return' => '404')
        }
      end

      context 'when provided two enpoint urls' do
        let(:params) do
          {
            'cert_fqdn' => 'webhook.example.com',
            'endpoints' => [
              'https://pe-prod.internal.example.com:8170/code-manager/v1/webhook',
              'http://cd4pe-prod.internal.example.com:8000/github/push',
            ],
          }
        end

        it 'two endpoint resources are crated' do
          is_expected.to contain_webhook_proxy__endpoint('https://pe-prod.internal.example.com:8170/code-manager/v1/webhook')
          is_expected.to contain_nginx__resource__location('webhook = /pe-prod.internal.example.com:8170/code-manager/v1/webhook/')

          is_expected.to contain_webhook_proxy__endpoint('http://cd4pe-prod.internal.example.com:8000/github/push')
          is_expected.to contain_nginx__resource__location('webhook = /cd4pe-prod.internal.example.com:8000/github/push/')
        end
      end

      context 'when a Jenkins fqdn is provided' do
        let(:params) do
          {
            'cert_fqdn'     => 'webhook.example.com',
            'jenkins_fqdns' => ['jenkins.internal.example.com'],
          }
        end

        it 'github-webhook and ghprbhook endpoints are created' do
          is_expected.to contain_webhook_proxy__endpoint('https://jenkins.internal.example.com/github-webhook/')
          is_expected.to contain_nginx__resource__location('webhook = /jenkins.internal.example.com/github-webhook/')

          is_expected.to contain_webhook_proxy__endpoint('https://jenkins.internal.example.com/ghprbhook/')
          is_expected.to contain_nginx__resource__location('webhook = /jenkins.internal.example.com/ghprbhook/')
        end
      end
    end
  end
end
