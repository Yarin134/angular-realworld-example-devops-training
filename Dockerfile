#deps stage
FROM node:20.19.0-alpine AS deps
WORKDIR /app
COPY package*.json /app
RUN npm ci --legacy-peer-deps

#build stage
FROM deps AS build
WORKDIR /app
COPY . .
RUN npm run build

#prod stage
FROM node:20.19.0-alpine AS prod
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/dist/angular-conduit/browser /app
EXPOSE 3000
CMD ["serve"]





# deps, build, prod

# FROM node:20.19.0-alpine

# WORKDIR /app

# COPY package.json ./

# RUN npm install -g @angular/cli

# RUN npm install --legacy-peer-deps

# COPY . .

# EXPOSE 4200

# CMD ["ng", "serve", "--host", "0.0.0.0"]