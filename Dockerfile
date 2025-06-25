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

RUN npm install -g serve

COPY --from=build /app/dist/angular-conduit/browser /app

EXPOSE 3000

CMD ["serve"]