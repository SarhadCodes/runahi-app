-- One row per item, with separate Sorani and Badini text columns.

create table public.app_config_new (
  id text primary key default 'default',
  whatsapp_number text not null default '',
  whatsapp_prefill_sorani text not null default '',
  whatsapp_prefill_badini text not null default '',
  content_version text not null default '1',
  privacy_url text not null default '',
  terms_url text not null default '',
  support_email text not null default '',
  about_body_sorani text not null default '',
  about_body_badini text not null default '',
  mission_body_sorani text not null default '',
  mission_body_badini text not null default '',
  team_body_sorani text not null default '',
  team_body_badini text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.app_config_new
select
  coalesce(s.id, b.id),
  coalesce(s.whatsapp_number, b.whatsapp_number, ''),
  coalesce(s.whatsapp_prefill, ''),
  coalesce(b.whatsapp_prefill, s.whatsapp_prefill, ''),
  coalesce(s.content_version, b.content_version, '1'),
  coalesce(s.privacy_url, b.privacy_url, ''),
  coalesce(s.terms_url, b.terms_url, ''),
  coalesce(s.support_email, b.support_email, ''),
  coalesce(s.about_body, ''),
  coalesce(b.about_body, s.about_body, ''),
  coalesce(s.mission_body, ''),
  coalesce(b.mission_body, s.mission_body, ''),
  coalesce(s.team_body, ''),
  coalesce(b.team_body, s.team_body, ''),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.app_config where language = 'sorani') s
full join (select * from public.app_config where language = 'badini') b on s.id = b.id;

create table public.daily_content_new (
  id date primary key default current_date,
  verse_id text not null,
  arabic text not null,
  translation_sorani text not null default '',
  translation_badini text not null default '',
  topic_id text not null default '',
  topic_title_sorani text not null default '',
  topic_title_badini text not null default '',
  word_id text not null default '',
  message_sorani text not null default '',
  message_badini text not null default ''
);

insert into public.daily_content_new
select
  coalesce(s.id, b.id),
  coalesce(s.verse_id, b.verse_id, ''),
  coalesce(s.arabic, b.arabic, ''),
  coalesce(s.translation, ''),
  coalesce(b.translation, s.translation, ''),
  coalesce(s.topic_id, b.topic_id, ''),
  coalesce(s.topic_title, ''),
  coalesce(b.topic_title, s.topic_title, ''),
  coalesce(s.word_id, b.word_id, ''),
  coalesce(s.message, ''),
  coalesce(b.message, s.message, '')
from (select * from public.daily_content where language = 'sorani') s
full join (select * from public.daily_content where language = 'badini') b on s.id = b.id;

create table public.books_new (
  id text primary key,
  title_sorani text not null default '',
  title_badini text not null default '',
  author_sorani text not null default '',
  author_badini text not null default '',
  category_sorani text not null default '',
  category_badini text not null default '',
  description_sorani text not null default '',
  description_badini text not null default '',
  cover_color text,
  source_url text,
  updated_at timestamptz not null default now()
);

insert into public.books_new
select
  coalesce(s.id, b.id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.author, ''),
  coalesce(b.author, s.author, ''),
  coalesce(s.category, ''),
  coalesce(b.category, s.category, ''),
  coalesce(s.description, ''),
  coalesce(b.description, s.description, ''),
  coalesce(s.cover_color, b.cover_color),
  coalesce(s.source_url, b.source_url),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.books where language = 'sorani') s
full join (select * from public.books where language = 'badini') b on s.id = b.id;

create table public.book_chapters_new (
  id text primary key,
  book_id text not null references public.books_new(id) on delete cascade,
  title_sorani text not null default '',
  title_badini text not null default '',
  body_sorani text not null default '',
  body_badini text not null default '',
  sort_order int not null default 0
);

insert into public.book_chapters_new
select
  coalesce(s.id, b.id),
  coalesce(s.book_id, b.book_id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.body, ''),
  coalesce(b.body, s.body, ''),
  coalesce(s.sort_order, b.sort_order, 0)
from (select * from public.book_chapters where language = 'sorani') s
full join (select * from public.book_chapters where language = 'badini') b on s.id = b.id;

