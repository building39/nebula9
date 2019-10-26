defmodule RiakMetadata.Cache do
  use Nebulex.Cache,
    otp_app: :riak_metadata,
    adapter: Nebulex.Adapters.Local
end
