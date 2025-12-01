import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { HttpModule } from '@nestjs/axios';
import { Request, Response } from 'express';
import { ConfigModule } from './config/config.module';
import { AuthResolver } from './auth/auth.resolver';
import { AuthService } from './auth/auth.service';

@Module({
  imports: [
    ConfigModule,
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: true,
      context: ({ req, res }: { req: Request; res: Response }) => ({ req, res }),
    }),
    HttpModule.register({
      timeout: 30000,
    }),
  ],
  providers: [AuthResolver, AuthService],
})
export class AppModule {}

