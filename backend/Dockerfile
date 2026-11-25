# Contexto de build: raíz del repositorio. NODE_IMAGE viene de docker/images.env.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9

FROM ${NODE_IMAGE} AS base
ENV TZ=UTC NPM_CONFIG_UPDATE_NOTIFIER=false NPM_CONFIG_FUND=false
WORKDIR /app
# openssl lo requiere el motor de migraciones de Prisma.
RUN apt-get update \
  && apt-get install --yes --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

FROM base AS deps
COPY package.json package-lock.json .npmrc ./
COPY backend/package.json backend/
COPY frontend/package.json frontend/
RUN npm ci --workspace backend --include-workspace-root

FROM deps AS builder
COPY tsconfig.base.json ./
COPY backend backend
# URL ficticia: generate no se conecta, pero prisma.config.ts exige la variable.
RUN DIRECT_URL=postgresql://build@127.0.0.1:5432/build npm run prisma:generate --workspace backend \
  && npm run build --workspace backend \
  && npm prune --omit=dev --workspace backend --include-workspace-root \
  && mkdir -p backend/node_modules

FROM deps AS dev
ENV NODE_ENV=development HEALTH_PORT=4000
COPY --chown=node:node tsconfig.base.json ./
COPY --chown=node:node backend backend
RUN DIRECT_URL=postgresql://build@127.0.0.1:5432/build npm run prisma:generate --workspace backend \
  && npm run build --workspace backend \
  && mkdir -p /var/lib/pe/documents \
  && chown -R node:node /app/backend /var/lib/pe
USER node
CMD ["npm", "run", "dev:api", "--workspace", "backend"]

FROM deps AS migrate
ENV NODE_ENV=production
COPY --chown=node:node backend/prisma.config.ts backend/
COPY --chown=node:node backend/src/prisma backend/src/prisma
USER node
WORKDIR /app/backend
CMD ["npx", "--no-install", "prisma", "migrate", "deploy"]

FROM base AS runner
ENV NODE_ENV=production HEALTH_PORT=4000
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/backend/package.json backend/
COPY --from=builder /app/backend/node_modules backend/node_modules
COPY --from=builder /app/backend/dist backend/dist
RUN mkdir -p /var/lib/pe/documents && chown node:node /var/lib/pe/documents
USER node
WORKDIR /app/backend
EXPOSE 4000 4001
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:'+process.env.HEALTH_PORT+'/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "--enable-source-maps", "dist/bootstrap/server.js"]
