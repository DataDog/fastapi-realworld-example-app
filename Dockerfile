FROM python:3.14-bookworm

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

# Install uv - fast Python package manager
ENV PATH="/root/.local/bin:$PATH"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies using uv (production only, no dev dependencies)
# --frozen: use exact versions from uv.lock without updating
# --no-group dev: skip dev dependency group
RUN uv sync --frozen --no-group dev && \
    uv pip install ddtrace

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


CMD uv run alembic upgrade head && \
    uv run ddtrace-run uvicorn --host=0.0.0.0 app.main:app
