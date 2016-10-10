defmodule ElasticsearchLoggerBackend do

  defmodule State do
    defstruct [
      name: nil,
      level: nil,
      metadata: [],
      elasticsearch_uri: nil,
      type: :logevent,
      index_format: "log_events",
      ship_interval: 5_000,
      timezone: :utc,
      buffer: []
    ]
  end

  def init({__MODULE__, name}) do
    state = configure(name, [], nil)
    Process.send_after(self(), :ship, state.ship_interval)
    {:ok, state}
  end

  def handle_call({:configure, opts}, state) do
    {:ok, :ok, configure(state.name, opts, state.buffer)}
  end

  def handle_info(:ship, state) do
    buffer = case send_buffer(state) do
      :ok -> []
      :error -> state.buffer
    end
    Process.send_after(self(), :ship, state.ship_interval)
    {:ok, %{state| buffer: buffer}}
  end
  def handle_info(_msg, state) do
    {:ok, state}
  end

  def handle_event(:flush, state) do
    buffer = case send_buffer(state) do
      :ok -> []
      :error -> state.buffer
    end
    {:ok, %{state| buffer: buffer}}
  end
  def handle_event({level, group_leader, {Logger, _message, _timestamp, _metadata}} = log, state) do
    buffer = case should_log?(group_leader, level, state.level) do
      true -> [log|state.buffer]
      false -> state.buffer
    end
    {:ok, %{state| buffer: buffer}}
  end

  defp configure(name, opts, nil) do
    get_and_refresh_opts(name, opts)
    |> state(name)
  end
  defp configure(name, opts, buffer) do
    get_and_refresh_opts(name, opts)
    |> Keyword.put(:buffer, buffer)
    |> state(name)
  end

  defp get_and_refresh_opts(name, opts) do
    all_opts =
      Application.get_env(:logger, name, [])
      |> Keyword.merge(opts)
    Application.put_env(:logger, name, all_opts)
    all_opts
  end

  defp state(opts, name) do
    State
    |> struct(opts)
    |> Map.put(:name, name)
  end

  defp should_log?(gl, _level, _min_level) when node(gl) != node(), do: false
  defp should_log?(_gl, _level, nil), do: true
  defp should_log?(_gl, level, min_level) do
    case Logger.compare_levels(level, min_level) do
      :lt -> false
      _ -> true
    end
  end

  defp send_buffer(%{buffer: []}), do: :ok
  defp send_buffer(state) do
    json = logs_to_json(state)
    url = Path.join(state.elasticsearch_uri, "_bulk")
    case :hackney.request(:post, url, [], json, []) do
      {:ok, 200, _resp_headers, _ref} -> :ok
      _ -> :error
    end
  end

  defp logs_to_json(state) do
    state.buffer
    |> Enum.map(&convert_log(&1, state))
    |> Enum.reduce([], fn {op, log}, acc -> [op|[log|acc]] end)
    |> Enum.map(&Poison.encode!/1)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp convert_log({level, _gl, {Logger, message, timestamp, metadata}}, state) do
    {
      %{
        index: %{
          "_index": format_index(state.index_format, timestamp, state.timezone),
          "_type": to_string(state.type)
        }
      },
      %{
        "@timestamp":  format_timestamp(timestamp, state.timezone),
        message: to_string(message),
        level: to_string(level),
        fields: to_fields(metadata, state.metadata)
      }
    }
  end

  defp format_index(index_format, timestamp, timezone) do
    datetime = timestamp_to_datetime(timestamp, timezone)
    case Timex.format(datetime, index_format) do
      {:ok, index} -> index
      {:error, _} -> index_format
    end
  end

  defp format_timestamp(timestamp, timezone) do
    timestamp_to_datetime(timestamp, timezone)
    |> Timex.format!("%FT%T%z", :strftime)
  end

  defp timestamp_to_datetime(timestamp, timezone) do
    {{year, month, day}, {hour, min, sec, ms}} = timestamp
    {:ok, ndt} = NaiveDateTime.new(year, month, day, hour, min, sec, ms * 1000)
    Timex.to_datetime(ndt, timezone)
  end

  defp to_fields(metadata, metadata_filter) do
    metadata
    |> take_metadata(metadata_filter)
    |> Enum.into(%{})
    |> inspect_pids()
  end

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
  end

  defp inspect_pids(fields) do
    Enum.reduce(fields, %{}, &inspect_pid/2)
  end

  defp inspect_pid({key, pid}, acc) when is_pid(pid), do: Map.put(acc, key, inspect(pid))
  defp inspect_pid({key, value}, acc), do: Map.put(acc, key, value)
end
