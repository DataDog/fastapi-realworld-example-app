# `DD_APPSEC_SCA_ENABLED` — Implementation Across Tracers

**Purpose:** Enables Software Composition Analysis (SCA) — dependency vulnerability detection. It's primarily a **telemetry/backend signal**, not a local behavior toggle (with the notable exception of Python).

---

## Java (`dd-trace-java`)
- **Config key:** `appsec.sca.enabled` in `AppSecConfig.java`
- **Type:** Nullable `Boolean` (default: `null`)
- **Loading:** `Config.java` reads it via `configProvider.getBoolean()` — can be `null`, `true`, or `false`
- **`isAppSecScaEnabled()`** returns `true` only when explicitly set to `true`
- **Sampling impact:** When SCA (or AppSec/IAST) is enabled AND APM is disabled, switches to `AsmStandaloneSampler` → only **1 trace/minute**
- **Dependency collection:** Uses a no-op class file transformer to detect loaded JARs, extracts Maven coordinates (`pom.properties`), SHA-1 hashes, then reports via the telemetry system periodically
- **Warning:** Logs a warning if SCA is enabled but telemetry (`DD_INSTRUMENTATION_TELEMETRY_ENABLED`) or dependency collection (`DD_TELEMETRY_DEPENDENCY_COLLECTION_ENABLED`) is disabled

---

## Python (`dd-trace-py`)
- **Config key:** `_sca_enabled` in `ddtrace/internal/settings/_config.py`
- **Type:** Nullable boolean (default: `None`), parsed by `asbool`
- **Most functional implementation** of all tracers — directly drives "APM opt-out" mode:
  ```python
  @property
  def _apm_opt_out(self) -> bool:
      return (self._asm_enabled or self._iast_enabled or tracer_config._sca_enabled is True) \
             and not self._apm_tracing_enabled
  ```
- When `_apm_opt_out=True`: tracer is disabled, stats computation off, **rate limited to 1 trace/minute**, spans tagged with `_dd.apm.enabled=0.0`
- **Note:** `DD_APPSEC_SCA_ENABLED=true` alone is not enough — also requires APM tracing to be disabled

---

## Go (`dd-trace-go`)
- **Config constant:** `EnvSCAEnabled = "DD_APPSEC_SCA_ENABLED"` in `internal/appsec/config/config.go`
- **Resolution priority:** Managed config file → env var → local config file → default (`false`)
- **Unique behavior:** Suppresses telemetry when the value is the default — telemetry is only sent when explicitly set to `true` or `false`
- **No functional effect:** Value is read, reported to telemetry, then **discarded** — no SCA features are gated on it in the Go tracer
- Listed in `supported_configurations.json` as `"A"`

---

## Node.js (`dd-trace-js`)
- **Config default:** `'appsec.sca.enabled': null` in `packages/dd-trace/src/config/defaults.js`
- **Mapping:** Parsed into `config.appsec.sca.enabled`
- **Explicit comment in source:** *"DD_APPSEC_SCA_ENABLED is never used locally, but only sent to the backend"*
- **Telemetry warning:** If SCA is enabled but telemetry is disabled, logs: `"DD_APPSEC_SCA_ENABLED requires enabling telemetry to work."`
- No local tracer behavior changes

---

## Ruby (`dd-trace-rb`)
- **Config:** `option :sca_enabled` with `o.type :bool, nilable: true` in `lib/datadog/appsec/configuration/settings.rb`
- **Default:** `nil`
- **Access:** `Datadog.configuration.appsec.sca_enabled`
- **Used in two telemetry places:**
  - `app_started` event — reports value at startup
  - `app_client_configuration_change` event — reports on every remote config change (noted in comments as possibly unnecessary)
- No functional SCA logic locally

---

## .NET (`dd-trace-dotnet`)
- **Config key:** `ConfigurationKeys.AppSec.ScaEnabled` (`"DD_APPSEC_SCA_ENABLED"`) in auto-generated `ConfigurationKeys.AppSec.g.cs`
- **Type:** `bool?` (nullable), default `null`
- **Reading:** `SecuritySettings.cs` uses `config.WithKeys(ScaEnabled).AsBool()`
- **Docstring explicitly states:** *"It is not use locally, but ready by the backend"*
- Passed via telemetry to the backend; no local behavioral effect

---

## PHP (`dd-trace-php`)
- **Config macro:** `CONFIG(BOOL, DD_APPSEC_SCA_ENABLED, "false", ...)` in `ext/configuration.h`
- **Notable difference:** Default is **`false`** (not `null` like other tracers)
- **INI name:** `datadog.appsec.sca_enabled` (via `DD_` → `datadog.` prefix + lowercase + dots)
- **Runtime validation:** Warns if SCA is enabled but `DD_INSTRUMENTATION_TELEMETRY_ENABLED` is off
- **Telemetry:** `ext/telemetry.c` sends `appsec.sca_enabled` (strips `datadog.` prefix) with value + origin to the sidecar
- **Immutable at runtime** — uses `zai_config_system_ini_change` handler, so `ini_set()` cannot change it

---

## Summary Table

| Tracer | Default | Type | Local Effect | Primary Use |
|--------|---------|------|-------------|------------|
| **Java** | `null` | `Boolean?` | Yes — switches to `AsmStandaloneSampler` + dependency collection | Telemetry + sampling |
| **Python** | `None` | `bool?` | Yes — drives APM opt-out mode (1 trace/min) | Billing/standalone mode |
| **Go** | `false` | `bool` | None — value is discarded | Telemetry only |
| **Node.js** | `null` | `bool?` | None | Telemetry only |
| **Ruby** | `nil` | `bool?` | None | Telemetry only |
| **.NET** | `null` | `bool?` | None | Telemetry only |
| **PHP** | `false` | `bool` | None | Telemetry only |

**C and Rust** do not implement this variable.

The key pattern across all tracers: the variable's value is read and forwarded to the Datadog backend via telemetry, where the actual SCA scanning/reporting decisions are made. **Java and Python** are the exceptions — they implement meaningful local behavior changes when it's set.
