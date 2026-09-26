-- Questions: question + answer (+ optional category) and optional related video.
-- Answer text uses ((word)) for Quran words; single (parentheses) stay visible.

alter table public.questions
  add column if not exists video_id text;

-- Keep first related topic's video is not available; related_verse/topic arrays go away.
-- No video list on questions historically — video_id starts empty unless set in CMS.

alter table public.questions
  drop column if exists related_verse_ids,
  drop column if exists related_topic_ids;