create table public.research_new (
  id text primary key,
  title_sorani text not null default '',
  title_badini text not null default '',
  description_sorani text not null default '',
  description_badini text not null default '',
  body_sorani text not null default '',
  body_badini text not null default '',
  author_sorani text not null default '',
  author_badini text not null default '',
  category_sorani text not null default '',
  category_badini text not null default '',
  reading_minutes int not null default 5,
  related_ids text[] not null default '{}',
  date_label_sorani text,
  date_label_badini text,
  updated_at timestamptz not null default now()
);

insert into public.research_new
select
  coalesce(s.id, b.id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.description, ''),
  coalesce(b.description, s.description, ''),
  coalesce(s.body, ''),
  coalesce(b.body, s.body, ''),
  coalesce(s.author, ''),
  coalesce(b.author, s.author, ''),
  coalesce(s.category, ''),
  coalesce(b.category, s.category, ''),
  coalesce(s.reading_minutes, b.reading_minutes, 5),
  coalesce(s.related_ids, b.related_ids, '{}'::text[]),
  nullif(coalesce(s.date_label, ''), ''),
  nullif(coalesce(b.date_label, s.date_label, ''), ''),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.research where language = 'sorani') s
full join (select * from public.research where language = 'badini') b on s.id = b.id;

create table public.videos_new (
  id text primary key,
  title_sorani text not null default '',
  title_badini text not null default '',
  description_sorani text not null default '',
  description_badini text not null default '',
  category_sorani text not null default '',
  category_badini text not null default '',
  duration_label text not null default '',
  thumbnail_url text not null default '',
  video_url text,
  related_ids text[] not null default '{}',
  featured boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into public.videos_new
select
  coalesce(s.id, b.id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.description, ''),
  coalesce(b.description, s.description, ''),
  coalesce(s.category, ''),
  coalesce(b.category, s.category, ''),
  coalesce(s.duration_label, b.duration_label, ''),
  coalesce(s.thumbnail_url, b.thumbnail_url, ''),
  coalesce(s.video_url, b.video_url),
  coalesce(s.related_ids, b.related_ids, '{}'::text[]),
  coalesce(s.featured, b.featured, false),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.videos where language = 'sorani') s
full join (select * from public.videos where language = 'badini') b on s.id = b.id;

create table public.questions_new (
  id text primary key,
  question_sorani text not null default '',
  question_badini text not null default '',
  answer_sorani text not null default '',
  answer_badini text not null default '',
  category_sorani text not null default '',
  category_badini text not null default '',
  related_verse_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

insert into public.questions_new
select
  coalesce(s.id, b.id),
  coalesce(s.question, ''),
  coalesce(b.question, s.question, ''),
  coalesce(s.answer, ''),
  coalesce(b.answer, s.answer, ''),
  coalesce(s.category, ''),
  coalesce(b.category, s.category, ''),
  coalesce(s.related_verse_ids, b.related_verse_ids, '{}'::text[]),
  coalesce(s.related_topic_ids, b.related_topic_ids, '{}'::text[]),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.questions where language = 'sorani') s
full join (select * from public.questions where language = 'badini') b on s.id = b.id;

create table public.topics_new (
  id text primary key,
  title_sorani text not null default '',
  title_badini text not null default '',
  introduction_sorani text not null default '',
  introduction_badini text not null default '',
  verse_ids text[] not null default '{}',
  video_ids text[] not null default '{}',
  related_topic_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

insert into public.topics_new
select
  coalesce(s.id, b.id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.introduction, ''),
  coalesce(b.introduction, s.introduction, ''),
  coalesce(s.verse_ids, b.verse_ids, '{}'::text[]),
  coalesce(s.video_ids, b.video_ids, '{}'::text[]),
  coalesce(s.related_topic_ids, b.related_topic_ids, '{}'::text[]),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.topics where language = 'sorani') s
full join (select * from public.topics where language = 'badini') b on s.id = b.id;

create table public.topic_articles_new (
  id text primary key,
  topic_id text not null references public.topics_new(id) on delete cascade,
  title_sorani text not null default '',
  title_badini text not null default '',
  body_sorani text not null default '',
  body_badini text not null default '',
  sort_order int not null default 0
);

insert into public.topic_articles_new
select
  coalesce(s.id, b.id),
  coalesce(s.topic_id, b.topic_id),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.body, ''),
  coalesce(b.body, s.body, ''),
  coalesce(s.sort_order, b.sort_order, 0)
from (select * from public.topic_articles where language = 'sorani') s
full join (select * from public.topic_articles where language = 'badini') b on s.id = b.id;

