# Configuration options

This application takes only few configuration options:

- `:name` - name of the current repo, need to be the same as on all developers
  machines
- `:token` - authorization token used for communication with API. **Required!**
- `:port` - port on which application listens. Defaults to `8080`.
- `:public_key` and `:private_key` - paths to the public and private parts of
  the RSA 2048-bit key used for signing the repo contents.
- `:store` - 2-ary tuple in form of `{store :: module(), opts :: keyword()}`
  where `store` is module that implements `Urepo.Store` behaviour. This
  application provides 3 such modules (more information about their usage can be
  found in their module docs):

    + `Urepo.Store.Local`
    + `Urepo.Store.S3`
    + `Urepo.Store.GoogleCloudStorage`

Example `sys.config`:

```erlang
[{urepo,[{token,<<"secret">>},
         {public_key,<<"public.pem">>},
         {private_key,<<"private.pem">>},
         {store,{'Elixir.Urepo.Store.S3',[{bucket,<<"repo">>}]}}]},
 {ex_aws,[{s3,[{access_key_id,<<"minioadmin">>},
               {secret_access_key,<<"minioadmin">>}]}]}].
```
