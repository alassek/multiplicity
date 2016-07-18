require 'spec_helper'
require 'support/active_record'

RSpec.describe Multiplicity::Adapters::ActiveRecord do
  subject { Multiplicity::Adapters::ActiveRecord }

  describe "connection_pool" do
    before(:each) { subject.connection_pool = nil }

    it "defaults to ActiveRecord::Base.connection_pool" do
      expect(subject.connection_pool).to be ActiveRecord::Base.connection_pool
    end

    it "can be overriden to something else" do
      expect{ subject.connection_pool = TestConnectionPool.new(:foo) }.to_not raise_error
      expect(subject.connection_pool).to be_a TestConnectionPool
    end
  end

  describe "find_by" do
    before(:each){ subject.connection_pool = ActiveRecord::Base.connection_pool }

    it "constructs a SQL query for select_one based on parameters" do
      expect(connection = double("Connection")).to receive(:select_one) { |query| query.to_sql }

      subject.connection_pool = TestConnectionPool.new(connection)

      query = subject.find_by :subdomain, 'quux'

      expect(query).to eq(%{SELECT "tenants"."id", "tenants"."subdomain", "tenants"."name", "tenants"."deleted_at" FROM "tenants" WHERE "tenants"."subdomain" = 'quux'})
    end

    it "returns the attributes for the record" do
      subject.connection_pool.with_connection do |connection|
        connection.execute "INSERT INTO tenants (id, subdomain, name) VALUES (321, 'quux', 'Quux Tenant')"
      end

      expect(subject.find_by(:subdomain, 'quux')).to include({
               'id' => 321,
        'subdomain' => 'quux',
             'name' => 'Quux Tenant'
      })
    end
  end
end
