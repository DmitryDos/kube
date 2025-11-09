export type SearchParams<T = {}> = Promise<Partial<Record<string, string | string[]>> & T>;

export type AwaitedSearchParams<T = {}> = Partial<Record<string, string | string[]>> & T>;

export type PageParams<T = {}> = Promise<T>;
