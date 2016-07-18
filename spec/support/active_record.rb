require 'active_record'

$arel_silence_type_casting_deprecation = true
ActiveSupport::Deprecation.silenced = true

ActiveRecord::Base.configurations = {
  'test' => {
    'adapter'   => 'sqlite3',
    'database'  => ':memory:',
    'verbosity' => 'quiet'
  }
}

ActiveRecord::Base.establish_connection :test

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :tenants do |t|
    t.string :subdomain, length: 63
    t.string :name
    t.datetime :deleted_at
  end

  create_table :widgets do |t|
    t.string :name
    t.references :tenant
    t.timestamps
  end
end

class Tenant < ActiveRecord::Base
  has_many :widgets
end

class Widget < ActiveRecord::Base
  belongs_to :tenant

  default_scope ->{ where tenant_id: Multiplicity::Tenant.current_id }
end

class TestConnectionPool
  attr_reader :connection

  def initialize(connection)
    @connection = connection
  end

  def with_connection
    yield connection
  end
end
