require 'virtus'
require 'uri'

module Multiplicity
  class Tenant
    UnknownTenantError = Class.new(StandardError)

    include Virtus.model(nullify_blank: true)

    attribute :id, Integer
    attribute :subdomain, String
    attribute :name, String
    attribute :deleted_at, DateTime

    def archived?
      !!deleted_at
    end

    def uri(domain = Multiplicity.domain)
      URI("https://#{ subdomain }.#{ domain }")
    end

    class << self
      def column_names
        attribute_set.map(&:name)
      end

      def current
        Thread.current[:multiplicity_tenant]
      end

      def current=(value)
        Thread.current[:multiplicity_tenant] = value
      end

      def current_id
        current && current.id
      end

      def use_tenant(subdomain)
        previous = Tenant.current
        find_by :subdomain, subdomain
        yield
      ensure
        self.current = previous
      end

      def load(subdomain)
        find_by :subdomain, subdomain
      end

      def find_by(field, value)
        return current if current && current.send(field) == value

        record = Multiplicity.adapter.find_by(field, value)

        self.current = nil
        self.current = new(record) if record
      end

      def find_by!(field, value)
        find_by(field, value) or raise UnknownTenantError, "Unknown Tenant #{field}: #{value}"
      end
    end
  end
end
