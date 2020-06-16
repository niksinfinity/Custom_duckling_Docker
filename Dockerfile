FROM ubuntu:18.04

RUN apt-get update
RUN apt-get -y upgrade

# Set all environment variables
ENV TZ America/New_York
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install dependencies
RUN apt-get -y install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git libmysqlclient-dev libpcre3-dev

RUN git clone git://github.com/yyuu/pyenv.git .pyenv
RUN git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

RUN mkdir /home/duckling

WORKDIR /home/duckling/

COPY . .

RUN wget -qO- https://get.haskellstack.org/ | sh

RUN stack build

EXPOSE 8080

CMD ["stack", "exec", "duckling-example-exe", "--allow-different-user","--", "-p", "6666"]



