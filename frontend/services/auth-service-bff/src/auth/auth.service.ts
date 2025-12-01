import { Injectable, UnauthorizedException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { AppConfigService } from '../config/config.service';

@Injectable()
export class AuthService {
  private readonly apiBaseUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: AppConfigService,
  ) {
    this.apiBaseUrl = this.configService.getApiBaseUrl();
  }

  async login(email: string, password: string) {
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.apiBaseUrl}/api/auth/login`, {
          email,
          password,
        }),
      );

      return response.data;
    } catch (error: any) {
      throw new UnauthorizedException(
        error.response?.data?.error || error.response?.data?.message || 'Login failed',
      );
    }
  }

  async register(email: string, password: string, name: string) {
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.apiBaseUrl}/api/auth/register`, {
          email,
          password,
          name,
        }),
      );

      return response.data;
    } catch (error: any) {
      throw new UnauthorizedException(
        error.response?.data?.error || error.response?.data?.message || 'Registration failed',
      );
    }
  }

  async logout(token: string) {
    try {
      await firstValueFrom(
        this.httpService.post(
          `${this.apiBaseUrl}/api/auth/logout`,
          {},
          {
            headers: { Authorization: `Bearer ${token}` },
          },
        ),
      );
    } catch (error) {
      // Игнорируем ошибки при логауте
    }
  }

  async validateToken(token: string) {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.apiBaseUrl}/api/auth/profile`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      );

      return response.data.user;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}

