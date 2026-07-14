# Java 17 Distroless Docker Image — Zero CVE, Minimal JRE (83 MB)

**A production-ready, zero-CVE Java 17 base image**: a jlink-trimmed Eclipse Temurin 17 JRE on top of a Chainguard Wolfi distroless base. No shell, no package manager, no application code — just the Java runtime, running as a non-root user.

**Trivy scan result: 0 CVEs across all severities (CRITICAL / HIGH / MEDIUM / LOW).**

Rebuilt and pushed **daily** by GitHub Actions, so the image always carries the latest Wolfi and Temurin security patches.

## Why this image?

| | `eclipse-temurin:17-jre` | `gcr.io/distroless/java17-debian12` | **this image** |
|---|---|---|---|
| Base OS | Ubuntu | Debian 12 | Wolfi (Chainguard) |
| Typical Trivy findings | dozens | ~76 (2 CRITICAL)* | **0** |
| Shell / package manager | yes | no | no |
| Size | ~260 MB | ~230 MB | **~83 MB** |
| Runs as non-root | no (root) | optional | yes (default) |

\* measured July 2026; numbers drift as patches land.

**How it gets to zero:** the JRE only needs glibc — libstdc++ is statically linked into HotSpot and zlib is bundled by Temurin. So the runtime sits on `cgr.dev/chainguard/glibc-dynamic`, a glibc-only distroless base that Chainguard patches within days. Even the most minimal Debian base (`cc-debian12`) permanently carries ~17 unfixed glibc/gcc CVEs; Debian-based images can never scan clean.

## Quick start

```bash
docker build -t jre17-distroless .
docker run --rm jre17-distroless -version   # openjdk version "17.x"
```

## Use as a base image for your Java app

```dockerfile
FROM jre17-distroless
COPY app.jar /app/app.jar
CMD ["-jar", "/app/app.jar"]
```

The entrypoint is `java`, so `CMD` takes plain JVM arguments.

## Shrink the JRE to exactly your app's modules

The default module set covers most server applications (no `java.desktop`). To trim further:

```bash
jdeps --print-module-deps --ignore-missing-deps app.jar
docker build --build-arg JAVA_MODULES=<jdeps output> -t jre17-distroless .
```

## Verify the CVE scan yourself

```bash
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW jre17-distroless
```

## How it works

1. **Build stage** (`eclipse-temurin:17-jdk`): `jlink` assembles a minimal JRE from the named modules with `--strip-debug --no-man-pages --no-header-files --compress=2`.
2. **Runtime stage** (`cgr.dev/chainguard/glibc-dynamic`): the JRE is copied to `/opt/java`. The base ships only glibc and CA certificates — no shell, no coreutils, no package manager, non-root by default. Attack surface is the JVM itself.

CI (`.github/workflows/build.yml`) builds on every push and PR, on a daily cron, and on manual dispatch, pushing to the registry from `main`.

## FAQ

**Why not just use `gcr.io/distroless/java17-debian12`?**
It ships graphics/font libraries (expat, glib, harfbuzz, libpng, lcms) for `java.desktop` that a headless server JRE never loads. In July 2026 it scanned at 76 CVEs, 2 CRITICAL. This image drops all of them.

**Why can a Debian-based image never reach zero CVEs?**
Debian marks many low-risk glibc/gcc CVEs as `affected`/`will_not_fix`, so scanners flag them forever regardless of updates. Wolfi rebuilds patched packages continuously, which is why Chainguard-based images scan clean.

**How do I debug a container with no shell?**
`docker debug <container>` (Docker Desktop), or `kubectl debug` with an ephemeral container on Kubernetes. The production image stays shell-free.

**Does it work with Spring Boot / Quarkus / Micronaut?**
Yes — any fat-jar server app. Check required modules with `jdeps` and pass them via `JAVA_MODULES`. Add `java.desktop` workloads (AWT, Swing, image processing) only with a base that provides fontconfig/freetype, e.g. `gcr.io/distroless/java-base-debian12`, accepting its CVEs.

**How do I keep it at zero CVEs over time?**
Rebuild regularly (the daily cron does this). For reproducible builds, pin both `FROM` images by digest (`@sha256:...`) and let Renovate/Dependabot bump the digests. Note the Chainguard free tier only offers the `latest` tag, which makes digest pinning more important.

**Is it really distroless?**
Yes: no shell, no package manager, no coreutils. `docker run --rm --entrypoint /bin/sh jre17-distroless` fails — there is nothing to execute except `java`.

## Keywords

Java 17 distroless Docker image · zero CVE Java base image · minimal JRE container · jlink custom runtime · Chainguard Wolfi Java · secure Java Docker image · Temurin 17 distroless · hardened JRE base image

## License

Apache-2.0 (same as Temurin and Wolfi components it assembles). See upstream: [Eclipse Temurin](https://adoptium.net/), [Chainguard Images](https://images.chainguard.dev/), [Google Distroless](https://github.com/GoogleContainerTools/distroless).
