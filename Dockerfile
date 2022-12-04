FROM golang:1.17-alpine as builder
WORKDIR $GOPATH/src/go.k6.io/k6
ADD . .
RUN apk --no-cache add git
RUN go install go.k6.io/xk6/cmd/xk6@latest
RUN xk6 build --with github.com/mstoykov/xk6-counter --output /tmp/k6
RUN xk6 build --with github.com/grafana/xk6-browser --output xk6-browser

FROM alpine:3.14
RUN apk add --no-cache ca-certificates && \
    adduser -D -u 12345 -g 12345 k6

WORKDIR /home/k6
COPY ./counter.js /home/k6
COPY --from=builder /tmp/k6 /usr/bin/k6

USER 12345
ENTRYPOINT ["k6"]

FROM cimg/php:8.1
RUN sudo add-apt-repository ppa:ondrej/php -y && \
  sudo apt-get update && \
  sudo apt-get install default-mysql-client zlib1g-dev libpng-dev libfreetype6-dev && \
  sudo apt-get install libapache2-mod-php8.1 php-mysql apache2 && \
  sudo pecl install xdebug &&\
  \
  # Install NodeJS, enable Corepack
  curl -sL https://deb.nodesource.com/setup_17.x | sudo -E bash - && \
  sudo apt-get install nodejs build-essential && \
  sudo corepack enable && \
  # Install WP-CLI
  sudo curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
  sudo chmod +x /usr/local/bin/wp && \
  \
  # Clean up
  sudo apt-get clean && \
  sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \