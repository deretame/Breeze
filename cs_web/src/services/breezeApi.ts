import {
  createApi,
  fetchBaseQuery,
  type BaseQueryFn,
  type FetchArgs,
  type FetchBaseQueryError,
} from '@reduxjs/toolkit/query/react';

import { clearSession, setSession, type AuthUser } from '../features/auth/authSlice';
import type { RootState } from '../app/store';

export type Health = {
  status: string;
  service: string;
  version: string;
  db_schema_version: number;
  web_frontend: boolean;
  server_download: boolean;
};

export type Capabilities = {
  server_download: boolean;
  browser_frontend: boolean;
  plugin_management: boolean;
  plugin_runtime: {
    quickjs: boolean;
    filesystem: boolean;
    cancellation: boolean;
  };
  authentication: {
    bearer_sessions: boolean;
    registration: boolean;
  };
};

export type Plugin = {
  plugin_id: string;
  name?: string | null;
  version: string;
  bundle_hash: string;
  enabled: boolean;
  updated_at: string;
};

export type PluginCatalogItem = {
  repo: string;
  manifest: {
    name: string;
    uuid: string;
    iconUrl: string;
    describe: string;
    version: string;
    home: string;
    npmName: string;
    updateUrl: string;
    creator: {
      name: string;
      describe: string;
    };
  };
};

export type Session = {
  access_token: string;
  expires_at: string;
  user: AuthUser & { created_at?: string };
};

export type LibraryRecord = {
  unique_key: string;
  source: string;
  comic_id: string;
  payload: Record<string, unknown>;
  updated_at: string;
  deleted_at: string | null;
};

export type SearchResponse = Record<string, unknown>;

export type SearchArgs = {
  pluginId: string;
  keyword: string;
  page: number;
};

export type DetailArgs = {
  pluginId: string;
  comicId: string;
};

export type ReadArgs = {
  pluginId: string;
  comicId: string;
  chapterId: string;
};

export type DownloadTask = {
  task_id: string;
  status: string;
  progress: number;
  payload: Record<string, unknown>;
  error: string | null;
  updated_at: string;
};

const apiBaseUrl =
  typeof window === 'undefined'
    ? '/api/v1'
    : new URL('/api/v1', window.location.origin).toString();

const rawBaseQuery = fetchBaseQuery({
  baseUrl: apiBaseUrl,
  timeout: 15_000,
  prepareHeaders: (headers, { getState }) => {
    const token = (getState() as RootState).auth.token;
    headers.set('accept', 'application/json');
    if (token) {
      headers.set('authorization', `Bearer ${token}`);
    }
    return headers;
  },
});

const baseQuery: BaseQueryFn<string | FetchArgs, unknown, FetchBaseQueryError> = async (
  args,
  api,
  extraOptions,
) => {
  const result = await rawBaseQuery(args, api, extraOptions);
  const publicEndpoints = new Set([
    'health',
    'capabilities',
    'plugins',
    'login',
    'register',
  ]);
  if (
    result.error?.status === 401 &&
    Boolean((api.getState() as RootState).auth.token) &&
    !publicEndpoints.has(api.endpoint)
  ) {
    api.dispatch(clearSession());
  }
  return result;
};

