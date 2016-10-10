# ElasticsearchLoggerBackend

Send logs in batches via the elasticsearch bulk index api!

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `elasticsearch_logger_backend` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:elasticsearch_logger_backend, "~> 0.1.0"}]
    end
    ```

  2. Ensure `elasticsearch_logger_backend` is started before your application:

    ```elixir
    def application do
      [applications: [:elasticsearch_logger_backend]]
    end
    ```

## Usage

  Application config:

  ```elixir
  config :logger,
    backends: [{ElasticsearchLoggerBackend, :es_log}]

  config :logger, :es_log, [
    level: :info,
    index_format: "index-{YYYY}.{0M}.{0D}",
    elasticsearch_uri: "http://elasticsearch:9200/"
  ]
  ```

  Runtime config:

  ```elixir
  Logger.add_backend({ElasticsearchLoggerBackend, :es_log})
  Logger.configure_backend({ElasticsearchLoggerBackend, :es_log}, [
    elasticsearch_uri: "http://elasticsearch:9200/",
    index_format: "index-{YYYY}.{0M}.{0D}",
    level: :info,
  ])
  ```

## Config Options

  * `level` - The minimum level to be logged by this backend.
  * `metadata` -  The metadata to be included as fields on the event. Defaults to an empty list (no metadata).
  * `elasticsearch_uri` - Uri of the elasticsearch instance used for logs.
  * `type` - Type used for log events.  Defaults to `logevent`
  * `index_format` - Index used for log events.  Can be a [Timex format string](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html) to include date information, such as `"index-{YYYY}.{0M}.{0D}"`
  * `ship_interval` -  How often buffered log events are sent to the elasticsearch cluster.  Defaults to `5_000`ms,
  * `timezone` - Timex timezone used in formatting the `@timestamp` field.  Default to `:utc`.
