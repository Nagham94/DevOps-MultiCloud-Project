# stage 1: build
# base image, alpine it is a small image
FROM node:22-alpine AS build
# working directory in the container
WORKDIR /app
# copy package.json and package-lock.json to the working directory
COPY website/package*.json ./
# install dependencies
# ci stands for clean install, it will remove the node_modules folder and install fresh dependencies
# faster than npm install and it will only install production dependencies as we use --only=production flag
RUN npm ci --only=production

# stage 2: production
# base image, alpine it is a small image
FROM node:22-alpine AS production
# create a non root user to run the application for security
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs
# working directory in the container
WORKDIR /app
# copy only the necessary files from the build stage to the production stage
COPY --from=build /app/node_modules ./node_modules
# copy the rest of the application files to the working directory
# set the ownership to the non root user to be able to read and execute the files
COPY --chown=nodejs:nodejs website/ ./
# switch to the non root user
USER nodejs
# expose the port that the application will run on
EXPOSE 3000
# command to run the application
CMD ["npm", "start"]