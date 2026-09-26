-- Live TV channels for رووناهى (stream URLs managed in Supabase, not the app).

create table if not exists public.tv_channels (
  id text primary key,
  name_sorani text not null default '',
  name_badini text not null default '',
  stream_url text not null default '',
  sort_order int not null default 0,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists tv_channels_sort_idx
  on public.tv_channels (enabled, sort_order);

alter table public.tv_channels enable row level security;

drop policy if exists tv_channels_public_read on public.tv_channels;
create policy tv_channels_public_read
  on public.tv_channels for select
  to anon, authenticated
  using (enabled = true);

insert into public.tv_channels (id, name_sorani, name_badini, stream_url, sort_order, enabled)
values (
  'ad-tv',
  'AD TV',
  'AD TV',
  'https://lbgo.bozztv.com/ssh101/live/AD_TV/playlist.m3u8',
  0,
  true
)
on conflict (id) do update set
  stream_url = excluded.stream_url,
  name_sorani = excluded.name_sorani,
  name_badini = excluded.name_badini,
  enabled = excluded.enabled,
  updated_at = now();
