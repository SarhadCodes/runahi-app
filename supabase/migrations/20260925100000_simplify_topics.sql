-- Topics: title, introduction, body, optional related video.
-- Words wrapped in ((double parentheses)) in body are Quran words in the app.
-- Single (parentheses) stay visible as normal text.

alter table public.topics
  add column if not exists body_sorani text not null default '',
  add column if not exists body_badini text not null default '',
  add column if not exists video_id text;

-- Fold existing article text into the topic body (keep order).
update public.topics t
set
  body_sorani = coalesce((
    select string_agg(
      nullif(trim(concat_ws(E'\n\n', nullif(a.title_sorani, ''), nullif(a.body_sorani, ''))), ''),
      E'\n\n'
      order by a.sort_order, a.id
    )
    from public.topic_articles a
    where a.topic_id = t.id
  ), body_sorani),
  body_badini = coalesce((
    select string_agg(
      nullif(trim(concat_ws(E'\n\n', nullif(a.title_badini, ''), nullif(a.body_badini, ''))), ''),
      E'\n\n'
      order by a.sort_order, a.id
    )
    from public.topic_articles a
    where a.topic_id = t.id
  ), body_badini)
where exists (select 1 from public.topic_articles a where a.topic_id = t.id);

-- Keep the first linked video as the single related video field.
update public.topics
set video_id = coalesce(nullif(video_id, ''), video_ids[1])
where video_ids is not null
  and cardinality(video_ids) > 0
  and coalesce(video_id, '') = '';

drop table if exists public.topic_articles cascade;

alter table public.topics
  drop column if exists verse_ids,
  drop column if exists video_ids,
  drop column if exists related_topic_ids;
