-- SKINOVA v2. Uruchom w SQL Editor NOWEGO / pustego projektu Supabase.
create extension if not exists pgcrypto;
create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 username text not null,
 balance bigint not null default 1000 check(balance>=0),
 created_at timestamptz not null default now()
);
create table if not exists public.cases(
 id text primary key, name text not null, cost bigint not null check(cost>=0)
);
create table if not exists public.skins(
 id bigint generated always as identity primary key,
 case_id text not null references public.cases(id),
 slug text not null unique, name text not null, item_value bigint not null,
 rarity_color text not null, weight int not null check(weight>0)
);
create table if not exists public.inventory(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 slug text not null,item_name text not null,item_value bigint not null,rarity_color text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.case_history(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 case_name text not null,item_name text not null,item_value bigint not null,
 created_at timestamptz not null default now()
);
create table if not exists public.bonus_claims(
 user_id uuid not null references public.profiles(id) on delete cascade,
 claim_day date not null,
 primary key(user_id,claim_day)
);
create or replace function public.new_player()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,username,balance)
 values(new.id,left(coalesce(nullif(split_part(new.email,'@',1),''),'Gracz'),24),1000)
 on conflict do nothing;
 return new;
end;$$;
drop trigger if exists skinova_user_created on auth.users;
create trigger skinova_user_created after insert on auth.users for each row execute function public.new_player();
alter table public.profiles enable row level security;
alter table public.cases enable row level security;
alter table public.skins enable row level security;
alter table public.inventory enable row level security;
alter table public.case_history enable row level security;
alter table public.bonus_claims enable row level security;
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using(id=auth.uid());
drop policy if exists inventory_read on public.inventory;
create policy inventory_read on public.inventory for select to authenticated using(user_id=auth.uid());
drop policy if exists history_read on public.case_history;
create policy history_read on public.case_history for select to authenticated using(user_id=auth.uid());
drop policy if exists cases_read on public.cases;
create policy cases_read on public.cases for select to authenticated using(true);
drop policy if exists skins_read on public.skins;
create policy skins_read on public.skins for select to authenticated using(true);
revoke all on public.profiles,public.inventory,public.case_history,public.bonus_claims from anon,authenticated;
grant select on public.profiles,public.inventory,public.case_history,public.cases,public.skins to authenticated;

-- Ranking is deliberately built with SECURITY DEFINER and exposes only aggregate public data,
-- not emails or balances. The function has no user-controlled input.
create or replace function public.get_leaderboard()
returns table(username text,items_count bigint,opens_count bigint)
language sql security definer set search_path='' as $$
 select p.username,
 (select count(*) from public.inventory i where i.user_id=p.id),
 (select count(*) from public.case_history h where h.user_id=p.id)
 from public.profiles p
 order by 2 desc,3 desc limit 30
$$;
revoke all on function public.get_leaderboard() from public,anon;
grant execute on function public.get_leaderboard() to authenticated;
-- API view can read only the current user's rows; frontend uses get_leaderboard RPC.

create or replace function public.bonus_status()
returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Zaloguj się';end if;
 return jsonb_build_object('claimed',exists(select 1 from public.bonus_claims where user_id=auth.uid() and claim_day=(now() at time zone 'utc')::date));
end;$$;
create or replace function public.claim_bonus()
returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Zaloguj się';end if;
 insert into public.bonus_claims(user_id,claim_day) values(auth.uid(),(now() at time zone 'utc')::date)
 on conflict do nothing;
 if not found then raise exception 'Bonus został już odebrany';end if;
 update public.profiles set balance=balance+250 where id=auth.uid();
 return jsonb_build_object('amount',250);
end;$$;
create or replace function public.open_case(p_case_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare c public.cases%rowtype; chosen public.skins%rowtype; r record; total integer; draw integer; running integer:=0;
begin
 if auth.uid() is null then raise exception 'Zaloguj się';end if;
 select * into c from public.cases where id=p_case_id;
 if not found then raise exception 'Nie ma takiej skrzynki';end if;
 select sum(weight)::int into total from public.skins where case_id=c.id;
 if coalesce(total,0)=0 then raise exception 'Pusta skrzynka';end if;
 update public.profiles set balance=balance-c.cost where id=auth.uid() and balance>=c.cost;
 if not found then raise exception 'Za mało monet';end if;
 draw=1+floor(random()*total)::int;
 for r in select * from public.skins where case_id=c.id order by id loop
   running=running+r.weight;
   if draw<=running then chosen=r;exit;end if;
 end loop;
 insert into public.inventory(user_id,slug,item_name,item_value,rarity_color)
 values(auth.uid(),chosen.slug,chosen.name,chosen.item_value,chosen.rarity_color);
 insert into public.case_history(user_id,case_name,item_name,item_value)
 values(auth.uid(),c.name,chosen.name,chosen.item_value);
 return jsonb_build_object('item',jsonb_build_object('slug',chosen.slug,'name',chosen.name,'value',chosen.item_value,'color',chosen.rarity_color));
end;$$;
revoke all on function public.bonus_status(),public.claim_bonus(),public.open_case(text) from public,anon;
grant execute on function public.bonus_status(),public.claim_bonus(),public.open_case(text) to authenticated;

insert into public.cases(id,name,cost) values ('whoops','WHOOPS!',400) on conflict(id) do update set name=excluded.name,cost=excluded.cost;
insert into public.skins(case_id,name,item_value,weight,rarity_color,slug) values
('whoops','★ Gut Knife | Stained (Field-Tested)',2200,1,'#facc15','gut-knife-stained'),
('whoops','AWP | Queen''s Gambit (Battle-Scarred)',950,3,'#f97316','awp-queens-gambit'),
('whoops','Desert Eagle | Ocean Drive (Minimal Wear)',650,5,'#d946ef','deagle-ocean-drive'),
('whoops','FAMAS | Djinn (Well-Worn)',220,12,'#a78bfa','famas-djinn'),
('whoops','FAMAS | Styx (Field-Tested)',260,11,'#a78bfa','famas-styx'),
('whoops','P90 | Scarab Rush (Well-Worn)',180,15,'#60a5fa','p90-scarab-rush'),
('whoops','P2000 | Space Race (Minimal Wear)',150,16,'#60a5fa','p2000-space-race'),
('whoops','PP-Bizon | Rust Coat (Minimal Wear)',90,20,'#60a5fa','pp-bizon-rust-coat'),
('whoops','SCAR-20 | Cardiac (Well-Worn)',280,9,'#a78bfa','scar20-cardiac'),
('whoops','USP-S | Monster Mashup (Well-Worn)',520,8,'#d946ef','usps-monster-mashup')
on conflict(slug) do update set name=excluded.name,item_value=excluded.item_value,weight=excluded.weight,rarity_color=excluded.rarity_color;
