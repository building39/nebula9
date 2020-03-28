defmodule Webula.Accounts.Encryption do
  alias Comeonin.Bcrypt
  alias Webula.Accounts.User

  @doc """
  Create an encrypted hash for the account password.
  """
  @spec hash_password(String.t()) :: String.t()
  def hash_password(password) do
    Bcrypt.hashpwsalt(password)
  end

  @doc """
  Validate that the account password is correct.
  """
  @spec validate_password(User.t(), String.t()) :: boolean()
  def validate_password(%User{} = user, password) do
    Bcrypt.check_pass(user, password)
  end
end
