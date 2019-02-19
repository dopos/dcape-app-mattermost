# dcape-app-mattermost Makefile

SHELL               = /bin/bash
CFG                ?= .env

# Database name
DB_NAME            ?= mmost
# Database user name
DB_USER            ?= $(DB_NAME)
# Database user password
DB_PASS            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Database dump for import on create
DB_SOURCE          ?=

# Site host
APP_SITE           ?= chat.dev.lan
# set to frontend entrys list ("http", "https" or both "http,https")
ENTRY_DEFAULT       	    ?= http
# enable redirection, if frontend entry set only to https, set this var to "https"
REDIRECT_ENTRYPOINTS        ?=

# Docker image name
IMAGE              ?= mattermost/mattermost-prod-app
# Docker image tag
IMAGE_VER          ?= 5.6.4
# Docker-compose project name (container name prefix)
PROJECT_NAME       ?= $(shell basename $$PWD)
# dcape container name prefix
DCAPE_PROJECT_NAME ?= dcape
# dcape network attach to
DCAPE_NET          ?= $(DCAPE_PROJECT_NAME)_default
# dcape postgresql container name
DCAPE_DB           ?= $(DCAPE_PROJECT_NAME)_db_1

# Docker-compose image tag
DC_VER             ?= 1.23.2

define CONFIG_DEF
# ------------------------------------------------------------------------------
# Mattermost settings

# Site host
APP_SITE=$(APP_SITE)
# set frontend
ENTRY_DEFAULT=$(ENTRY_DEFAULT)
# enable redirection
REDIRECT_ENTRYPOINTS=$(REDIRECT_ENTRYPOINTS)

# Database name
DB_NAME=$(DB_NAME)
# Database user name
DB_USER=$(DB_USER)
# Database user password
DB_PASS=$(DB_PASS)
# Database dump for import on create
DB_SOURCE=$(DB_SOURCE)

# Docker details

# Docker image name
IMAGE=$(IMAGE)
# Docker image tag
IMAGE_VER=$(IMAGE_VER)

# Used by docker-compose
# Docker-compose project name (container name prefix)
PROJECT_NAME=$(PROJECT_NAME)
# dcape network attach to
DCAPE_NET=$(DCAPE_NET)
# dcape postgresql container name
DCAPE_DB=$(DCAPE_DB)

endef
export CONFIG_DEF

-include $(CFG)
export

.PHONY: all $(CFG) start start-hook stop update up reup down docker-wait db-create db-drop psql dc help

all: help

# ------------------------------------------------------------------------------
# webhook commands

start: db-create up

start-hook: db-create reup

stop: down

update: reup

# ------------------------------------------------------------------------------
# docker commands

## старт контейнеров
up:
up: CMD=up -d
up: dc

## рестарт контейнеров
reup:
reup: CMD=up --force-recreate -d
reup: dc

## остановка и удаление всех контейнеров
down:
down: CMD=rm -f -s
down: dc


# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..."
	@until [[ `docker inspect -f "{{.State.Health.Status}}" $$DCAPE_DB` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

# Database import script
# DCAPE_DB_DUMP_DEST must be set in pg container

define IMPORT_SCRIPT
[[ "$$DCAPE_DB_DUMP_DEST" ]] || { echo "DCAPE_DB_DUMP_DEST not set. Exiting" ; exit 1 ; } ; \
DB_NAME="$$1" ; DB_USER="$$2" ; DB_PASS="$$3" ; DB_SOURCE="$$4" ; \
dbsrc=$$DCAPE_DB_DUMP_DEST/$$DB_SOURCE.tgz ; \
if [ -f $$dbsrc ] ; then \
  echo "Dump file $$dbsrc found, restoring database..." ; \
  zcat $$dbsrc | PGPASSWORD=$$DB_PASS pg_restore -h localhost -U $$DB_USER -O -Ft -d $$DB_NAME || exit 1 ; \
else \
  echo "Dump file $$dbsrc not found" ; \
  exit 2 ; \
fi
endef
export IMPORT_SCRIPT

# create user, db and load dump
db-create: docker-wait
	@echo "*** $@ ***" ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE USER \"$$DB_USER\" WITH PASSWORD '$$DB_PASS';" || true ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE DATABASE \"$$DB_NAME\" OWNER \"$$DB_USER\";" || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] ; then \
	  if [[ "$$DB_SOURCE" ]] ; then \
	    echo "$$IMPORT_SCRIPT" | docker exec -i $$DCAPE_DB bash -s - $$DB_NAME $$DB_USER $$DB_PASS $$DB_SOURCE \
	    && docker exec -i $$DCAPE_DB psql -U postgres -c "COMMENT ON DATABASE \"$$DB_NAME\" IS 'SOURCE $$DB_SOURCE';" \
	    || true ; \
	  fi \
	fi

## drop database and user
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -it $$DCAPE_DB psql -U postgres -c "DROP DATABASE \"$$DB_NAME\";" || true
	@docker exec -it $$DCAPE_DB psql -U postgres -c "DROP USER \"$$DB_USER\";" || true

psql: docker-wait
	@docker exec -it $$DCAPE_DB psql -U $$DB_USER -d $$DB_NAME

# ------------------------------------------------------------------------------

# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@docker run --rm  \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v $$PWD:$$PWD \
	  -w $$PWD \
	  docker/compose:$(DC_VER) \
	  -p $$PROJECT_NAME \
	  $(CMD)

# ------------------------------------------------------------------------------

$(CFG):
	@[ -f $@ ] || { echo "$$CONFIG_DEF" > $@ ; echo "Warning: Created default $@" ; }

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
