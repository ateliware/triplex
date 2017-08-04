defmodule Triplex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :triplex,
      version: "1.0.0",
      elixir: "~> 1.4",

      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]],
      name: "Triplex",
      source_url: "https://github.com/ateliware/triplex"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 2.1"},
      {:plug, "~> 1.3.5"},
      {:postgrex, ">= 0.11.0"},

      {:ex_doc, ">= 0.0.0", only: :dev},

      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, only: :test},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["db.migrate": ["ecto.migrate", "triplex.migrate"],
     "test.reset": ["ecto.drop", "ecto.create", "db.migrate"],
     "test.cover": &run_default_coverage/1,
     "test.cover.html": &run_html_coverage/1]
  end

  defp description do
    """
    An https://github.com/influitive/apartment for succesfull Phoenix
		programmers.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :triplex,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Kelvin Stinghen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ateliware/triplex"}
    ]
  end

  defp preferred_cli_env do
    ["coveralls": :test,
     "coveralls.travis": :test,
     "coveralls.detail": :test,
     "coveralls.post": :test,
     "coveralls.html": :test,
     "test.reset": :test]
  end

  defp run_default_coverage(args), do: run_coverage("coveralls", args)
  defp run_html_coverage(args), do: run_coverage("coveralls.html", args)
  defp run_coverage(task, args) do
    {_, res} = System.cmd "mix", [task | args],
                          into: IO.binstream(:stdio, :line),
                          env: [{"MIX_ENV", "test"}]

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
