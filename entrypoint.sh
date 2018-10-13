#!/usr/bin/env sh

set -eu

until PGPASSWORD=${KONG_PG_PASSWORD} psql -h "${KONG_PG_HOST}" -U "kong" -c '\q'; do
    >&2 echo "Waiting for postgres to be ready"
    sleep 5
done

kong migrations up

kong start