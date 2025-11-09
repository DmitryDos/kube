import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private readonly configService: ConfigService) {}

  getApiBaseUrl(): string {
    return this.configService.get<string>('API_GATEWAY_SERVICE')
      ? `http://${this.configService.get<string>('API_GATEWAY_SERVICE')}:80`
      : this.configService.get<string>('NEXT_PUBLIC_API_BASE_URL') ||
          this.configService.get<string>('API_BASE_URL') ||
          'http://localhost:8080';
  }

  getFrontendUrl(): string {
    return this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
  }

  getPort(): number {
    return this.configService.get<number>('PORT') || 3002;
  }
}

