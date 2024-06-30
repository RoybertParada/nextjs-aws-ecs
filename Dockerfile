FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
ARG ENVIRONMENT_NAME
ENV ENVIRONMENT_NAME=$ENVIRONMENT_NAME
RUN npm install

COPY . .

RUN npm run build

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

CMD ["npm", "start"]
