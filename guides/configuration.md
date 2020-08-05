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
  application provides 2 such modules (more information about their usage can be
  found in their module docs):

    + `Urepo.Store.Local`
    + `Urepo.Store.S3`
