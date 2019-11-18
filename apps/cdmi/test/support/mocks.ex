require Logger
Logger.debug("here i am")
Mox.defmock(CdmiWeb.Util.MockMetadataBackend, for: CdmiWeb.Util.MetadataBackend.Adapter)
