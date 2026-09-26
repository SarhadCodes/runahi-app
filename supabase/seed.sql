insert into public.app_config (
  id,
  whatsapp_number,
  whatsapp_prefill_sorani,
  whatsapp_prefill_badini,
  content_version,
  privacy_url,
  terms_url,
  support_email,
  about_body_sorani,
  about_body_badini,
  mission_body_sorani,
  mission_body_badini,
  team_body_sorani,
  team_body_badini
) values (
  'default',
  '',
  'سڵاو، پرسیارێکم هەیە سەبارەت بە رووناهى.',
  'سلاڤ، پسیارەکە هەیە لدور رووناهى.',
  '1',
  'https://rounahi.app/privacy',
  'https://rounahi.app/terms',
  '',
  'رووناهى پلاتفۆڕمێکی کوردییە بۆ خوێندنەوە، توێژینەوە و تێگەیشتنی قورئان.',
  'رووناهى پلاتفۆرمایەکا کوردییە بۆ خاندن، ڤەکولین و تێگەهشتنا قورئانێ.',
  'ئامانجی رووناهى ئەوەیە خوێنەری کورد بتوانێت قورئان بخوێنێتەوە و واتای ئایەت و وشەکان تێبگات.',
  'ئارمانجا رووناهى ئەوەیە خواندەڤانێ کورد بشێت قورئانێ بخوێنیت و رامانا ئایەت و پەیڤان تێبگەهیت.',
  'ناوەڕۆک لە پانێلی بەڕێوەبردنەوە نوێ دەکرێتەوە.',
  'ناڤەڕۆک ژ پانێلا بەڕێڤەبرنێ دهێتە نووکرن.'
);

insert into public.daily_content (
  id, verse_id, arabic, translation_sorani, translation_badini,
  topic_id, topic_title_sorani, topic_title_badini, word_id, message_sorani, message_badini
) values (
  current_date,
  '20-114',
  'وَقُل رَّبِّ زِدْنِي عِلْمًا',
  'و بڵێ: پەروەردگارم، زانستم زیاد بکە.',
  'و بێژە: پەروەردگارێ من، زانینا من زێدە بکە.',
  'topic-ilm',
  'زانست و فێربوون',
  'زانست و فێربوون',
  'word-ilm',
  'ڕۆژێک بە داواکردنی زانست دەست پێدەکات.',
  'ڕۆژەک ب داخوازیا زانستێ دەستپێدکەت.'
);
