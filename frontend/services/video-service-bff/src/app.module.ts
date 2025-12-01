import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { HttpModule } from '@nestjs/axios';
import { Request, Response } from 'express';
import { ConfigModule } from './config/config.module';
import { VideoResolver } from './video/video.resolver';
import { VideoService } from './video/video.service';
import { VideoController } from './video/video.controller';

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
  controllers: [VideoController],
  providers: [VideoResolver, VideoService],
})
export class AppModule {}

