# Manymon

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).


# Running in Docker

```
echo SECRET_KEY_BASE=$(head /dev/urandom | md5sum | head -c 32) > secret.env
docker compose up -d
docker compose exec manymon bin/migrate
curl localhost:4000/metrics
```
