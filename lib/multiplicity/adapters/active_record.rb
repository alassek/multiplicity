module Multiplicity
  module Adapters
    class ActiveRecord
      def self.connection_pool
        Thread.current[:multiplicity_connection_pool] ||= ::ActiveRecord::Base.connection_pool
      end

      def self.connection_pool=(pool)
        Thread.current[:multiplicity_connection_pool] = pool
      end

      def self.find_by(field, value)
        table   = Arel::Table.new(Multiplicity.table_name)
        columns = Multiplicity::Tenant.column_names.map{|col| table[col] }
        query   = table.where(table[field].eq(value)).project(columns)

        connection_pool.with_connection do |connection|
          connection.select_one query
        end
      end
    end
  end
end

begin
  gem 'activerecord', '>= 3.1'
rescue Gem::LoadError => e
  raise Gem::LoadError, "You are using functionality requiring
     the optional gem dependency `#{e.name}`, but the gem is not
     loaded, or is not using an acceptable version. Add
     `gem '#{e.name}'` to your Gemfile. Version #{Multiplicity::VERSION}
     of multiplicity requires #{e.name} that matches #{e.requirement}".gsub(/\n/, '').gsub(/\s+/, ' ')
end

require 'active_support/lazy_load_hooks'
ActiveSupport.on_load(:active_record) do
  Multiplicity.adapter = Multiplicity::Adapters::ActiveRecord
end
