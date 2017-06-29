# Triplex

[![Build Status](https://travis-ci.org/ateliware/triplex.svg?branch=master)](https://travis-ci.org/ateliware/triplex)

An [apartment](https://github.com/influitive/apartment) for succesfull Phoenix
programmers.

## Installation

The package can be installed as:

1. Add `triplex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:triplex, "~> 0.1.0"}]
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

To create a table inside your tenant you can use the task
`mix triplex.gen.migration` or move a normal migration to the
`priv/YOUR_REPO/tenant_migrations` folder.

The schemas look the same way, nothing to change.

To run the tenant migrations, use the task `mix triplex.migrate`, it will
migrate all your existent tenants for you.

## Managing your tenants

You can use the functions `Triplex.create/1`, `Triplex.drop/1` and
`Triplex.rename/2` to manage your tenants. You may want to use them on your
tenant operations.

PS.: we encourage you to use an unchangable field as your tenant name, that
way you will not need to rename your tenant when changing the field.

## Using the tenant

Finally, but not less important, you must call the function
`Triplex.put_tenant/2` to any changeset, schema or query you are executing
on your "tenanted" tables.

