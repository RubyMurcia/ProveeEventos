# Contexto de build: raíz del repositorio. NODE_IMAGE viene de docker/images.env.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9

FROM ${NODE_IMAGE} AS base
ENV TZ=UTC NPM_CONFIG_UPDATE_NOTIFIER=false NPM_CONFIG_FUND=false NEXT_TELEMETRY_DISABLED=1
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json .npmrc ./
COPY backend/package.json backend/
COPY frontend/package.json frontend/
RUN npm ci --workspace frontend --include-workspace-root

FROM deps AS builder
COPY tsconfig.base.json ./
COPY frontend frontend
RUN mkdir -p frontend/public && npm run build --workspace frontend

FROM deps AS dev
ENV NODE_ENV=development
COPY --chown=node:node tsconfig.base.json ./
COPY --chown=node:node frontend frontend
RUN mkdir -p frontend/.next && chown -R node:node /app/frontend
USER node
CMD ["npm", "run", "dev", "--workspace", "frontend", "--", "--hostname", "0.0.0.0", "--port", "3000"]

FROM base AS runner
ENV NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3000
COPY --from=builder /app/frontend/.next/standalone ./
COPY --from=builder /app/frontend/.next/static frontend/.next/static
COPY --from=builder /app/frontend/public frontend/public
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "frontend/server.js"]
