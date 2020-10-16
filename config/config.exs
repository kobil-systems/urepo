import Config

config :logger,
  backends: []

config :urepo,
  logger: [
    {:handler, :default, :logger_std_h,
     %{
       filters: [
         remote_gl: {&:logger_filters.remote_gl/2, :stop},
         domain: {&:logger_filters.domain/2, {:stop, :super, [:otp, :sasl]}}
       ],
       formatter:
         {:logger_formatter,
          %{
            template: [:time, ' [', :level, '] ', :msg, '\n']
          }}
     }}
  ]

import_config "#{Mix.env()}.exs"
