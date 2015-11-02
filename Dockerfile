FROM phusion/passenger-ruby22

RUN gem install cloudformation-ruby-dsl -v 0.4.9

WORKDIR /app
