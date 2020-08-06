import Config

config :urepo,
  token: "secret",
  public_key: "public.pem",
  private_key: "private.pem",
  store: {Urepo.Store.Local, path: "/tmp/repo"}
