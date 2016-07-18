require 'spec_helper'
require 'pry'

RSpec.describe Multiplicity::Tenant do
  subject{ Multiplicity::Tenant }

  let(:tenant_record){ { 'id' => 1, 'subdomain' => value, 'name' => 'Test Tenant' } }

  describe "find_by" do
    it "finds a record by an arbitrary column" do
      Multiplicity.adapter = double("TestAdapter")

      expect(Multiplicity.adapter).to receive(:find_by).with(:id, 1)
      expect(Multiplicity.adapter).to receive(:find_by).with(:subdomain, 'foobar')
      expect(Multiplicity.adapter).to receive(:find_by).with(:name, "Test Tenant")

      subject.find_by :id, 1
      subject.find_by :subdomain, 'foobar'
      subject.find_by :name, "Test Tenant"
    end

    it "initializes a new instance with the attributes from `find_by`" do
      Multiplicity.adapter = double("TestAdapter")

      expect(Multiplicity.adapter).to receive(:find_by).and_return('id' => 2, 'subdomain' => 'foo2', 'name' => 'Test 2')

      tenant = subject.load('foo2')

      expect(tenant.id).to eq 2
      expect(tenant.subdomain).to eq 'foo2'
      expect(tenant.name).to eq 'Test 2'

      expect(subject.current).to eq tenant
      expect(subject.current).to be_a(subject)
    end

    it "Short-circuits if the requested Tenant is already loaded" do
      Multiplicity.adapter = double("TestAdapter")
      subject.current      = subject.new(id: 123, subdomain: 'foo123', name: 'Test 123')

      expect(Multiplicity.adapter).not_to receive(:find_by)

      subject.find_by :id, 123
      subject.find_by :subdomain, 'foo123'
      subject.find_by :name, 'Test 123'
    end
  end

  describe "find_by!" do
    it "raises UnknownTenantError if there is no result" do
      Multiplicity.adapter = double("TestAdapter")

      expect(Multiplicity.adapter).to receive(:find_by).and_return(nil)

      expect{ subject.find_by!(:subdomain, 'foo') }.to raise_error(subject::UnknownTenantError)
    end
  end

  describe "load" do
    it "Finds a Tenant by subdomain" do
      Multiplicity.adapter = double("TestAdapter")

      expect(Multiplicity.adapter).to receive(:find_by).with(:subdomain, 'foobar')

      subject.load 'foobar'
    end
  end

  describe "use_tenant" do
    it "sets a temporary Tenant inside a block" do
      Multiplicity.adapter = double("TestAdapter")
      subject.current      = subject.new(id: 3, subdomain: 'foo3', name: 'Test 3')

      expect(Multiplicity.adapter).to receive(:find_by).and_return('id' => 4, 'subdomain' => 'foo4', 'name' => 'Test 4')

      expect(subject.current_id).to eq 3

      subject.use_tenant('foo4') do
        expect(subject.current_id).to eq 4
      end

      expect(subject.current_id).to eq 3
    end
  end

  describe "column_names" do
    it "returns a list of the attributes for the model" do
      expect(Multiplicity::Tenant.column_names).to include(:id, :subdomain, :name, :deleted_at)
    end
  end

  describe '#archived?' do
    it "returns true if deleted_at exists" do
      archived = subject.new(id: 1, subdomain: 'foo', name: 'Foo', deleted_at: Time.now)
      active   = subject.new(id: 2, subdomain: 'bar', name: 'Bar')

      expect(archived.archived?).to be true
      expect(active.archived?).to be false
    end
  end

  describe '#uri' do
    before(:each) { Multiplicity.domain = "example.org" }

    let(:tenant){ subject.new(id: 3, subdomain: 'baz', name: 'Baz') }

    it "builds a URI based on #subdomain and Multiplicity.domain" do
      expect(tenant.uri).to eq URI("https://baz.example.org")
    end

    it "accepts an override domain as an argument" do
      expect(tenant.uri('example.com')).to eq URI("https://baz.example.com")
    end
  end
end
