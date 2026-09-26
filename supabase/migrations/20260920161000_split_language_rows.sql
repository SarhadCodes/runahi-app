-- Split packed {"sorani":"...","badini":"..."} JSON into two editable rows.

create or replace function public.loc_text(value jsonb, lang text)
returns text
language plpgsql
immutable
as $$
begin
  if value is null then
    return '';
  end if;
  if jsonb_typeof(value) = 'string' then
    return value #>> '{}';
  end if;
  if jsonb_typeof(value) = 'object' then
    return coalesce(nullif(value->>lang, ''), nullif(value->>'sorani', ''), nullif(value->>'badini', ''), '');
  end if;
  return '';
end;
$$;

create or replace function public.loc_text_array(value jsonb, lang text)
returns text[]
language plpgsql
immutable
as $$
begin
  if value is null or jsonb_typeof(value) <> 'array' then
    return '{}'::text[];
  end if;
  return coalesce(
    (
      select array_agg(public.loc_text(elem, lang) order by ordinality)
      from jsonb_array_elements(value) with ordinality as t(elem, ordinality)
    ),
    '{}'::text[]
  );
end;
$$;

create table public.app_config_new (
  id text not null default 'default',
  language text not null check (language in ('sorani', 'badini')),
  whatsapp_number text not null default '',
  whatsapp_prefill text not null default '',
  content_version text not null default '1',
  privacy_url text not null default '',
  terms_url text not null default '',
  support_email text not null default '',
  about_body text not null default '',
  mission_body text not null default '',
  team_body text not null default '',
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.app_config_new (
  id, language, whatsapp_number, whatsapp_prefill, content_version,
  privacy_url, terms_url, support_email, about_body, mission_body, team_body, updated_at
)
select
  id, lang.language, whatsapp_number, public.loc_text(whatsapp_prefill, lang.language),
  content_version, privacy_url, terms_url, support_email,
  public.loc_text(about_body, lang.language),
  public.loc_text(mission_body, lang.language),
  public.loc_text(team_body, lang.language),
  updated_at
from public.app_config
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.daily_content_new (
  id date not null default current_date,
  language text not null check (language in ('sorani', 'badini')),
  verse_id text not null,
  arabic text not null,
  translation text not null default '',
  topic_id text not null default '',
  topic_title text not null default '',
  word_id text not null default '',
  message text not null default '',
  primary key (id, language)
);

insert into public.daily_content_new (
  id, language, verse_id, arabic, translation, topic_id, topic_title, word_id, message
)
select
  id, lang.language, verse_id, arabic,
  public.loc_text(translation, lang.language),
  topic_id,
  public.loc_text(topic_title, lang.language),
  word_id,
  public.loc_text(message, lang.language)
from public.daily_content
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.books_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  title text not null default '',
  author text not null default '',
  category text not null default '',
  description text not null default '',
  cover_color text,
  source_url text,
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.books_new (
  id, language, title, author, category, description, cover_color, source_url, updated_at
)
select
  id, lang.language,
  public.loc_text(title, lang.language),
  public.loc_text(author, lang.language),
  public.loc_text(category, lang.language),
  public.loc_text(description, lang.language),
  cover_color, source_url, updated_at
from public.books
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.book_chapters_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  book_id text not null,
  title text not null default '',
  body text not null default '',
  sort_order int not null default 0,
  primary key (id, language),
  foreign key (book_id, language) references public.books_new(id, language) on delete cascade
);

insert into public.book_chapters_new (id, language, book_id, title, body, sort_order)
select
  id, lang.language, book_id,
  public.loc_text(title, lang.language),
  public.loc_text(body, lang.language),
  sort_order
from public.book_chapters
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.research_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  title text not null default '',
  description text not null default '',
  body text not null default '',
  author text not null default '',
  category text not null default '',
  reading_minutes int not null default 5,
  related_ids text[] not null default '{}',
  date_label text,
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.research_new (
  id, language, title, description, body, author, category,
  reading_minutes, related_ids, date_label, updated_at
)
select
  id, lang.language,
  public.loc_text(title, lang.language),
  public.loc_text(description, lang.language),
  public.loc_text(body, lang.language),
  public.loc_text(author, lang.language),
  public.loc_text(category, lang.language),
  reading_minutes, related_ids,
  nullif(public.loc_text(date_label, lang.language), ''),
  updated_at
from public.research
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.videos_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  title text not null default '',
  description text not null default '',
  category text not null default '',
  duration_label text not null default '',
  thumbnail_url text not null default '',
  video_url text,
  related_ids text[] not null default '{}',
  featured boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.videos_new (
  id, language, title, description, category, duration_label,
  thumbnail_url, video_url, related_ids, featured, updated_at
)
select
  id, lang.language,
  public.loc_text(title, lang.language),
  public.loc_text(description, lang.language),
  public.loc_text(category, lang.language),
  duration_label, thumbnail_url, video_url, related_ids, featured, updated_at
from public.videos
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.questions_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  question text not null default '',
  answer text not null default '',
  category text not null default '',
  related_verse_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.questions_new (
  id, language, question, answer, category, related_verse_ids, related_topic_ids, updated_at
)
select
  id, lang.language,
  public.loc_text(question, lang.language),
  public.loc_text(answer, lang.language),
  public.loc_text(category, lang.language),
  related_verse_ids, related_topic_ids, updated_at
