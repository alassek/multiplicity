require 'multiplicity/version'
require 'multiplicity/tenant'

module Multiplicity
  def self.adapter; @adapter; end

  def self.adapter=(adapter)
    @adapter = adapter
  end

  def self.table_name
    @table ||= :tenants
  end

  def self.table_name=(value)
    @table = value.to_sym
  end

  def self.domain; @domain; end

  def self.domain=(uri)
    @domain = uri.to_s
  end
end

# Load Subdomain by default until there are multiple strategies
require 'multiplicity/middleware/subdomain'
# Always load AR adapter for now, until there is more than one
require 'multiplicity/adapters/active_record'
