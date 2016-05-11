defmodule Bugsnag do
  use Application

  alias Bugsnag.Payload

  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start(_, _), do: start()

  def start do
    config = Keyword.merge default_config, Application.get_all_env(:bugsnag)

    if config[:use_logger] do
      :error_logger.add_report_handler(Bugsnag.Logger)
    end

    update_app_config(config)
  end

  def report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace

    spawn fn ->
      Payload.new(exception, stacktrace, options)
        |> to_json
        |> send_notification
    end
  end

  def to_json(payload) do
    payload |> Poison.encode!
  end

  defp send_notification(body) do
    HTTPoison.post @notify_url, body, @request_headers
  end

  defp default_config do
    [
      api_key: System.get_env("BUGSNAG_API_KEY") || "FAKEKEY",
      use_logger: true,
      release_stage: to_string(Mix.env) || "dev"
    ]
  end

  defp update_app_config(normalized_config) do
    Enum.each normalized_config, fn {key, value} ->
      Application.put_env :bugsnag, key, value
    end
  end
end
