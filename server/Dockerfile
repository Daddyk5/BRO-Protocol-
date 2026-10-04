# Build context: the repo root (see docker-compose.yml), so the shared reply
# logic in functions/src is compiled into the image.

FROM node:22-alpine AS build
WORKDIR /app
COPY server/package.json server/package-lock.json ./
RUN npm ci
COPY server/tsconfig.json ./
COPY server/src ./src
COPY functions/src/errors.ts functions/src/llm.ts functions/src/postprocess.ts functions/src/prompt.ts functions/src/validation.ts ./src/core/
RUN npx tsc && rm -f lib/*.test.js lib/*.test.js.map

FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY server/package.json server/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/lib ./lib
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT:-8080}/healthz" >/dev/null || exit 1
CMD ["node", "lib/server.js"]
