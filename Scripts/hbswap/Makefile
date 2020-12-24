.PHONY: help

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef

export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-mpc-progs clean-player-data
	docker-compose run --rm eth.chain rm -rf poa/data

clean-mpc-progs:
	docker-compose -f hbswap-init.yml run --rm mpc.compile rm -rf Programs/Bytecode Programs/Schedules Programs/Public-Input

clean-player-data:
	# FIXME does not work
	docker-compose -f hbswap-init.yml run --rm mpc.trusted.setup rm -rf Player-Data/*

down: down-init
	docker-compose down

stop:
	docker-compose stop eth.chain mpc.nodes

rm: clean
	docker-compose rm --stop --force eth.chain contract.deploy contract.deposit mpc.nodes

up: down rm down-init rm-init up-init ## run the example
	docker-compose up --remove-orphans -d eth.chain
	docker-compose up --remove-orphans contract.deploy
	docker-compose up --remove-orphans contract.deposit
	docker-compose up --remove-orphans -d mpc.nodes
	sh scripts/follow-sim-logs-with-tmux.sh

down-init:
	docker-compose -f hbswap-init.yml down

rm-init: clean
	#docker-compose -f hbswap-init.yml rm --stop --force mpc.trusted.setup mpc.compile mpc.node.0 mpc.node.1 mpc.node.2 mpc.node.3
	docker-compose -f hbswap-init.yml rm --stop --force mpc.trusted.setup mpc.compile mpc.allnodes

up-init: down-init rm-init
	docker-compose -f hbswap-init.yml up --remove-orphans mpc.trusted.setup mpc.compile
	#docker-compose -f hbswap-init.yml up mpc.node.0 mpc.node.1 mpc.node.2 mpc.node.3
	docker-compose -f hbswap-init.yml up --remove-orphans mpc.allnodes
