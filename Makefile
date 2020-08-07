# ==================================================
# KOBIL ecosystem
# ==================================================

.PHONY: all init compile clean test lint xref credo dialyzer cover docs

MIX = $(shell which mix)

MIX_ENV ?= "test"

DOC_PATH ?= "doc"

all: lint test

init:
	MIX_ENV=${MIX_ENV} $(MIX) do deps.get

compile: init
	MIX_ENV=${MIX_ENV} $(MIX) compile

clean:
	$(MIX) clean
	@rm -rf _build deps docs public log assets/node_modules

test: compile
	MIX_ENV=${MIX_ENV} $(MIX) test --cover

cover: compile
	MIX_ENV=${MIX_ENV} $(MIX) coveralls.html

doc: compile
	MIX_ENV=dev $(MIX) docs -o ${DOC_PATH}

lint: credo dialyzer

credo: init
	MIX_ENV=dev $(MIX) credo --strict

dialyzer: init
	MIX_ENV=dev $(MIX) dialyzer

# Release.

RELEASE_NAME = urepo

release:
	MIX_ENV=prod $(MIX) distillery.release --name=$(RELEASE_NAME) --env=prod

release_docker: init release

start: release
	_build/prod/rel/${RELEASE_NAME}/bin/${RELEASE_NAME} start

stop:
	_build/prod/rel/${RELEASE_NAME}/bin/${RELEASE_NAME} stop
