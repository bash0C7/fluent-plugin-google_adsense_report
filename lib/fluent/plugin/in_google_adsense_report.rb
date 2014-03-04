module Fluent
  class Fluent::GoogleAdsenseReportInput < Fluent::Input
    Fluent::Plugin.register_input('google_adsense_report', self)

    config_param :tag, :string
    config_param :run_interval,   :integer

    config_param :authorization_scope, :string, :default => 'https://www.googleapis.com/auth/adsense.readonly'
    config_param :authorization_client_id, :string
    config_param :authorization_client_secret, :string
    config_param :authorization_access_token, :string
    config_param :authorization_refresh_token, :string

    config_param :account_id, :string
    config_param :dimension, :string
    config_param :locale, :string
    config_param :max_results, :integer, :default => 5000
    config_param :metrics, :string
    config_param :use_timezone_reporting, :bool, :default => true

    attr_reader :client

    def initialize
      super

      require "google/api_client"
    end

    def configure(config)
      super

      @client = Google::APIClient.new(
        :authorization => :oauth_2,
        :application_name=> __FILE__,
        :application_version => 0,
      )

      @client.authorization.scope         = @authorization_scope
      @client.authorization.client_id     = @authorization_client_id
      @client.authorization.client_secret = @authorization_client_secret
      @client.authorization.access_token  = @authorization_access_token
      @client.authorization.refresh_token = @authorization_refresh_token

      @api_method = @client.discovered_api('adsense', 'v1.3').reports.generate
    end

    def start
      super
      @thread = Thread.new(&method(:run))
    end

    def execute
      date = Date.today.strftime('%Y-%m-%d')
      @client.authorization.fetch_access_token!
      response = @client.execute(
        :api_method => @api_method,
        :parameters => {
          :startDate=> date,
          :endDate=> date,
          :accountId=> @account_id,
          :dimension => [@dimension],
          :locale => @locale,
          :maxResults => @max_results,
          :metric => @metrics.split(','),
          :useTimezoneReporting => @use_timezone_reporting,
        }
      )

      header_names = response.data.headers.map {|h| h.name}
      header_names.shift
      result = response.data.rows.map do |row|
        channel = row.shift
        keys = header_names.map {|name| "#{channel}_#{name}"}
        alist = keys.zip row
        Hash[alist]
      end

      result
    end

    def run
      loop do
        execute.each do |result|
          Engine.emit @tag, Engine.now, result
        end
        sleep @run_interval
      end
    end

    def shutdown
      Thread.kill(@thread)
    end
  end
end