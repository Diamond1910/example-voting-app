
# 1. Pin structural base image
FROM node:18-slim@sha256:d3ab14d7a8d9a26388960fa793081e64906f36ebc0c704285e68371192e6a32a

WORKDIR /app

# 2. Handle configuration separately for optimization
COPY package*.json /app/
RUN npm ci --only=production && npm cache clean --force

COPY . /app

# 3. Use built-in non-privileged node user
RUN chown -R node:node /app
USER node

EXPOSE 80

CMD ["node", "server.js"]
