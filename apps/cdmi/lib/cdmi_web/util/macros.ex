defmodule CdmiWeb.Util.Macros do
  @moduledoc """
  Various and assorted macros used throughout the application.
  """

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
