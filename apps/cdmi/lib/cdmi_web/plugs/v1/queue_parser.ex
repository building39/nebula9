defmodule Plug.Parsers.CDMIQ do
  @moduledoc """
  Parses CDMI domain request body.

  An empty request body is parsed as an empty map.
  """

  @behaviour Plug.Parsers
  import Plug.Conn

  require Logger

  def init(opts) do
    opts
  end

  def parse(conn, "application", "cdmi-queue", _headers, opts) do
    Logger.debug("In the CDMIQ parser")
    Logger.debug("opts: #{inspect(opts)}")

    decoder =
      Keyword.get(opts, :json_library) ||
        raise ArgumentError, "JSON parser expects a :json_library option"

    conn
    |> read_body(opts)
    |> decode(decoder)
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end

  defp decode({:more, _, conn}, _decoder) do
    {:error, :too_large, conn}
  end

  defp decode({:error, :timeout}, _decoder) do
    raise Plug.TimeoutError
  end

  defp decode({:error, _}, _decoder) do
    raise Plug.BadRequestError
  end

  defp decode({:ok, "", conn}, _decoder) do
    {:ok, %{}, conn}
  end

  defp decode({:ok, body, conn}, decoder) do
    case decoder.decode!(body) do
      terms when is_map(terms) ->
        {:ok, terms, conn}

      terms ->
        {:ok, %{"_json" => terms}, conn}
    end
  rescue
    e -> raise Plug.Parsers.ParseError, exception: e
  end
end