from public.questions
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.topics_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  title text not null default '',
  introduction text not null default '',
  verse_ids text[] not null default '{}',
  video_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.topics_new (
  id, language, title, introduction, verse_ids, video_ids, related_topic_ids, updated_at
)
select
  id, lang.language,
  public.loc_text(title, lang.language),
  public.loc_text(introduction, lang.language),
  verse_ids, video_ids, related_topic_ids, updated_at
from public.topics
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.topic_articles_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  topic_id text not null,
  title text not null default '',
  body text not null default '',
  sort_order int not null default 0,
  primary key (id, language),
  foreign key (topic_id, language) references public.topics_new(id, language) on delete cascade
);

insert into public.topic_articles_new (id, language, topic_id, title, body, sort_order)
select
  id, lang.language, topic_id,
  public.loc_text(title, lang.language),
  public.loc_text(body, lang.language),
  sort_order
from public.topic_articles
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.content_updates_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  kind text not null,
  title text not null default '',
  deep_link text,
  created_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.content_updates_new (id, language, kind, title, deep_link, created_at)
select
  id, lang.language, kind, public.loc_text(title, lang.language), deep_link, created_at
from public.content_updates
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.surahs_new (
  number int not null,
  language text not null check (language in ('sorani', 'badini')),
  name_arabic text not null,
  name text not null default '',
  ayah_count int not null default 0,
  primary key (number, language)
);

insert into public.surahs_new (number, language, name_arabic, name, ayah_count)
select
  number, lang.language, name_arabic, public.loc_text(name, lang.language), ayah_count
from public.surahs
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.verses_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  surah_number int not null,
  ayah_number int not null,
  arabic text not null,
  translation text not null default '',
  explanation text not null default '',
  tafsir text not null default '',
  source_refs text[] not null default '{}',
  related_verse_ids text[] not null default '{}',
  word_ids text[] not null default '{}',
  audio_url text,
  updated_at timestamptz not null default now(),
  primary key (id, language),
  unique (surah_number, ayah_number, language),
  foreign key (surah_number, language) references public.surahs_new(number, language) on delete cascade
);

insert into public.verses_new (
  id, language, surah_number, ayah_number, arabic, translation, explanation,
  tafsir, source_refs, related_verse_ids, word_ids, audio_url, updated_at
)
select
  id, lang.language, surah_number, ayah_number, arabic,
  public.loc_text(translation, lang.language),
  public.loc_text(explanation, lang.language),
  public.loc_text(tafsir, lang.language),
  public.loc_text_array(source_refs, lang.language),
  related_verse_ids, word_ids, audio_url, updated_at
from public.verses
cross join (values ('sorani'), ('badini')) as lang(language);

create table public.words_new (
  id text not null,
  language text not null check (language in ('sorani', 'badini')),
  arabic text not null,
  normalized text not null default '',
  root text not null default '',
  meaning text not null default '',
  occurrences int not null default 1,
  surahs text[] not null default '{}',
  example_verse_ids text[] not null default '{}',
  related_word_ids text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (id, language)
);

insert into public.words_new (
  id, language, arabic, normalized, root, meaning, occurrences,
  surahs, example_verse_ids, related_word_ids, updated_at
)
select
  id, lang.language, arabic, normalized, root,
  public.loc_text(meaning, lang.language),
  occurrences,
  public.loc_text_array(surahs, lang.language),
  example_verse_ids, related_word_ids, updated_at
from public.words
cross join (values ('sorani'), ('badini')) as lang(language);

drop table public.book_chapters cascade;
drop table public.topic_articles cascade;
drop table public.verses cascade;
drop table public.books cascade;
drop table public.topics cascade;
drop table public.surahs cascade;
drop table public.research cascade;
drop table public.videos cascade;
drop table public.questions cascade;
drop table public.words cascade;
drop table public.daily_content cascade;
drop table public.app_config cascade;
drop table public.content_updates cascade;

alter table public.app_config_new rename to app_config;
alter table public.daily_content_new rename to daily_content;
alter table public.books_new rename to books;
alter table public.book_chapters_new rename to book_chapters;
alter table public.research_new rename to research;
alter table public.videos_new rename to videos;
alter table public.questions_new rename to questions;
alter table public.topics_new rename to topics;
alter table public.topic_articles_new rename to topic_articles;
alter table public.content_updates_new rename to content_updates;
alter table public.surahs_new rename to surahs;
alter table public.verses_new rename to verses;
alter table public.words_new rename to words;

create index book_chapters_book_id_idx on public.book_chapters (book_id, language, sort_order);
create index topic_articles_topic_id_idx on public.topic_articles (topic_id, language, sort_order);
create index content_updates_created_at_idx on public.content_updates (created_at desc);
create index verses_surah_ayah_idx on public.verses (surah_number, ayah_number, language);
create index words_arabic_idx on public.words (arabic);
create index verses_language_idx on public.verses (language);
create index books_language_idx on public.books (language);

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
create trigger verses_updated_at before update on public.verses
  for each row execute function public.set_updated_at();
create trigger words_updated_at before update on public.words
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
alter table public.surahs enable row level security;
alter table public.verses enable row level security;
alter table public.words enable row level security;

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
create policy "Public read surahs" on public.surahs for select using (true);
create policy "Public read verses" on public.verses for select using (true);
create policy "Public read words" on public.words for select using (true);

drop function public.loc_text_array(jsonb, text);
drop function public.loc_text(jsonb, text);
