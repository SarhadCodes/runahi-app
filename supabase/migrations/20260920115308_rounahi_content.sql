-- رووناهى catalog tables. Quran/tafsir stay in the Imani Kurd bundle;
-- these rows are the CMS overlay (config, daily, books, videos, Q&A, topics).

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.app_config (
  id text primary key default 'default',
  whatsapp_number text not null default '',
  whatsapp_prefill jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  content_version text not null default '1',
  privacy_url text not null default '',
  terms_url text not null default '',
  support_email text not null default '',
  about_body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  mission_body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  team_body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.daily_content (
  id date primary key default current_date,
  verse_id text not null,
  arabic text not null,
  translation jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  topic_id text not null default '',
  topic_title jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  word_id text not null default '',
  message jsonb not null default '{"sorani":"","badini":""}'::jsonb
);

create table public.books (
  id text primary key,
  title jsonb not null,
  author jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  category jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  description jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  cover_color text,
  source_url text,
  updated_at timestamptz not null default now()
);

create table public.book_chapters (
  id text primary key,
  book_id text not null references public.books(id) on delete cascade,
  title jsonb not null,
  body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  sort_order int not null default 0
);

create table public.research (
  id text primary key,
  title jsonb not null,
  description jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  author jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  category jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  reading_minutes int not null default 5,
  related_ids text[] not null default '{}',
  date_label jsonb,
  updated_at timestamptz not null default now()
);

create table public.videos (
  id text primary key,
  title jsonb not null,
  description jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  category jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  duration_label text not null default '',
  thumbnail_url text not null default '',
  video_url text,
  related_ids text[] not null default '{}',
  featured boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.questions (
  id text primary key,
  question jsonb not null,
  answer jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  category jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  related_verse_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create table public.topics (
  id text primary key,
  title jsonb not null,
  introduction jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  verse_ids text[] not null default '{}',
  video_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create table public.topic_articles (
  id text primary key,
  topic_id text not null references public.topics(id) on delete cascade,
  title jsonb not null,
  body jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  sort_order int not null default 0
);

create table public.content_updates (
  id text primary key,
  kind text not null,
  title jsonb not null,
  deep_link text,
  created_at timestamptz not null default now()
);

create index book_chapters_book_id_idx on public.book_chapters (book_id, sort_order);
create index topic_articles_topic_id_idx on public.topic_articles (topic_id, sort_order);
create index content_updates_created_at_idx on public.content_updates (created_at desc);

create trigger app_config_updated_at before update on public.app_config
  for each row execute function public.set_updated_at();
create trigger books_updated_at before update on public.books
  for each row execute function public.set_updated_at();
create trigger research_updated_at before update on public.research
  for each row execute function public.set_updated_at();
create trigger videos_updated_at before update on public.videos
  for each row execute function public.set_updated_at();
create trigger questions_updated_at before update on public.questions
  for each row execute function public.set_updated_at();
create trigger topics_updated_at before update on public.topics
  for each row execute function public.set_updated_at();

alter table public.app_config enable row level security;
alter table public.daily_content enable row level security;
alter table public.books enable row level security;
alter table public.book_chapters enable row level security;
alter table public.research enable row level security;
alter table public.videos enable row level security;
alter table public.questions enable row level security;
alter table public.topics enable row level security;
alter table public.topic_articles enable row level security;
alter table public.content_updates enable row level security;

create policy "Public read app_config" on public.app_config for select using (true);
create policy "Public read daily_content" on public.daily_content for select using (true);
create policy "Public read books" on public.books for select using (true);
create policy "Public read book_chapters" on public.book_chapters for select using (true);
create policy "Public read research" on public.research for select using (true);
create policy "Public read videos" on public.videos for select using (true);
create policy "Public read questions" on public.questions for select using (true);
create policy "Public read topics" on public.topics for select using (true);
create policy "Public read topic_articles" on public.topic_articles for select using (true);
create policy "Public read content_updates" on public.content_updates for select using (true);
