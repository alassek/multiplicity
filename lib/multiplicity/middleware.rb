module Multiplicity
  class Middleware
    attr_reader :app, :header

    def initialize(app, header = 'HTTP_HOST')
      @app    = app
      @header = header

      unless defined?(Multiplicity::Adapters)
        raise RuntimeError, "You must require an adapter to use Multiplicity"
      end
    end

    def call(env)
      subdomain = env[header].to_s.sub(/^http(s)?:\/\//, '').sub(/:[0-9]+$/, '')
      subdomain = subdomain.split('.')[0..-3].join('.').downcase if subdomain.split('.').length > 2
      subdomain = env.fetch('TENANT', 'localhost') if development?(subdomain)

      if subdomain.length > 0
        ::Multiplicity::Tenant.load(subdomain) or return not_found
      else
        return not_found
      end

      return gone if ::Multiplicity::Tenant.current.archived?

      @app.call(env)
    ensure
      ::Multiplicity::Tenant.current = nil
    end

    def not_found
      [404, { 'Content-Type' => 'text/plain', 'Content-Length' => '9' }, ['Not Found']]
    end

    def gone
      [410, { 'Content-Type' => 'text/plain', 'Content-Length' => '15' }, ['Tenant archived']]
    end

  private

    def development?(server_name)
      return true if server_name =~ /^localhost(?:\:[0-9]+)$/
      return true if server_name =~ /\.local$/
      return true if server_name =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?:\:[0-9]+)$/
      false
    end
  end
end
