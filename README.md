# Triplex

[![Build Status](https://travis-ci.org/ateliware/triplex.svg?branch=master)](https://travis-ci.org/ateliware/triplex)

An [apartment](https://github.com/influitive/apartment) for succesfull Phoenix
programmers.

## Installation

The package can be installed as:

1. Add `triplex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:triplex, "~> 0.8.0"}]
end
```

2. Run in your shell:

```bash
mix deps.get
```

## Configuring

All you need to do in your project to start using it is to configure the Repo
you will use to execute the database commands with:

    config :triplex, repo: ExampleApp.Repo

## Creating tables and schemas

To create a table inside your tenant you can use:

```bash
mix triplex.gen.migration
```

Also, you can move a normally generated migration to the
`priv/YOUR_REPO/tenant_migrations` folder.

The schemas look the same way, nothing to change.

To run the tenant migrations, just run:

```bash
mix triplex.migrate
```

This task will migrate all your existent tenants, one by one.

## Managing your tenants

To create a tenant:

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

## Using the tenant

To use your tenant is quite easy. Just send a `prefix` opt on your repo call
with your current tenant name. Like this:

```elixir
Repo.all(User, prefix: Triplex.to_prefix("my_tenant"))
```

It's a good idea to call `Triplex.to_prefix` on your tenant name, altough is
not required. Because, if you configured a `tenant_prefix`, this function will
return the prefixed one.
