import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { Request, Response } from 'express';
import { AppConfigService } from '../config/config.service';

@Injectable()
export class VideoService {
  private readonly logger = new Logger(VideoService.name);
  private readonly apiBaseUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: AppConfigService,
  ) {
    this.apiBaseUrl = this.configService.getApiBaseUrl();
    this.logger.log(`VideoService initialized with API_BASE_URL: ${this.apiBaseUrl}`);
  }

  async search(query: string, page: number, limit: number, filter: string, token: string | null) {
    try {
      const params = new URLSearchParams({
        q: query || '',
        page: page.toString(),
        limit: limit.toString(),
        filter,
      });

      const url = `${this.apiBaseUrl}/api/search?${params.toString()}`;
      this.logger.debug(`Search request: ${url}`);

      const headers: any = {};
      if (token) {
        headers.Authorization = `Bearer ${token}`;
      }

      const response = await firstValueFrom(
        this.httpService.get(url, {
          headers,
        }),
      );

      // Log raw response for debugging
      this.logger.debug(`API Gateway response status: ${response.status}`);
      this.logger.debug(`API Gateway response data: ${JSON.stringify(response.data, null, 2)}`);

      // API Gateway returns: { results: [{ type: "video", data: {...} }], pagination: {...} }
      // GraphQL expects: { results: [{ type: "video", video: {...}, author: null }], total, page, limit }
      const data = response.data || {};
      const apiResults = data.results || [];
      const pagination = data.pagination || {};
      
      const results = apiResults.map((item: any) => {
        const type = item.type || 'unknown';
        const itemData = item.data || {};
        
        if (type === 'video') {
          return {
            type: 'video',
            video: itemData,
            author: null,
          };
        } else if (type === 'author') {
          // API Gateway returns author with 'title' field, but GraphQL expects 'name'
          // Map the fields correctly
          const author = {
            id: itemData.id || '',
            name: itemData.name || itemData.title || '',
            title: itemData.title,
            subtitle: itemData.subtitle,
            avatar_url: itemData.avatar_url || itemData.imageURL,
            imageURL: itemData.imageURL,
            videoCount: itemData.videoCount,
            followerCount: itemData.followerCount,
          };
          return {
            type: 'author',
            video: null,
            author,
          };
        } else {
          return {
            type: 'unknown',
            video: null,
            author: null,
          };
        }
      });
      
      this.logger.debug(`Processed results count: ${results.length}`);
      
      return {
        results,
        total: pagination.total ?? data.total ?? 0,
        page: pagination.page ?? data.page ?? 1,
        limit: pagination.limit ?? data.limit ?? 20,
      };
    } catch (error: any) {
      this.logger.error(`Search error: ${error.message}`, error.stack);
      
      if (error.response) {
        // HTTP error response
        const status = error.response.status;
        const data = error.response.data;
        this.logger.error(`API Gateway error: ${status} - ${JSON.stringify(data)}`);
        throw new Error(`Search failed: ${status} - ${data?.message || data?.error || 'Unknown error'}`);
      } else if (error.request) {
        // Request was made but no response received
        this.logger.error(`No response from API Gateway: ${error.message}`);
                throw new Error(`Cannot connect to API Gateway at ${this.apiBaseUrl}. Check if the service is running.`);
      } else {
        // Error setting up the request
        this.logger.error(`Request setup error: ${error.message}`);
        throw new Error(`Search request failed: ${error.message}`);
      }
    }
  }

  async streamVideo(id: string, req: Request, res: Response) {
    const range = req.headers.range;
    const headers: any = {};

    const token = req.cookies?.['authToken'] || req.headers.authorization?.replace('Bearer ', '');
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    if (range) {
      headers.Range = range;
    }

    const response = await firstValueFrom(
      this.httpService.get(`${this.apiBaseUrl}/api/videos/${id}/stream/proxy`, {
        headers,
        responseType: 'stream',
      }),
    );

    res.setHeader('Content-Type', response.headers['content-type']);
    res.setHeader('Content-Length', response.headers['content-length']);
    res.setHeader('Accept-Ranges', response.headers['accept-ranges'] || 'bytes');

    if (range) {
      res.status(206);
    } else {
      res.status(200);
    }

    response.data.pipe(res);
  }

  async getThumbnail(id: string, req: Request, res: Response) {
    const headers: any = {};

    const token = req.cookies?.['authToken'] || req.headers.authorization?.replace('Bearer ', '');
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    const response = await firstValueFrom(
      this.httpService.get(`${this.apiBaseUrl}/api/videos/${id}/thumbnail`, {
        headers,
        responseType: 'arraybuffer',
      }),
    );

    res.setHeader('Content-Type', response.headers['content-type'] || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.send(Buffer.from(response.data));
  }
}

