-- Premium PDF digital library schema for رووناهى books.
-- PDFs live in Supabase Storage (bucket: books). Metadata lives here.

create table if not exists public.book_categories (
  id text primary key,
  title_sorani text not null default '',
  title_badini text not null default '',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.books
  add column if not exists cover_image_url text,
  add column if not exists pdf_url text,
  add column if not exists category_id text references public.book_categories(id) on delete set null,
  add column if not exists language text not null default 'ku',
  add column if not exists page_count int not null default 0,
  add column if not exists published_at timestamptz,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists featured boolean not null default false;

-- Prefer pdf_url; keep source_url as legacy alias if present.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'books' and column_name = 'source_url'
  ) then
    update public.books
    set pdf_url = coalesce(nullif(pdf_url, ''), source_url)
    where pdf_url is null or pdf_url = '';
  end if;
end $$;

create index if not exists books_category_id_idx on public.books (category_id);
create index if not exists books_published_at_idx on public.books (published_at desc nulls last);
create index if not exists books_featured_idx on public.books (featured) where featured = true;

alter table public.book_categories enable row level security;

drop policy if exists book_categories_public_read on public.book_categories;
create policy book_categories_public_read
  on public.book_categories for select
  to anon, authenticated
  using (true);

-- Storage bucket for PDF files and covers (run once; ignore if exists).
insert into storage.buckets (id, name, public)
values ('books', 'books', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists books_storage_public_read on storage.objects;
create policy books_storage_public_read
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'books');
