-- Drop previous tables if they exist (for clean slate)
drop table if exists public.logs;
drop table if exists public.comments;
drop table if exists public.attachments; 
drop table if exists public.cards;
drop table if exists public.columns;

-- Create Columns Table
create table public.columns (
  id text primary key,
  title text not null,
  "order" integer not null,
  created_at timestamp with time zone default now() not null
);

-- Create Cards Table with JSONB for nested data
create table public.cards (
  id text primary key,
  column_id text references public.columns(id) on delete cascade not null,
  title text not null,
  description text,
  attachments jsonb default '[]'::jsonb,
  comments jsonb default '[]'::jsonb,
  history jsonb default '[]'::jsonb,
  time_in_columns jsonb default '{}'::jsonb,
  created_at bigint not null,
  last_moved_at bigint not null
);

-- Enable Row Level Security (RLS)
alter table public.columns enable row level security;
alter table public.cards enable row level security;

-- Create Policies
-- Note: Policy names must be unique per table, but using distinct names is safer for tooling.
create policy "public_columns_access" on public.columns for all using (true);
create policy "public_cards_access" on public.cards for all using (true);

-- Insert Default Columns
insert into public.columns (id, title, "order") values 
('col-todo', 'A FAZER', 0),
('col-doing', 'EM PROGRESSO', 1),
('col-done', 'REVISÃO', 2);
