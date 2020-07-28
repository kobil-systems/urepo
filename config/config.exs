import Config

config :urepo,
  public_key: "public.pem",
  private_key: "private.pem",
  store: {Urepo.Store.Local, path: "repo"}
