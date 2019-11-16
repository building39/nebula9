defmodule CdmiWeb.Util.Utils do
  @moduledoc """
  Various utility functions
  """

  require Logger
  require CdmiWeb.Util.Macros, as: Macros

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
  def get_domain_hash(domain) do
    hash =
      :crypto.hmac(:sha, <<"domain">>, domain)
      |> Base.encode16()
      |> String.downcase()

    hash
  end

  @doc """
  Return a timestamp in the form of "2015-12-25T16:39:1451083144.000000Z"
  """
  @spec make_timestamp() :: String.t()
  def make_timestamp() do
    {{year, month, day}, {hour, minute, second}} =
      case Macros.mix_build_env() do
        "test" ->
          {{2001, 3, 17}, {13, 45, 21}}

        _ ->
          :calendar.now_to_universal_time(:os.timestamp())
      end

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

    timestamp
  end
end
