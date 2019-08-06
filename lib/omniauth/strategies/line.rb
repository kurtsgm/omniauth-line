require 'omniauth-oauth2'
require 'json'

module OmniAuth
  module Strategies
    class Line < OmniAuth::Strategies::OAuth2
      option :name, 'line'
      option :scope, 'profile openid email'

      option :client_options, {
        site: 'https://access.line.me',
        authorize_url: '/oauth2/v2.1/authorize',
        token_url: '/oauth2/v2.1/token'
      }

      # host changed
      def callback_phase
        options[:client_options][:site] = 'https://api.line.me'
        super
      end

      def callback_url
        full_host + script_name + callback_path
      end

      uid { raw_info['userId'] }

      info do
        Rails.logger.info "INFO here"
        Rails.logger.info access_token.params
        Rails.logger.info  ENV['LINE_CHANNEL_SECRET']
        Rails.logger.info raw_info

        {
          name:        raw_info['displayName'],
          image:       raw_info['pictureUrl'],
          description: raw_info['statusMessage'],
          email: JWT.decode(access_token.params['id_token'], ENV['LINE_CHANNEL_SECRET']).first['email']
        }
      end

      # Require: Access token with PROFILE permission issued.
      def raw_info
        @raw_info ||= JSON.load(access_token.get('v2/profile').body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end

    end
  end
end
