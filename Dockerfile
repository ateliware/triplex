# https://hub.docker.com/_/elixir/
FROM elixir:1.4.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y postgresql-client

ADD . /app
RUN mix local.hex --force
RUN mix local.rebar --force
WORKDIR /app
RUN mix do deps.get, compile

