# Manual Database Setup

Since the bulk script is causing an error in your dashboard, please try running these commands **one by one** in the SQL Editor. Clear the editor after each successful run.

### Step 1: Cleanup (Optional)

```sql
drop table if exists public.logs;
drop table if exists public.comments;
drop table if exists public.attachments;
drop table if exists public.cards;
drop table if exists public.columns;
```

### Step 2: Create "columns" table

```sql
create table public.columns (
  id text primary key,
  title text not null,
  "order" integer not null,
  created_at timestamp with time zone default now() not null
);
```

### Step 3: Create "cards" table

```sql
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
```

### Step 4: Enable Security

```sql
alter table public.columns enable row level security;
alter table public.cards enable row level security;

create policy "public_columns_access" on public.columns for all using (true);
create policy "public_cards_access" on public.cards for all using (true);
```

### Step 5: Insert Default Data

```sql
insert into public.columns (id, title, "order") values
('col-todo', 'A FAZER', 0),
('col-doing', 'EM PROGRESSO', 1),
('col-done', 'REVISÃO', 2);
```
