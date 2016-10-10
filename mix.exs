defmodule ElasticsearchLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :elasticsearch_logger_backend,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: description()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :timex, :hackney, :poison]]
  end

  def description do
    """
    Send logs in batches via the elasticsearch bulk index api!
    """
  end

  def package do
    [# These are the default files included in the package
     name: :elasticsearch_logger_backend,
     files: ["lib", "mix.exs", "README*", "LICENSE*",],
     maintainers: ["Sam Schneider"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/sschneider1207/elasticsearch_logger_backend/",
      "Docs" => "https://hexdocs.pm/elasticsearch_logger_backend/"}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:timex, "~> 3.0"},
     {:hackney, "~> 1.6"},
     {:poison, "~> 3.0"},
     {:ex_doc, "~> 0.14.2", only: :dev}]
  end
end
