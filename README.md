# Triplex

[![Build Status](https://travis-ci.org/ateliware/triplex.svg?branch=master)](https://travis-ci.org/ateliware/triplex)
[![Hex pm](http://img.shields.io/hexpm/v/triplex.svg?style=flat)](https://hex.pm/packages/triplex)
[![Coverage Status](https://coveralls.io/repos/github/ateliware/triplex/badge.svg?branch=master)](https://coveralls.io/github/ateliware/triplex?branch=master)
[![Code Climate](https://img.shields.io/codeclimate/github/ateliware/triplex.svg)](https://codeclimate.com/github/ateliware/triplex)
[![Inline docs](http://inch-ci.org/github/ateliware/triplex.svg?branch=master&style=flat)](http://inch-ci.org/github/ateliware/triplex)

Triplex is an elixir lib that makes multitenancy based on separate
databases/schemas easier for you!

With one line of configuration and some function calls you can create, drop and
migrate your tenant databases, as well as executing ecto queries and commands
inside them.

It is inspired by the gem [apartment](https://github.com/influitive/apartment),
which does exactly the same on the Ruby on Rails world.

We may also give some credit (and a lot of thanks) to @Dania02525 for the work
on [apartmentex](https://github.com/Dania02525/apartmentex), a lot of the work
here is based on what she has done there. And also to @jeffdeville which made a
fork of it ([tenantex](https://github.com/jeffdeville/tenantex)) with a
different approach, which gave us some ideas too.

## Installation

The package can be installed as:

1. Add `triplex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:triplex, "~> 1.1.5"}]
end
```

2. Run in your shell:

```bash
mix deps.get
```

## Configuration

All you need to do in your project to start using it is to configure the Repo
you will use to execute the database commands with:

    config :triplex, repo: ExampleApp.Repo

## Usage

Here is a quick overview of what you can do with triplex!

### Creating, renaming and droping tenants

To create a new tenant:

```elixir
Triplex.create("your_tenant")
```

PS.: this will run the migrations, so it's a function that takes a while to
complete depending on how much migrations you have.

If you change your mind and want to rename te tenant:

```elixir
Triplex.rename("your_tenant", "my_tenant")
```

PS.: we encourage you to use an unchangable thing as your tenant name, that
way you will not need to rename your tenant when changing the field.

And if you're sick of it and want to drop:

```elixir
Triplex.drop("my_tenant")
```

More information on `Triplex` module documentation.

### Creating tables inside tenant

To create a table inside your tenant you can use:

```bash
mix triplex.gen.migration your_migration_name
```

Also, you can move a normally generated migrations from inside
`priv/YOUR_REPO/migrations` to the `priv/YOUR_REPO/tenant_migrations`
folder.

The schemas look the same way, nothing to change.

To run the tenant migrations, just run:

```bash
mix triplex.migrate
```

This task will migrate all your existent tenants, one by one. If it
fail in any tenant, the next time you run it will continue from where
it stoped.

If you need more information, check the `Mix.Triplex` documentation, where
you can find the list of tasks and their descriptions.

### Querying, updating and inserting data inside tenants

To make queries, updates and inserts inside your tenant is quite easy.
Just send a `prefix` opt on your repo call with your current tenant name.
Like this:

```elixir
Repo.all(User, prefix: Triplex.to_prefix("my_tenant"))
```

It's a good idea to call `Triplex.to_prefix/1` on your tenant name, altough is
not required. Because, if you configured a `tenant_prefix`, this function will
return the prefixed one.

### Loading the current tenant to your `Plug.Conn`

We have some basic and configurable plugs you can use to load the current
tenant on your web app. Here is an example loading it from the subdomain:

```elixir
plug Triplex.SubdomainPlug, endpoint: MyApp.Endpoint
```

For more information, check the `Triplex.Plug` documentation for an overview of
our plugs.
