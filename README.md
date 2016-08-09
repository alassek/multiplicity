# Multiplicity

![build status](https://travis-ci.org/alassek/multiplicity.svg?branch=master)
![Gem Version](https://badge.fury.io/rb/multiplicity.svg)

Multiplicity is a gem for building multitenant Rack applications, with a much less opinionated approach than e.g. [Apartment](https://github.com/influitive/apartment) might entail.

The goal of this gem is to provide the simplest tools required to isolate your data, and then get out of your way.

It uses an adapter system to plug into your ORM framework of choice. Currently ActiveRecord is the only adapter included, but it is not a dependency and never will be.

Adapter contributions for additional ORMs are welcome.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'multiplicity'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install multiplicity

## Usage

Multiplicity expects a table that looks like this:

| id | subdomain | name         | deleted_at |
|----|-----------|--------------|------------|
| 1  | demo      | Demo Account | NULL       |

The table name defaults to `tenants` but can be set with `Multiplicity.table_name`.

First, choose your adapter.

```ruby
require 'multiplicity/adapters/active_record'
```

Second, set the default domain for your app.

```ruby
Multiplicity.domain = 'example.com'
```

The domain is purely a convenience setting, you can override this when calling `Multiplicity::Tenant#uri` by passing a domain as an argument.

Finally, load the middleware. Either `config.ru` for a Rack app, or perhaps `application.rb` for Rails.

```ruby
require 'multiplicity/middleware'
use Multiplicity::Middleware
```

This will automatically set `Multiplicity::Tenant.current` by subdomain for the duration of your request.

## Multiplicity::Tenant

This is the object that gets initialized by your tenant record from the db. It's just a simple [Virtus](https://github.com/solnic/virtus) model with some helper functions. It's been namespaced under `Multiplicity` so that you can be free to define your own tenant model.

### `.find_by(column_name, value)`

This performs a simple `SELECT` against a given column.

```ruby
Multiplicity::Tenant.current
# => nil
Multiplicity::Tenant.find_by :subdomain, 'demo'
# => #<Tenant id=1 subdomain=demo name="Demo Account" deleted_at=nil>
Multiplicity::Tenant.current
# => #<Tenant id=1 subdomain=demo name="Demo Account" deleted_at=nil>
```

### `.find_by!(column_name, value)`

Raises `Multiplicity::Tenant::UnknownTenantError` if tenant is not found.

### `.load(subdomain)`

Alias for `find_by :subdomain`

### `.current_id`

Returns the numeric id from `Multiplicity::Tenant.current` without having to care about nil traversal.

```ruby
Multiplicity::Tenant.current_id # => nil
Multiplicity::Tenant.load 'demo'
Multiplicity::Tenant.current_id # => 1
```

### `.use_tenant(subdomain, &block)`

Set a given tenant inside the block without changing the global context.

```ruby
Multiplicity::Tenant.current
# => #<Tenant id=1 subdomain=foo name="Foo Account" deleted_at=nil>
Multiplicity::Tenant.use_tenant('bar') do
  Multiplicity::Tenant.current
end
# => #<Tenant id=2 subdomain=bar name="Bar Account" deleted_at=nil>
Multiplicity::Tenant.current
# => #<Tenant id=1 subdomain=foo name="Foo Account" deleted_at=nil>
```

### `#archived?`

Simple convenience predicate to check if `deleted_at` is nil.

### `#uri(domain = Multiplicity.domain)`

Returns a `URI` object for the tenant's subdomain.

```ruby
Multiplicity::Tenant.current.uri
# => #<URI::HTTPS URL:https://demo.example.com>
Multiplicity::Tenant.current.uri('example.org')
# => #<URI::HTTPS URL:https://demo.example.org>
```

## Isolating data

Since Multiplicity doesn't impose opinions on how to do this, it doesn't include the logic for it. Here's an example using ActiveRecord's `default_scope` feature.

```ruby
# All multitenant models should descend from this
# parent, as they already should in Rails 5.0+
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.inherited(subclass)
    super

    return unless subclass.superclass == self
    return unless subclass.column_names.include? 'tenant_id'

    subclass.class_eval do
      default_scope ->{ where tenant_id: Multiplicity::Tenant.current_id }
    end
  end
end
```

Side-effects of `default_scope` that are normally downsides are upsides in this case. Every new record created in a tenant scope will automatically save the correct id.

But this is merely a suggestion. Do what works best for your business logic.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

You are, at some point, going to need to point a local url to your development machine to actually test the middleware, however most of the time you can actually just set `Multiplicity::Tenant.current` with a fake record.

```ruby
if Rails.env.development?
  Multiplicity::Tenant.current = Multiplicity::Tenant.new(id: 1, subdomain: 'demo', name: 'Demo Account')
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alassek/multiplicity.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
