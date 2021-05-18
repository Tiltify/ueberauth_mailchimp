defmodule UeberauthMailchimp.Mixfile do
  use Mix.Project

  @version "0.1.5"

  def project do
    [
      app: :ueberauth_mailchimp,
      version: @version,
      name: "Ueberauth Mailchimp",
      package: package(),
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/Tiltify/ueberauth_mailchimp",
      homepage_url: "https://github.com/Tiltify/ueberauth_mailchimp",
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.6"},
      {:jason, "~> 1.0"},

      # dev/test dependencies
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md", "CONTRIBUTING.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Mailchimp to authenticate your users"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Tiltify"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/Tiltify/ueberauth_mailchimp"}
    ]
  end
end
