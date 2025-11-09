// UUID type - строка в формате UUID
export type UUID = string;

export interface Video {
  id: UUID; // UUID как строка
  title: string;
  description: string;
  user_id: UUID; // UUID как строка
  file_size: number; // int64
  file_url: string;
  thumbnail_url?: string;
  status: string;
  duration: number; // float64
  is_private: boolean;
  created_at: string; // ISO8601 date string
}

export interface Author {
  id: string;
  title?: string;
  name?: string;
  subtitle?: string;
  imageURL?: string;
  avatar_url?: string;
  videoCount?: number;
  followerCount?: number;
}

export type SearchResultItem = 
  | { type: 'video'; data: Video }
  | { type: 'author'; data: Author };

export interface SearchResponse {
  results: SearchResultItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
  };
}

export type SearchFilter = 'all' | 'videos' | 'authors';

// Auth types
export interface User {
  id: UUID; // UUID как строка
  email: string;
  name: string;
  created_at?: string; // ISO8601 date string
}

export interface AuthResponse {
  message: string;
  user: User;
  token: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}

