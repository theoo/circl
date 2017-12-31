FROM ruby:2.1.2
LABEL directory.circl.vendor=CIRCL
LABEL directory.circl.name=circl_container

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev libqt4-webkit \
  libqt4-dev xvfb nodejs wkhtmltopdf libreoffice pdftk imagemagick logrotate zsh

# logrotate
RUN echo "*/5 * * * * /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontab && \
  echo "/circl/log/*.log { daily missingok rotate 7 compress delaycompress notifempty copytruncate su }" > /etc/logrotate.conf && \
  chmod 644 /etc/logrotate.conf

ENV APP_HOME /circl
RUN git clone https://github.com/theoo/circl.git $APP_HOME
WORKDIR $APP_HOME

RUN bundle install
RUN cp $APP_HOME/config/configuration.reference.yml $APP_HOME/config/configuration.yml

EXPOSE 80

ENTRYPOINT foreman start
