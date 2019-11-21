defmodule RiakMetadata.Application do
  @moduledoc """
    The RiakMetadata application provides an interface for manipulating CDMI
    metadata in a `riak` cluster.

    Configuration is done in config.exs, naturally. Configurable items are:
        :riak_bucket_type Default: `<<"cdmi">>`
        :riak_bucket_name Default: `<<"cdmi">>`
        :riak_cdmi_index: Default: `<<"cdmi_idx">>`
        :riak_serverip Default: "127.0.0.1"
        :riak_serverport Default: 8087
  """

  use Application
  require Logger

  def start(_type, _args) do
    host = Application.get_env(:riak_metadata, :riak_serverip, "127.0.0.1")
    port = Application.get_env(:riak_metadata, :riak_serverport, 8087)
    cdmi_index = Application.get_env(:riak_metadata, :riak_cdmi_index, <<"cdmi_idx">>)
    bucket_type = Application.get_env(:riak_metadata, :riak_bucket_type, <<"cdmi">>)
    bucket_name = Application.get_env(:riak_metadata, :riak_bucket_name, <<"cdmi">>)
    bucket = {bucket_type, bucket_name}

    Logger.info("Starting the RIAK metadata backend")
    Logger.info("RIAK server host: #{inspect(host)}")
    Logger.info("RIAK server port: #{inspect(port)}")
    Logger.info("RIAK index: #{inspect(cdmi_index)}")
    Logger.info("RIAK bucket: #{inspect(bucket)}")

    state = %RiakMetadata.State{
      host: host,
      port: port,
      bucket_type: bucket_type,
      bucket_name: bucket_name,
      bucket: bucket,
      cdmi_index: cdmi_index
    }

    children = [
      RiakMetadata.Cache,
      %{
        id: RiakMetadata.Server,
        start: {RiakMetadata.Server, :start_link, [state]}
      }
    ]

    opts = [strategy: :one_for_one, name: RiakMetadata.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
