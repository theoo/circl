FROM ruby:2.1.2
LABEL directory.circl.vendor=CIRCL
LABEL directory.circl.name=circl_container

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev libqt4-webkit \
  libqt4-dev xvfb nodejs wget libreoffice pdftk imagemagick logrotate zsh vim openssl build-essential libssl-dev \
  libxrender-dev git-core libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.0/wkhtmltox-linux-amd64_0.12.0-03c001d.tar.xz && \
  tar xvf wkhtmltox-linux-amd64_0.12.0-03c001d.tar.xz && \
  mv wkhtmltox/bin/wkhtmlto* /usr/bin && \
  rm -r wkhtmltox-linux-amd64_0.12.0-03c001d.tar.xz wkhtmltox

# logrotate
RUN echo "*/5 * * * * /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontab && \
  echo "/circl/log/*.log { daily missingok rotate 7 compress delaycompress notifempty copytruncate su }" > /etc/logrotate.conf && \
  chmod 644 /etc/logrotate.conf

ENV APP_HOME /circl
RUN git clone https://github.com/theoo/circl.git $APP_HOME
WORKDIR $APP_HOME

RUN bundle install
RUN cp $APP_HOME/config/configuration.reference.yml $APP_HOME/config/configuration.yml
RUN cp $APP_HOME/config/secrets.example $APP_HOME/config/secrets.yml
RUN mkdir tmp

EXPOSE 80

ENV RACK_ENV production
#RUN rake assets:precompile
ENTRYPOINT foreman start
