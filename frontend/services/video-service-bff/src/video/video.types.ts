import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Author {
  @Field()
  id!: string;

  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  title?: string;

  @Field({ nullable: true })
  subtitle?: string;

  @Field({ nullable: true })
  avatar_url?: string;

  @Field({ nullable: true })
  imageURL?: string;

  @Field(() => Int, { nullable: true })
  videoCount?: number;

  @Field(() => Int, { nullable: true })
  followerCount?: number;
}

@ObjectType()
export class Video {
  @Field()
  id!: string;

  @Field()
  title!: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  thumbnail_url?: string;

  @Field(() => Int)
  duration!: number;

  @Field()
  user_id!: string;

  @Field({ nullable: true })
  created_at?: string;
}

@ObjectType()
export class SearchResult {
  @Field({ nullable: true })
  type?: string;

  @Field(() => Video, { nullable: true })
  video?: Video;

  @Field(() => Author, { nullable: true })
  author?: Author;
}

@ObjectType()
export class SearchResponse {
  @Field(() => [SearchResult])
  results!: SearchResult[];

  @Field(() => Int, { nullable: true })
  total?: number;

  @Field(() => Int, { nullable: true })
  page?: number;

  @Field(() => Int, { nullable: true })
  limit?: number;
}

