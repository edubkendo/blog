FROM trenpixster/elixir
MAINTAINER Eric West "esw9999@gmail.com"

ENV REFRESHED_AT 2015-04-02-12-01-29-am

RUN apt-get update
RUN apt-get -y install postgresql-client
RUN mkdir -p /opt/app/blog/prod
RUN mkdir -p /opt/app/blog/dev
ADD . /opt/app/blog/prod
WORKDIR /opt/app/blog/prod

ENV MIX_ENV prod
RUN mix deps.get
RUN mix deps.compile

ENV PORT 8888

EXPOSE 8888
CMD [ "/opt/app/blog/prod/setup" ]
