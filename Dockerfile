FROM phusion/passenger-ruby22

RUN gem install cloudformation-ruby-dsl -v 1.0.4

WORKDIR /app
