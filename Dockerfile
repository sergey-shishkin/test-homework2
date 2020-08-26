ARG HTTP_PORT=80
ARG MYSQL_HOST=mysql
ARG MYSQL_PORT=3306
# Create temporary container for building the app
FROM node:12-alpine AS builder
WORKDIR /build/

COPY . /build/
RUN npm install && npm run build

# Create finalized container
FROM node:12-alpine

ARG HTTP_PORT
ARG MYSQL_HOST
ARG MYSQL_PORT

WORKDIR /app/
COPY --from=builder /build/dist /app/dist

ENV HTTP_PORT=${HTTP_PORT}
ENV MYSQL_HOST=${MYSQL_HOST}
ENV MYSQL_PORT=${MYSQL_PORT}

EXPOSE ${HTTP_PORT}

CMD ["node", "dist/main.js"]
