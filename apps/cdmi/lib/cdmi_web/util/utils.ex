defmodule CdmiWeb.Util.Utils do
  @moduledoc """
  Various utility functions
  """

  require Logger

  @doc """
  Encrypt.
  """
  @spec encrypt(String.t(), String.t()) :: String.t()
  def encrypt(key, message) do
    :crypto.hmac(:sha, key, message)
    |> Base.encode16()
    |> String.downcase()
  end

  @doc """
  Calculate a hash for a domain.
  """
  @spec get_domain_hash(String.t() | binary) :: String.t()
  def get_domain_hash(domain) when is_binary(domain) do
    Logger.debug("generating hash for #{inspect(domain)}")

    hash =
      :crypto.hmac(:sha, <<"domain">>, domain)
      |> Base.encode16()
      |> String.downcase()

    Logger.debug("hash is #{inspect(hash)}")
    hash
  end

  def get_domain_hash(domain) do
    get_domain_hash(<<domain>>)
  end

  @doc """
  Return a timestamp in the form of "2015-12-25T16:39:1451083144.000000Z"
  """
  @spec make_timestamp() :: String.t()
  def make_timestamp() do
    Logger.debug(fn -> "making a timestamp" end)

    {{year, month, day}, {hour, minute, second}} =
      :calendar.now_to_universal_time(:os.timestamp())

    timestamp =
      List.flatten(
        :io_lib.format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0w.000000Z", [
          year,
          month,
          day,
          hour,
          minute,
          second
        ])
      )
      |> List.to_string()

    Logger.debug(fn -> "made timestamp: #{inspect(timestamp)}" end)
    timestamp
  end
end
