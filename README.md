# Saj

*inspired by [JsonStreamingParser](https://github.com/salsify/jsonstreamingparser)*

This is a simple, streaming parser for processing large JSON documents. Use it for parsing very large JSON documents to avoid loading the entire thing into memory

[Documentation](https://hexdocs.pm/saj/api-reference.html)

## Installation

The package can be installed as:

  1. Add `saj` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:saj, "~> 0.1.0"}]
    end
    ```

  2. Ensure `saj` is started before your application:

    ```elixir
    def application do
      [applications: [:saj]]
    end
    ```
