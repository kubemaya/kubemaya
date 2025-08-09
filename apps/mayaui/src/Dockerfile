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
ARG TARGETOS="linux"
ARG TARGETARCH="amd64"
WORKDIR /backend
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o mayaui .
RUN apk update
RUN apk add --no-cache curl
RUN curl -LO https://dl.k8s.io/release/v1.32.3/bin/linux/${TARGETARCH}/kubectl
RUN chmod +x kubectl

## Final image
FROM --platform=${TARGETOS}/${TARGETARCH} alpine:3.19
WORKDIR /app
## Copy Go binary
COPY --from=backend-builder /backend/mayaui .
COPY --from=backend-builder /backend/scripts /app/scripts
COPY --from=backend-builder /backend/kubectl /sbin
## Copy built frontend static files
COPY --from=build-stage /frontend/dist/spa /frontend/dist/spa
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./mayaui"]