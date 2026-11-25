# Dobles locales de Auth0, SendGrid (webhook) y Cloudinary. Sin dependencias: Node ejecuta TypeScript directamente.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9
FROM ${NODE_IMAGE} AS runner
ENV NODE_ENV=development TZ=UTC
WORKDIR /app
COPY --chown=node:node Tools/dev-stubs/ ./
USER node
EXPOSE 4010
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:4010/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "server.ts"]
