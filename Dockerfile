# STAGE 1: Build Flutter Web
FROM debian:stable-slim AS build-env

# Install dependencies (Removed libgconf-2-4)
RUN apt-get update && apt-get install -y \
    curl git wget unzip gdb libstdc++6 libglu1-mesa fonts-droid-fallback python3 \
    && apt-get clean

# Clone the Flutter SDK (Using a stable branch is safer)
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor and enable web
RUN flutter doctor -v
RUN flutter config --enable-web

# Copy project files and build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# STAGE 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]