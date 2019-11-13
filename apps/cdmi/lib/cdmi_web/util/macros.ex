defmodule CdmiWeb.Util.Macros do
  @moduledoc """
  Various and assorted macros used throughout the application.
  """

  # Capture the mix environment at build time
  defmacro mix_build_env() do
    Atom.to_string( Mix.env )
  end

  defmacro fix_container_path(conn) do
    quote do
      if String.ends_with?(unquote(conn).request_path, "/") do
        unquote(conn).request_path
      else
        unquote(conn).request_path <> "/"
      end
    end
  end

end
