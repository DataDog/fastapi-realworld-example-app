FROM python:3.12.6-bookworm

ENV PYTHONUNBUFFERED 1

EXPOSE 8000
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      apt-transport-https \
      build-essential \
      ca-certificates \
      clang-format \
      curl \
      git \
      gnupg \
      jq \
      libbz2-dev \
      libffi-dev \
      liblzma-dev \
      libmemcached-dev \
      libncurses5-dev \
      libncursesw5-dev \
      libpq-dev \
      libreadline-dev \
      libsasl2-dev \
      libsqlite3-dev \
      libsqliteodbc \
      libssh-dev \
      libssl-dev \
      patch \
      unixodbc-dev \
      wget \
      zlib1g-dev \
    # Cleaning up apt cache space
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup Rust compiler
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y

COPY poetry.lock pyproject.toml ./
RUN pip install -U poetry==1.8.3 ddtrace && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-dev

COPY . ./

ENV SECRET_KEY secret
ENV DEBUG true
ENV DD_ENV staging
ENV DD_TRACE_ENABLED true
ENV DD_TRACE_DEBUG true
ENV DD_TRACE_STARTUP_LOGS true
ENV DD_VERSION 0.4
ENV DD_IAST_ENABLED true
ENV DD_APPSEC_ENABLED true
ENV _DD_IAST_DEBUG true


CMD poetry run alembic upgrade head && \
    poetry run ddtrace-run uvicorn --host=0.0.0.0 app.main:app
