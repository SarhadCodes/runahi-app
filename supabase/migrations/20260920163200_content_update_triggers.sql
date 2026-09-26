-- Record a notification row whenever catalog content is added in the dashboard.

create or replace function public.record_content_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  payload jsonb := to_jsonb(NEW);
  item_id text;
  item_kind text;
  title_s text;
  title_b text;
  link text;
begin
  item_id := coalesce(payload->>'id', '');
  if item_id = '' then
    return NEW;
  end if;

  item_kind := case TG_TABLE_NAME
    when 'books' then 'book'
    when 'research' then 'research'
    when 'videos' then 'video'
    when 'questions' then 'question'
    when 'topics' then 'topic'
    when 'words' then 'word'
    when 'verses' then 'verse'
    else 'announcement'
  end;

  title_s := coalesce(
    nullif(payload->>'title_sorani', ''),
    nullif(payload->>'question_sorani', ''),
    nullif(payload->>'meaning_sorani', ''),
    nullif(payload->>'translation_sorani', ''),
    payload->>'arabic',
    item_id
  );
  title_b := coalesce(
    nullif(payload->>'title_badini', ''),
    nullif(payload->>'question_badini', ''),
    nullif(payload->>'meaning_badini', ''),
    nullif(payload->>'translation_badini', ''),
    title_s
  );

  link := '/' || case item_kind
    when 'book' then 'books'
    when 'research' then 'research'
    when 'video' then 'videos'
    when 'question' then 'questions'
    when 'topic' then 'topics'
    when 'word' then 'words'
    when 'verse' then 'verses'
    else 'notifications'
  end || '/' || item_id;

  insert into public.content_updates (id, kind, title_sorani, title_badini, deep_link)
  values (
    'upd-' || item_kind || '-' || item_id || '-' || replace(clock_timestamp()::text, ' ', ''),
    item_kind,
    title_s,
    title_b,
    link
  );

  return NEW;
end;
$$;

drop trigger if exists books_content_update on public.books;
create trigger books_content_update after insert on public.books
  for each row execute function public.record_content_update();

drop trigger if exists research_content_update on public.research;
create trigger research_content_update after insert on public.research
  for each row execute function public.record_content_update();

drop trigger if exists videos_content_update on public.videos;
create trigger videos_content_update after insert on public.videos
  for each row execute function public.record_content_update();

drop trigger if exists questions_content_update on public.questions;
create trigger questions_content_update after insert on public.questions
  for each row execute function public.record_content_update();

drop trigger if exists topics_content_update on public.topics;
create trigger topics_content_update after insert on public.topics
  for each row execute function public.record_content_update();

drop trigger if exists words_content_update on public.words;
create trigger words_content_update after insert on public.words
  for each row execute function public.record_content_update();

drop trigger if exists verses_content_update on public.verses;
create trigger verses_content_update after insert on public.verses
  for each row execute function public.record_content_update();

do $$
begin
  alter publication supabase_realtime add table public.content_updates;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;