create table public.content_updates_new (
  id text primary key,
  kind text not null,
  title_sorani text not null default '',
  title_badini text not null default '',
  deep_link text,
  created_at timestamptz not null default now()
);

insert into public.content_updates_new
select
  coalesce(s.id, b.id),
  coalesce(s.kind, b.kind),
  coalesce(s.title, ''),
  coalesce(b.title, s.title, ''),
  coalesce(s.deep_link, b.deep_link),
  coalesce(s.created_at, b.created_at, now())
from (select * from public.content_updates where language = 'sorani') s
full join (select * from public.content_updates where language = 'badini') b on s.id = b.id;

create table public.surahs_new (
  number int primary key,
  name_arabic text not null,
  name_sorani text not null default '',
  name_badini text not null default '',
  ayah_count int not null default 0
);

insert into public.surahs_new
select
  coalesce(s.number, b.number),
  coalesce(s.name_arabic, b.name_arabic, ''),
  coalesce(s.name, ''),
  coalesce(b.name, s.name, ''),
  coalesce(s.ayah_count, b.ayah_count, 0)
from (select * from public.surahs where language = 'sorani') s
full join (select * from public.surahs where language = 'badini') b on s.number = b.number;

create table public.verses_new (
  id text primary key,
  surah_number int not null references public.surahs_new(number) on delete cascade,
  ayah_number int not null,
  arabic text not null,
  translation_sorani text not null default '',
  translation_badini text not null default '',
  explanation_sorani text not null default '',
  explanation_badini text not null default '',
  tafsir_sorani text not null default '',
  tafsir_badini text not null default '',
  source_refs_sorani text[] not null default '{}',
  source_refs_badini text[] not null default '{}',
  related_verse_ids text[] not null default '{}',
  word_ids text[] not null default '{}',
  audio_url text,
  updated_at timestamptz not null default now(),
  unique (surah_number, ayah_number)
);

insert into public.verses_new
select
  coalesce(s.id, b.id),
  coalesce(s.surah_number, b.surah_number),
  coalesce(s.ayah_number, b.ayah_number),
  coalesce(s.arabic, b.arabic, ''),
  coalesce(s.translation, ''),
  coalesce(b.translation, s.translation, ''),
  coalesce(s.explanation, ''),
  coalesce(b.explanation, s.explanation, ''),
  coalesce(s.tafsir, ''),
  coalesce(b.tafsir, s.tafsir, ''),
  coalesce(s.source_refs, '{}'::text[]),
  coalesce(b.source_refs, s.source_refs, '{}'::text[]),
  coalesce(s.related_verse_ids, b.related_verse_ids, '{}'::text[]),
  coalesce(s.word_ids, b.word_ids, '{}'::text[]),
  coalesce(s.audio_url, b.audio_url),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.verses where language = 'sorani') s
full join (select * from public.verses where language = 'badini') b on s.id = b.id;

create table public.words_new (
  id text primary key,
  arabic text not null,
  normalized text not null default '',
  root text not null default '',
  meaning_sorani text not null default '',
  meaning_badini text not null default '',
  occurrences int not null default 1,
  surahs_sorani text[] not null default '{}',
  surahs_badini text[] not null default '{}',
  example_verse_ids text[] not null default '{}',
  related_word_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

insert into public.words_new
select
  coalesce(s.id, b.id),
  coalesce(s.arabic, b.arabic, ''),
  coalesce(s.normalized, b.normalized, ''),
  coalesce(s.root, b.root, ''),
  coalesce(s.meaning, ''),
  coalesce(b.meaning, s.meaning, ''),
  coalesce(s.occurrences, b.occurrences, 1),
  coalesce(s.surahs, '{}'::text[]),
  coalesce(b.surahs, s.surahs, '{}'::text[]),
  coalesce(s.example_verse_ids, b.example_verse_ids, '{}'::text[]),
  coalesce(s.related_word_ids, b.related_word_ids, '{}'::text[]),
  coalesce(s.updated_at, b.updated_at, now())
from (select * from public.words where language = 'sorani') s
full join (select * from public.words where language = 'badini') b on s.id = b.id;

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

create index book_chapters_book_id_idx on public.book_chapters (book_id, sort_order);
create index topic_articles_topic_id_idx on public.topic_articles (topic_id, sort_order);
create index content_updates_created_at_idx on public.content_updates (created_at desc);
create index verses_surah_ayah_idx on public.verses (surah_number, ayah_number);
create index words_arabic_idx on public.words (arabic);

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
