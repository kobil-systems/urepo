import Config

config :logger,
  level: :info

config :urepo,
  token: "secret",
  private_key: "private.pem",
  store: {Urepo.Store.Local, path: "/tmp/repo"}
