# Build frontend (Vue.js/Quasar) first
FROM node:22.18.0-alpine3.21 AS frontend-builder
WORKDIR /frontend
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn global add @quasar/cli
COPY frontend/ ./

FROM frontend-builder AS build-stage
RUN yarn
RUN quasar build

## Build backend (Go)
FROM golang:1.24-alpine AS backend-builder
WORKDIR /backend
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN go build -o mayaui .

## Final image
FROM alpine:3.19
WORKDIR /app
## Copy Go binary
COPY --from=backend-builder /backend/mayaui .
COPY --from=backend-builder /backend/scripts /app/scripts
## Copy built frontend static files
COPY --from=build-stage /frontend/dist/spa /frontend/dist/spa
RUN apk update
RUN apk add kubectl
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./mayaui"]