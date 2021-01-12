# HoneyBadgerSwap

## Running a local devnet with docker-compose
To run a tiny local devnet simulation of 4 MPC nodes, with `docker-compose`:

Generate TLS keys, compile MPC programs, and initialize pool data, with secret
shares:

```shell
make mpc-init-pool
```

Docker volumes are used to store the data generated from the above
initialization phase. The public components associated with the TLS keys
are stored in the `public-keys` volume whereas the private key and the secret
shares are stored in `secrets-p<node_id>`, where `node_id` is the id of the
MPC server. Hence, each node has a dedicated volume for its secret data.

To start the ethereum (_private_) node, deploy the contract, deposit
initial funds, and the MPC servers:

```shell
make up
```

This will launch a tmux session, with split panes, to view the different
services running.

Open another pane, tab or window, in which to run the client:

```shell
make run-client
```

Ideally, for the purpose of a simulation, only one command would perhaps
be preferable, but due to timing issues, briefly documented in the next
section, it's currently best to wait a bit before running the client.


### Notes about timing issues
When trying to run everything in one chunk, some problems occur. More testing
needs to be done to clearly identify these problems, but some of them are, or
seem to be:

* **Preprocessing** data is perhaps not ready -- hence it's best to monitor
  the logs of the MPC nodes, to see whether preprocessing (`random-shamir.x`)
  has kicked off.
* **HTTP server** cannot be reached. Sometimes, the client fails to connect
  to one or more HTTP servers. Must make sure that HTTP servers are running,
  and/or the client could have a retry loop.
* Shamir sharing fails. Not sure why. Perhaps some data from previous runs
  has not been deleted.


### Things to improve
* Mount only the data belonging to a node. Example: the db of node 1 should
  not be mounted in the container of node 3.
* When running in separate containers, additional parameters must be passed
  to the Go programs. Use optional flags, with a default value, so that when
  running on localhost, no command line argument needs to be passed.
