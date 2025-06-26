FROM node:20.19.0-alpine AS deps

WORKDIR /app

COPY package*.json /app

RUN npm ci --legacy-peer-deps


FROM deps AS build

WORKDIR /app

COPY . .

RUN npm run build


FROM node:20.19.0-alpine AS prod

WORKDIR /app

COPY package*.json /app

RUN npm ci --omit-dev --legacy-peer-deps

COPY --from=build /app/dist/angular-conduit/browser /app

EXPOSE 3000

CMD ["npx", "serve"]