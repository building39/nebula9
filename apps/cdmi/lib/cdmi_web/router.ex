defmodule CdmiWeb.Router do
  use CdmiWeb, :router
  require Logger

  pipeline :cdmi do
    # plug(CdmiWeb.Plugs.V1.Debug)
    plug(:accepts, ["json", "cdmia", "cdmic"])
    plug(CdmiWeb.Plugs.V1.MetadataBackend)
    plug(CdmiWeb.Plugs.V1.CDMIVersion)
    plug(CdmiWeb.Plugs.V1.ResolveDomain)
    # plug(CdmiWeb.Plugs.V1.ApplyCapabilities)
    # plug(CdmiWeb.Plugs.V1.Authentication)
    plug(CdmiWeb.Plugs.V1.Prefetch)
    # plug CdmiWeb.Plugs.V1.ApplyACLs
  end

  scope "/cdmi", CdmiWeb do
    Logger.debug("CDMI scope")
    pipe_through(:cdmi)

    scope "/v1", V1, as: :v1 do
      get("/", CdmiRootContainerController, :show)
      put("/", CdmiRootContainerController, :create)
      # get("/cdmi_objectid/:id", CdmiObjectController, :show)
      resources("/cdmi_objectid", CdmiObjectController, only: [:show])
      # get("/", GetController, :show)
      # get("/*path", GetController, :show)
      # delete("/cdmi_objectid/:id", CdmiObjectController, :delete)
      # delete("/cdmi_domains/*path", DomainController, :delete)
      # delete("/*path", PutController, :delete)
      # put("/container/*path", PutController, :create)
      # put("/cdmi_domains/*path", DomainController, :create)
      # post("/", PostController, :update)
      # post("/*path", PostController, :update)
      # put("/", PutController, :create)
      # put("/*path", PutController, :create)
      # pipe_through(:cdmi)
    end
  end
end
