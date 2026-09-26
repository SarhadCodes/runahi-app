create table public.surahs (
  number int primary key,
  name_arabic text not null,
  name jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  ayah_count int not null default 0
);

create table public.verses (
  id text primary key,
  surah_number int not null references public.surahs(number) on delete cascade,
  ayah_number int not null,
  arabic text not null,
  translation jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  explanation jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  tafsir jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  source_refs jsonb not null default '[]'::jsonb,
  related_verse_ids text[] not null default '{}',
  word_ids text[] not null default '{}',
  audio_url text,
  updated_at timestamptz not null default now(),
  unique (surah_number, ayah_number)
);

create table public.words (
  id text primary key,
  arabic text not null,
  normalized text not null default '',
  root text not null default '',
  meaning jsonb not null default '{"sorani":"","badini":""}'::jsonb,
  occurrences int not null default 1,
  surahs jsonb not null default '[]'::jsonb,
  example_verse_ids text[] not null default '{}',
  related_word_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create index verses_surah_ayah_idx on public.verses (surah_number, ayah_number);
create index words_arabic_idx on public.words (arabic);

create trigger verses_updated_at before update on public.verses
  for each row execute function public.set_updated_at();
create trigger words_updated_at before update on public.words
  for each row execute function public.set_updated_at();

alter table public.surahs enable row level security;
alter table public.verses enable row level security;
alter table public.words enable row level security;

create policy "Public read surahs" on public.surahs for select using (true);
create policy "Public read verses" on public.verses for select using (true);
create policy "Public read words" on public.words for select using (true);
