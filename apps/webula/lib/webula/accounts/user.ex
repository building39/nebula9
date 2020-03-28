defmodule Webula.Accounts.User do

  @type t :: %__MODULE__ {
    id: binary(),
    name: String.t(),
    password_hash: String.t()
    realm: String.t()
  }
  
end
