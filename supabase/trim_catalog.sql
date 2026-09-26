-- Keep a small catalog: 5 topics, 1 video, 5 research, 5 questions, 1 book.



delete from videos

where id not in (

  select id from (

    select id

    from videos

    order by (coalesce(video_url, '') <> '') desc, featured desc, id

    limit 1

  ) keep_videos

);



delete from books

where id not in (

  select id from (

    select id

    from books

    order by case when id like 'book-%' then 0 else 1 end, id

    limit 1

  ) keep_books

);



delete from research

where id not in (

  select id from (

    select id

    from research

    order by coalesce(nullif(regexp_replace(id, '\D', '', 'g'), '')::int, 2147483647), id

    limit 5

  ) keep_research

);



delete from questions

where id not in (

  select id from (

    select id

    from questions

    order by coalesce(nullif(regexp_replace(id, '\D', '', 'g'), '')::int, 2147483647), id

    limit 5

  ) keep_questions

);



delete from topics

where id not in ('seerah', 'dhikr-1', 'dhikr-27', 'dhikr-28', 'dhikr-29');



update videos set related_ids = '{}';



update research

set related_ids = coalesce((

  select array_agg(x)

  from unnest(related_ids) as x

  where x in (select id from research)

), '{}');



update questions

set video_id = null

where video_id is not null

  and video_id not in (select id from videos);



update topics

set video_id = null

where video_id is not null

  and video_id not in (select id from videos);



update daily_content

set topic_id = 'dhikr-1'

where topic_id not in (select id from topics);

