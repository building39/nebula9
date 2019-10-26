defmodule RiakMetadata.Application do

  use Application
  require Logger

  def start(_type, _args) do
    host = Application.get_env(:riak_metadata, :riak_serverip)
    port = Application.get_env(:riak_metadata, :riak_serverport)
    cdmi_index = Application.get_env(:riak_metadata, :riak_cdmi_index)
    bucket_type = Application.get_env(:riak_metadata, :riak_bucket_type)
    bucket_name = Application.get_env(:riak_metadata, :riak_bucket_name)
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
