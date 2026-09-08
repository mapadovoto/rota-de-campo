create extension if not exists pgcrypto;

create table if not exists public.operations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  client_name text,
  area_name text,
  public_token text unique not null,
  created_at timestamptz not null default now()
);
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  operation_id uuid not null references public.operations(id) on delete cascade,
  name text not null,
  track_token text unique not null,
  created_at timestamptz not null default now()
);
create table if not exists public.tracking_sessions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create table if not exists public.track_points (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.tracking_sessions(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  accuracy double precision,
  speed double precision,
  heading double precision,
  recorded_at timestamptz not null default now()
);

alter table public.operations enable row level security;
alter table public.teams enable row level security;
alter table public.tracking_sessions enable row level security;
alter table public.track_points enable row level security;

-- MVP: criação anônima de operações/equipes. Na V2, substituir por login de administrador.
create policy "mvp create operations" on public.operations for insert to anon with check (true);
create policy "mvp read created operation" on public.operations for select to anon using (true);
create policy "mvp create teams" on public.teams for insert to anon with check (true);
create policy "mvp read teams" on public.teams for select to anon using (true);

grant select,insert on public.operations to anon;
grant select,insert on public.teams to anon;

create or replace function public.get_team_by_token(p_token text)
returns table(team_id uuid,team_name text,operation_name text,area_name text)
language sql security definer set search_path=public as $$
 select t.id,t.name,o.name,o.area_name from teams t join operations o on o.id=t.operation_id where t.track_token=p_token limit 1;
$$;
create or replace function public.start_tracking_session(p_token text)
returns uuid language plpgsql security definer set search_path=public as $$
declare tid uuid; sid uuid; begin select id into tid from teams where track_token=p_token; if tid is null then raise exception 'Token inválido'; end if; insert into tracking_sessions(team_id) values(tid) returning id into sid; return sid; end $$;
create or replace function public.add_track_point(p_session uuid,p_token text,p_lat double precision,p_lng double precision,p_accuracy double precision default null,p_speed double precision default null,p_heading double precision default null)
returns void language plpgsql security definer set search_path=public as $$
begin if not exists(select 1 from tracking_sessions s join teams t on t.id=s.team_id where s.id=p_session and t.track_token=p_token and s.ended_at is null) then raise exception 'Sessão inválida'; end if; insert into track_points(session_id,lat,lng,accuracy,speed,heading) values(p_session,p_lat,p_lng,p_accuracy,p_speed,p_heading); end $$;
create or replace function public.stop_tracking_session(p_session uuid,p_token text)
returns void language plpgsql security definer set search_path=public as $$
begin update tracking_sessions s set ended_at=now() from teams t where s.id=p_session and t.id=s.team_id and t.track_token=p_token; end $$;
create or replace function public.get_public_operation(p_token text)
returns jsonb language sql security definer set search_path=public as $$
select jsonb_build_object(
 'operation',jsonb_build_object('id',o.id,'name',o.name,'client_name',o.client_name,'area_name',o.area_name),
 'teams',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',t.name,'active',exists(select 1 from tracking_sessions s where s.team_id=t.id and s.ended_at is null),'points',coalesce((select jsonb_agg(jsonb_build_object('lat',p.lat,'lng',p.lng,'recorded_at',p.recorded_at) order by p.recorded_at) from track_points p join tracking_sessions s2 on s2.id=p.session_id where s2.team_id=t.id),'[]'::jsonb))) from teams t where t.operation_id=o.id),'[]'::jsonb)
) from operations o where o.public_token=p_token limit 1;
$$;

grant execute on function public.get_team_by_token(text) to anon;
grant execute on function public.start_tracking_session(text) to anon;
grant execute on function public.add_track_point(uuid,text,double precision,double precision,double precision,double precision,double precision) to anon;
grant execute on function public.stop_tracking_session(uuid,text) to anon;
grant execute on function public.get_public_operation(text) to anon;
