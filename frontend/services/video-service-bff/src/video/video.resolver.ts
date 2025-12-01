import { Resolver, Query, Args, Context, Int } from '@nestjs/graphql';
import { Logger } from '@nestjs/common';
import { VideoService } from './video.service';
import { SearchResponse } from './video.types';
import { Request } from 'express';

@Resolver()
export class VideoResolver {
  private readonly logger = new Logger(VideoResolver.name);

  constructor(private readonly videoService: VideoService) {}

  @Query(() => SearchResponse)
  async search(
    @Args('query', { nullable: true, defaultValue: '' }) query: string,
    @Args('page', { type: () => Int, nullable: true, defaultValue: 1 }) page: number,
    @Args('limit', { type: () => Int, nullable: true, defaultValue: 20 }) limit: number,
    @Args('filter', { nullable: true, defaultValue: 'all' }) filter: string,
    @Context() context: { req: Request },
  ) {
    try {
      this.logger.debug(`Search query: query="${query}", page=${page}, limit=${limit}, filter=${filter}`);
      
      const token = context.req.cookies?.['authToken'] || 
                    context.req.headers.authorization?.replace('Bearer ', '');
      
      return await this.videoService.search(query, page, limit, filter, token || null);
    } catch (error: any) {
      this.logger.error(`Search resolver error: ${error.message}`, error.stack);
      throw error;
    }
  }
}

