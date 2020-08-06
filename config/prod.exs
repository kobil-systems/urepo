import Config

config :urepo,
  token: "secret",
  public_key: "public.pem",
  private_key: "private.pem",
  store: {Urepo.Store.S3, bucket: "repo"}

config :ex_aws, :s3,
  access_key_id: "minioadmin",
  secret_access_key: "minioadmin"
