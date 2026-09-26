-- Verses: only id, surah_number, ayah_number, arabic, translation_sorani, translation_badini.

alter table public.verses
  drop column if exists explanation_sorani,
  drop column if exists explanation_badini,
  drop column if exists tafsir_sorani,
  drop column if exists tafsir_badini,
  drop column if exists source_refs_sorani,
  drop column if exists source_refs_badini,
  drop column if exists related_verse_ids,
  drop column if exists word_ids,
  drop column if exists audio_url;
