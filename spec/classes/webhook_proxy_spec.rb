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
      before(:each) { mock_file_function('pem-formatted-data')}

      let(:facts) { os_facts }

      let(:pre_condition) do
        "class { ssl:
          cert_source => 'profile/ssl',
          keys        => {
            'webhook.example.com' => 'some-private-key-data',
          },
        }"
      end

      let(:params) do
        {
          'cert_fqdn' => 'webhook.example.com',
        }
      end

      it { is_expected.to compile }
    end
  end
end
