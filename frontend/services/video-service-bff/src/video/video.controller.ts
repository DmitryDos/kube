import { Controller, Get, Query, Param, Req, Res } from '@nestjs/common';
import { Request, Response } from 'express';
import { VideoService } from './video.service';

@Controller('api')
export class VideoController {
  constructor(private readonly videoService: VideoService) {}

  @Get('search')
  async search(
    @Query('q') query: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '20',
    @Query('filter') filter: string = 'all',
    @Req() req: Request,
  ) {
    const token = req.cookies?.['authToken'] || req.headers.authorization?.replace('Bearer ', '');
    return this.videoService.search(query, parseInt(page), parseInt(limit), filter, token || null);
  }

  @Get('videos/:id/stream/proxy')
  async streamVideo(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.videoService.streamVideo(id, req, res);
  }

  @Get('videos/:id/thumbnail')
  async getThumbnail(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.videoService.getThumbnail(id, req, res);
  }
}

