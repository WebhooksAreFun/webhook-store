# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 node:16.18.0-alpine as builder
USER node
WORKDIR /tmp/build/app

COPY --chown=node:node package.json ./
COPY --chown=node:node yarn.lock ./
RUN yarn install
COPY --chown=node:node prisma ./prisma/
RUN yarn prisma generate
COPY --chown=node:node tsconfig.json ./
COPY --chown=node:node tsconfig.build.json ./
COPY --chown=node:node src ./src
RUN yarn build

FROM --platform=linux/amd64 node:16.18.0-alpine as ts-node-module-prod
USER node
WORKDIR /usr/src/app

COPY --chown=node:node --from=builder /tmp/build/app/package.json ./
COPY --chown=node:node --from=builder /tmp/build/app/yarn.lock ./
RUN yarn install --frozen-lockfile --production
COPY --chown=node:node --from=builder /tmp/build/app/node_modules/@prisma ./node_modules/@prisma
COPY --chown=node:node --from=builder /tmp/build/app/node_modules/.prisma ./node_modules/.prisma

FROM --platform=linux/amd64 node:16.18.0-alpine
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=builder /tmp/build/app/package.json ./
COPY --chown=node:node --from=ts-node-module-prod /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=builder /tmp/build/app/prisma ./prisma

COPY --chown=node:node --from=builder /tmp/build/app/dist ./

EXPOSE 3000
CMD ["main.js"]