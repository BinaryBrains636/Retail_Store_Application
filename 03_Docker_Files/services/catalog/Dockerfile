# Build Stage
FROM golang:1.23-alpine AS build-env

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o catalog .

# Package Stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

COPY --from=build-env /app/catalog .

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["./catalog"]
