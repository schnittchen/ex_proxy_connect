# ExProxyConnect

Mix task to connect to remote nodes on a server

## Installation

Install from this repo as a mix archive like this:

```sh
git clone https://github.com/schnittchen/ex_proxy_connect
cd ex_proxy_connect
mix archive.build
mix archive.install
```

## Usage

Invoke iex using the mix task as setup like this:

```
iex -S mix proxy_connect remote nodes_erlang_cookie
```

where `remote` is [user@]hostname used by `ssh` to set up the secure tunnel and
`nodes_erlang_cookie` is the cookie commonly used by all nodes registered
with the `epmd` running on the remote host.

This will set up distributed erlang connections to all those nodes and drop
you into an IEx shell. You can now play around with things like `Node.spawn/2` and
`:observer.start/0`.

## Caveats

Port forwardings are set up using the same local ports as the remote nodes _and_
epmd. This means that you cannot have epmd running locally.

## Thanks

@schurig for the inspiration (https://github.com/schurig/elixir-remote-monitor)
and @bitwalker for lots of Elixir tooling
