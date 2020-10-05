import 'reflect-metadata';
import { createConnection } from 'typeorm';
import { buildSchema } from 'type-graphql';
import {
  JWT_PUBLIC_KEY,
  JWT_PRIVATE_KEY,
  API_PORT,
  ENV,
  DOMAIN
} from './config';
import koa from 'koa';
import jwt from 'koa-jwt';
import cors from '@koa/cors';
import path from 'path';
import { graphqlUploadKoa } from 'graphql-upload';
import Redis from 'ioredis';
import apolloServer from './utils/apolloServer';
import authChecker from './utils/authChecker';
import { typeOrmConfig } from './typeorm/typeOrmConfig';

(async () => {
  try {
    const connection = await createConnection(typeOrmConfig);
    const redis = new Redis({ host: 'redis' });

    const server = apolloServer(
      await buildSchema({
        resolvers: [__dirname + '/resolvers/*.resolver.{ts,js}'],
        emitSchemaFile:
          ENV === 'development'
            ? path.resolve(__dirname, '../shared/schema.gql')
            : undefined,
        validate: true,
        authChecker
      })
    );

    const app = new koa();
    app.proxy = true;

    app.use(
      cors({
        origin: ENV === 'production' ? DOMAIN : undefined,
        credentials: true
      })
    );

    app.use(async (ctx, next) => {
      ctx.state = ctx.state || {};
      ctx.redis = redis;
      await next();
    });

    app.use(
      jwt({
        cookie: JWT_PUBLIC_KEY,
        secret: JWT_PRIVATE_KEY,
        passthrough: true
      })
    );

    app.use(
      graphqlUploadKoa({
        maxFileSize: 10000000,
        maxFiles: 20
      })
    );

    const httpServer = app.listen(API_PORT, () =>
      console.log(
        `🚀 Server is running in ${ENV} environment on the port ${API_PORT}.\n` +
          `🚀 Database connection established on port ${process.env.POSTGRES_PORT}.\n` +
          `🚀 GraphQL server at path ${server.graphqlPath}.\n` +
          `🚀 GraphQL subscription server at path ${server.subscriptionsPath}.`
      )
    );

    server.applyMiddleware({ app, path: '/graphql' });
    server.installSubscriptionHandlers(httpServer);

    const cleanup = async () => {
      await connection.close();

      setTimeout(function () {
        console.error('Could not close connections in time, forcing shut down');
        process.exit(1);
      }, 30 * 1000);
    };

    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
  } catch (error) {
    console.error(error);
  }
})();
