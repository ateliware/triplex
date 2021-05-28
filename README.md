# Triplex

[![Build Status](https://travis-ci.org/ateliware/triplex.svg?branch=master)](https://travis-ci.org/ateliware/triplex)
[![Version](http://img.shields.io/hexpm/v/triplex.svg?style=flat)](https://hex.pm/packages/triplex)
[![Downloads](https://img.shields.io/hexpm/dt/triplex.svg)](https://hex.pm/packages/triplex)
[![Coverage Status](https://coveralls.io/repos/github/ateliware/triplex/badge.svg?branch=master)](https://coveralls.io/github/ateliware/triplex?branch=master)
[![Code Climate](https://img.shields.io/codeclimate/github/ateliware/triplex.svg)](https://codeclimate.com/github/ateliware/triplex)
[![Inline docs](http://inch-ci.org/github/ateliware/triplex.svg?branch=master&style=flat)](http://inch-ci.org/github/ateliware/triplex)

A simple and effective way to build multitenant applications on top of Ecto.

[Documentation](https://hexdocs.pm/triplex/readme.html)

Triplex leverages database data segregation techniques (such as [Postgres schemas](https://www.postgresql.org/docs/current/static/ddl-schemas.html)) to keep tenant-specific data separated, while allowing you to continue using the Ecto functions you are familiar with.



## Quick Start

1. Add `triplex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:triplex, "~> 1.3.0"},
  ]
end
```

2. Run in your shell:

```bash
mix deps.get
```


## Configuration

Configure the Repo you will use to execute the database commands with:

    config :triplex, repo: ExampleApp.Repo

### Additional configuration for MySQL

In MySQL, each tenant will have its own MySQL database.
Triplex used to use a table called `tenants` in the main Repo to keep track of the different tenants.
If you wish to keep this behavior, generate the migration that will create the table by running:

    mix triplex.mysql.install

And then create the table:

    mix ecto.migrate

Finally, configure Triplex to use the `tenants` table:

    config :triplex, tenant_table: :tenants

Otherwise, Triplex will continue to use the `information_schema.schemata` table as the default behavior for storing tenants.

## Usage

Here is a quick overview of what you can do with triplex!


### Creating, renaming and dropping tenants


#### To create a new tenant:

```elixir
Triplex.create("your_tenant")
```

This will create a new database schema and run your migrations—which may take a while depending on your application.


#### Rename a tenant:

```elixir
Triplex.rename("your_tenant", "my_tenant")
```

This is not something you should need to do often. :-)


#### Delete a tenant:

```elixir
Triplex.drop("my_tenant")
```

More information on the API can be found in [documentation](https://hexdocs.pm/triplex/Triplex.html#content).


### Creating tenant migrations

To create a migration to run across tenant schemas:

```bash
mix triplex.gen.migration your_migration_name
```

If migrating an existing project to use Triplex, you can move some or all of your existing migrations from `priv/YOUR_REPO/migrations` to  `priv/YOUR_REPO/tenant_migrations`.

Triplex and Ecto will automatically add prefixes to standard migration functions.  If you have _custom_ SQL in your migrations, you will need to use the [`prefix`](https://hexdocs.pm/ecto/Ecto.Migration.html#prefix/0) function provided by Ecto. e.g.

```elixir
def up do
  execute "CREATE INDEX name_trgm_index ON #{prefix()}.users USING gin (nam gin_trgm_ops);"
end
```


### Running tenant migrations:

```bash
mix triplex.migrate
```

This will migrate all of your existing tenants, one by one.  In the case of failure, the next run will continue from where it stopped.


### Using Ecto

Your Ecto usage only needs the `prefix` option.  Triplex provides a helper to coerce the tenant value into the proper format, e.g.:

```elixir
Repo.all(User, prefix: Triplex.to_prefix("my_tenant"))
Repo.get!(User, 123, prefix: Triplex.to_prefix("my_tenant"))
```


### Fetching the tenant with Plug

Triplex includes configurable plugs that you can use to load the current tenant in your application.

Here is an example loading the tenant from the current subdomain:

```elixir
plug Triplex.SubdomainPlug, endpoint: MyApp.Endpoint
```

For more information, check the `Triplex.Plug` documentation for an overview of our plugs.


## Thanks

This lib is inspired by the gem [apartment](https://github.com/influitive/apartment), which does the same thing in Ruby on Rails world. We also give credit (and a lot of thanks) to @Dania02525 for the work on [apartmentex](https://github.com/Dania02525/apartmentex).  A lot of the work here is based on what she has done there.  And also to @jeffdeville, who forked ([tenantex](https://github.com/jeffdeville/tenantex)) taking a different approach, which gave us additional ideas.