export const breezeApi = createApi({
  reducerPath: 'breezeApi',
  baseQuery,
  tagTypes: ['Health', 'Plugins', 'Library', 'Downloads'],
  refetchOnReconnect: true,
  keepUnusedDataFor: 30,
  endpoints: (builder) => ({
    health: builder.query<Health, void>({
      query: () => '/health',
      providesTags: ['Health'],
    }),
    capabilities: builder.query<Capabilities, void>({
      query: () => '/capabilities',
      providesTags: ['Health'],
    }),
    plugins: builder.query<{ items: Plugin[] }, void>({
      query: () => '/plugins',
      providesTags: ['Plugins'],
    }),
    pluginCatalog: builder.query<{ items: PluginCatalogItem[]; source: string }, void>({
      query: () => '/plugins/catalog',
    }),
    installCatalogPlugin: builder.mutation<Plugin, { pluginId: string }>({
      query: ({ pluginId }) => ({
        url: '/plugins/catalog/install',
        method: 'POST',
        body: { plugin_id: pluginId },
      }),
      invalidatesTags: ['Plugins'],
    }),
    register: builder.mutation<Session, { username: string; password: string }>({
      query: (body) => ({ url: '/auth/register', method: 'POST', body }),
      async onQueryStarted(_args, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled;
          dispatch(setSession({ token: data.access_token, user: data.user }));
        } catch {
          // The form owns the visible error state for a failed request.
        }
      },
    }),
    login: builder.mutation<Session, { username: string; password: string }>({
      query: (body) => ({ url: '/auth/login', method: 'POST', body }),
      async onQueryStarted(_args, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled;
          dispatch(setSession({ token: data.access_token, user: data.user }));
        } catch {
          // The form owns the visible error state for a failed request.
        }
      },
    }),
    logout: builder.mutation<{ logged_out: boolean }, void>({
      query: () => ({ url: '/auth/logout', method: 'POST', body: {} }),
      async onQueryStarted(_args, { dispatch, queryFulfilled }) {
        try {
          await queryFulfilled;
        } finally {
          dispatch(clearSession());
        }
      },
    }),
    search: builder.query<SearchResponse, SearchArgs>({
      query: ({ pluginId, keyword, page }) => ({
        url: `/plugins/${encodeURIComponent(pluginId)}/search`,
        method: 'POST',
        body: { core: { keyword, page }, extern: {} },
      }),
    }),
    detail: builder.query<SearchResponse, DetailArgs>({
      query: ({ pluginId, comicId }) => ({
        url: `/plugins/${encodeURIComponent(pluginId)}/comic/${encodeURIComponent(comicId)}/detail`,
        method: 'POST',
        body: { core: {}, extern: {} },
      }),
    }),
    read: builder.query<SearchResponse, ReadArgs>({
      query: ({ pluginId, comicId, chapterId }) => ({
        url: `/plugins/${encodeURIComponent(pluginId)}/comic/${encodeURIComponent(comicId)}/read`,
        method: 'POST',
        body: { core: { chapterId }, extern: {} },
      }),
    }),
    library: builder.query<{ items: LibraryRecord[] }, string>({
      query: (kind) => `/library/${kind}`,
      providesTags: (_result, _error, kind) => [{ type: 'Library', id: kind }],
    }),
    saveLibrary: builder.mutation<
      LibraryRecord,
      { kind: string; record: Partial<LibraryRecord> }
    >({
      query: ({ kind, record }) => ({
        url: `/library/${kind}`,
        method: 'POST',
        body: record,
      }),
      invalidatesTags: (_result, _error, { kind }) => [{ type: 'Library', id: kind }],
    }),
    downloads: builder.query<{ items: DownloadTask[] }, void>({
      query: () => '/downloads/tasks',
      providesTags: ['Downloads'],
    }),
    createDownload: builder.mutation<
      DownloadTask,
      { plugin_id: string; comic_id: string; chapter_ids: string[] }
    >({
      query: (body) => ({ url: '/downloads/tasks', method: 'POST', body }),
      invalidatesTags: ['Downloads'],
    }),
    cancelDownload: builder.mutation<DownloadTask, string>({
      query: (taskId) => ({
        url: `/downloads/tasks/${encodeURIComponent(taskId)}/cancel`,
        method: 'POST',
        body: {},
      }),
      invalidatesTags: ['Downloads'],
    }),
  }),
});

export const {
  useHealthQuery,
  useCapabilitiesQuery,
  usePluginsQuery,
  usePluginCatalogQuery,
  useInstallCatalogPluginMutation,
  useRegisterMutation,
  useLoginMutation,
  useLogoutMutation,
  useSearchQuery,
  useLazySearchQuery,
  useDetailQuery,
  useReadQuery,
  useLibraryQuery,
  useSaveLibraryMutation,
  useDownloadsQuery,
  useCreateDownloadMutation,
  useCancelDownloadMutation,
} = breezeApi;
