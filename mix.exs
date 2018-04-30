defmodule Lru.MixProject do
  use Mix.Project

  def project do
    [
      app: :lru,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cbuf,
       git: "https://github.com/ckampfe/cbuf.git", ref: "b6d72b002c8be9cb438d745d2744f93fb3ec2971"},
      {:stream_data, "~> 0.1", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
