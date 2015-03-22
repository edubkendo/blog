FROM trenpixster/elixir
MAINTAINER Eric West "esw9999@gmail.com"

ENV REFRESHED_AT 2015-03-21-10-51

RUN apt-get update
RUN apt-get -y install postgresql-client
RUN mkdir -p /opt/app/blog/prod
RUN mkdir -p /opt/app/blog/dev
ADD . /opt/app/blog/prod
WORKDIR /opt/app/blog/prod

ENV MIX_ENV prod
RUN mix deps.get
RUN mix deps.compile

ENV PORT 4000

EXPOSE 4000
CMD [ "/opt/app/blog/prod/setup" ]
