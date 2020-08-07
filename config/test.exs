import Config

config :logger, level: :warning

config :urepo,
  public_key: "test/fixtures/public.pem",
  private_key: "test/fixtures/private.pem"
