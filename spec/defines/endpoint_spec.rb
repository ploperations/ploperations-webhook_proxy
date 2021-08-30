# frozen_string_literal: true

require 'spec_helper'

describe 'webhook_proxy::endpoint' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with a url that does not have a trailing /' do
        let(:title) { 'https://pe-prod.internal.example.com:8170/code-manager/v1/webhook' }

        it { is_expected.to compile }
        it {
          is_expected.to contain_nginx__resource__location('webhook = /pe-prod.internal.example.com:8170/code-manager/v1/webhook')
            .with_location('= /pe-prod.internal.example.com:8170/code-manager/v1/webhook')
        }
      end

      context 'with a url that includes a trailing /' do
        let(:title) { 'https://jenkins.internal.example.com/ghprbhook/' }

        it { is_expected.to compile }
        it {
          is_expected.to contain_nginx__resource__location('webhook = /jenkins.internal.example.com/ghprbhook/')
            .with_location('= /jenkins.internal.example.com/ghprbhook/')
        }
      end
    end
  end
end
