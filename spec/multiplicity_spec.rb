require 'spec_helper'

RSpec.describe Multiplicity do
  describe "adapter" do
    it "can be set" do
      new_adapter = Class.new

      expect{ Multiplicity.adapter = new_adapter }.to_not raise_error
      expect(Multiplicity.adapter).to eq new_adapter
    end
  end

  describe "table_name" do
    before(:each){ Multiplicity.instance_variable_set(:@table, nil) }

    it "defaults to :tenants" do
      expect(Multiplicity.table_name).to eq :tenants
    end

    it "can be overridden" do
      expect{ Multiplicity.table_name = :foobar }.to_not raise_error
      expect(Multiplicity.table_name).to eq :foobar
    end
  end

  describe "domain" do
    it "can be set" do
      expect{ Multiplicity.domain = "example.com" }.to_not raise_error
      expect(Multiplicity.domain).to eq "example.com"
    end
  end
end
