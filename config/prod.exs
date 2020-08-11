import Config

config :urepo,
  token: "secret",
  private_key: "private.pem",
  store: {Urepo.Store.Local, path: "/tmp/repo"}
