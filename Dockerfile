# ---------- Etapa 1: compilar la app Flutter Web ----------
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

# URLs de las APIs (Render pasa las variables de entorno como build args)
ARG API_WEB_URL=http://127.0.0.1:8000/api
ARG API_LOCAL_URL=http://127.0.0.1:8081/api
ARG API_LOCAL_KEY=

WORKDIR /app

# Dependencias primero para aprovechar la caché de capas
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release \
      --dart-define=API_WEB_URL=${API_WEB_URL} \
      --dart-define=API_LOCAL_URL=${API_LOCAL_URL} \
      --dart-define=API_LOCAL_KEY=${API_LOCAL_KEY}

# ---------- Etapa 2: servir con nginx ----------
FROM nginx:1.27-alpine

# Render asigna el puerto en $PORT (por defecto 10000)
ENV PORT=10000

# La imagen oficial de nginx procesa /etc/nginx/templates/*.template con envsubst
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 10000
