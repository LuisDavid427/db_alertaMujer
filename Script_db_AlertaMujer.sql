-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.alertas (
  estado_alerta character varying,
  fecha timestamp without time zone,
  mensaje character varying NOT NULL,
  id_usuario integer NOT NULL,
  id_alerta integer NOT NULL DEFAULT nextval('alertas_id_alerta_seq'::regclass),
  CONSTRAINT alertas_pkey PRIMARY KEY (id_alerta),
  CONSTRAINT fkjad1866kolvlv9p7r68vqdwb9 FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario)
);
CREATE TABLE public.dispositivos (
  fecha_registro timestamp without time zone,
  modelo_dispositivo character varying,
  os_version character varying,
  token_fcm character varying,
  id_usuario integer NOT NULL,
  id_dispositivo integer NOT NULL DEFAULT nextval('dispositivos_id_dispositivo_seq'::regclass),
  CONSTRAINT dispositivos_pkey PRIMARY KEY (id_dispositivo),
  CONSTRAINT fkjjhh0ilyao2coeg8sc3u0ovwt FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario)
);
CREATE TABLE public.evidencias (
  fecha_envio timestamp without time zone,
  tipo character varying NOT NULL,
  url character varying NOT NULL,
  id_alerta integer NOT NULL,
  id_evidencia integer NOT NULL DEFAULT nextval('evidencias_id_evidencia_seq'::regclass),
  CONSTRAINT evidencias_pkey PRIMARY KEY (id_evidencia),
  CONSTRAINT fk8umpare3r0q7visiqpgl8s8y1 FOREIGN KEY (id_alerta) REFERENCES public.alertas(id_alerta)
);
CREATE TABLE public.permisos (
  descripcion character varying,
  nombre_permiso character varying NOT NULL UNIQUE,
  id_permiso integer NOT NULL DEFAULT nextval('permisos_id_permiso_seq'::regclass),
  CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso)
);
CREATE TABLE public.politicas_contrasenas (
  caducidad_dias integer,
  esta_activa boolean,
  nombre_politica character varying NOT NULL UNIQUE,
  requiere_mayusculas boolean,
  requiere_numeros boolean,
  requiere_simbolos boolean,
  id_politica integer NOT NULL DEFAULT nextval('politicas_contrasenas_id_politica_seq'::regclass),
  maxlongitud integer DEFAULT 20,
  minlongitud integer DEFAULT 8,
  CONSTRAINT politicas_contrasenas_pkey PRIMARY KEY (id_politica)
);
CREATE TABLE public.roles (
  descripcion character varying,
  nombre_rol character varying NOT NULL UNIQUE,
  id_politica integer,
  id_rol integer NOT NULL DEFAULT nextval('roles_id_rol_seq'::regclass),
  CONSTRAINT roles_pkey PRIMARY KEY (id_rol),
  CONSTRAINT fk7q0foj4jp68d40exxqm1dle3r FOREIGN KEY (id_politica) REFERENCES public.politicas_contrasenas(id_politica)
);
CREATE TABLE public.roles_permisos (
  id_rol integer NOT NULL,
  id_permiso integer NOT NULL,
  CONSTRAINT fk4h8gjvsfn5njneo4l657x4pqm FOREIGN KEY (id_permiso) REFERENCES public.permisos(id_permiso),
  CONSTRAINT fklbd1ngpbh0vro1s0lvk6ces5u FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol)
);
CREATE TABLE public.sesion_usuarios (
  estadosesion character varying,
  fechafin timestamp without time zone,
  fechainicio timestamp without time zone,
  ip_origen character varying,
  id_dispositivo integer NOT NULL,
  id_usuario integer NOT NULL,
  id_sesion integer NOT NULL DEFAULT nextval('sesion_usuarios_id_sesion_seq'::regclass),
  CONSTRAINT sesion_usuarios_pkey PRIMARY KEY (id_sesion),
  CONSTRAINT fkspmo8w16dljwwhdxaajupx0d4 FOREIGN KEY (id_dispositivo) REFERENCES public.dispositivos(id_dispositivo),
  CONSTRAINT fklx1ooxebcridtp2le567ka7dc FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario)
);
CREATE TABLE public.ubicaciones (
  fecha_hora_registro timestamp without time zone,
  latitud numeric NOT NULL,
  longitud numeric NOT NULL,
  precision_gps numeric,
  velocidad numeric,
  id_alerta integer NOT NULL,
  id_ubicacion bigint NOT NULL DEFAULT nextval('ubicaciones_id_ubicacion_seq'::regclass),
  CONSTRAINT ubicaciones_pkey PRIMARY KEY (id_ubicacion),
  CONSTRAINT fk1d4nksghpj2pu6j05qckw5ifc FOREIGN KEY (id_alerta) REFERENCES public.alertas(id_alerta)
);
CREATE TABLE public.usuarios (
  codigo_recuperacion character varying,
  contrasena_hash character varying NOT NULL,
  email character varying UNIQUE,
  estado_usuario boolean,
  expiracion_codigo timestamp without time zone,
  fcm_token character varying,
  fecha_actualizacion timestamp without time zone,
  fecha_creacion timestamp without time zone,
  fecha_nacimiento timestamp without time zone,
  nombre character varying NOT NULL,
  ultimo_acceso timestamp without time zone,
  id_usuario integer NOT NULL DEFAULT nextval('usuarios_id_usuario_seq'::regclass),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario)
);
CREATE TABLE public.usuarios_roles (
  fechaasignacion timestamp without time zone,
  id_rol integer NOT NULL,
  id_usuario integer NOT NULL,
  id_ur integer NOT NULL DEFAULT nextval('usuarios_roles_id_ur_seq'::regclass),
  CONSTRAINT usuarios_roles_pkey PRIMARY KEY (id_ur),
  CONSTRAINT fkhcbndx0dnk4c3ww8jfg98k7el FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol),
  CONSTRAINT fkt5th9sao5wjukq9ij7154ktuw FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario)
);


insert into politicas_contrasenas (nombre_politica, minlongitud, maxlongitud, requiere_mayusculas, requiere_numeros, requiere_simbolos)
values ('politica estandar', 8, 20, true, true, true);


insert into roles (nombre_rol, descripcion, id_politica)
values ('usuaria', 'usuarias de la aplicacion movil alerta mujer', (select id_politica from politicas_contrasenas where nombre_politica = 'politica estandar'));

create or replace function sp_obtener_tokens_por_emails(
    p_lista_emails text
)
returns table (
    token_fcm varchar(255)
) as $$
begin
    return query
    select distinct u.fcm_token 
    from usuarios u
    where u.email = ANY(string_to_array(p_lista_emails, ','))
      and u.fcm_token is not null 
      and u.fcm_token != '';
end;
$$ language plpgsql;


create or replace function sp_listar_alertas_dashboard(p_busqueda varchar(255))
returns table (
    id_alerta int,
    nombre_victima varchar(255),
    mensaje varchar(250),
    estado_alerta varchar(50),
    fecha timestamp,
    latitud numeric(10, 7),
    longitud numeric(10, 7)
) as $$
declare
    v_busqueda text;
begin
    v_busqueda := coalesce(trim(p_busqueda), '');

    return query
    select 
        a.id_alerta,
        u.nombre as nombre_victima,
        a.mensaje,
        a.estado_alerta,
        a.fecha,
        (select ub.latitud from ubicaciones ub where ub.id_alerta = a.id_alerta order by ub.id_ubicacion desc limit 1) as latitud,
        (select ub.longitud from ubicaciones ub where ub.id_alerta = a.id_alerta order by ub.id_ubicacion desc limit 1) as longitud
    from alertas a
    join usuarios u on a.id_usuario = u.id_usuario
    where v_busqueda = '' 
       or u.nombre ilike '%' || v_busqueda || '%' 
       or a.mensaje ilike '%' || v_busqueda || '%' 
       or a.estado_alerta ilike '%' || v_busqueda || '%'
       or (v_busqueda ~ '^[0-9]+$' and a.id_alerta = a.id_alerta)
    order by a.fecha desc;
end;
$$ language plpgsql;


-- sp para usuarios: lista todo y permite busqueda por nombre, email o id
create or replace function sp_listar_usuarios_dashboard(p_busqueda varchar(100))
returns table (
    id_usuario int,
    nombre varchar(255),
    email varchar(150),
    activo boolean
) as $$
declare
    v_busqueda text;
begin
    v_busqueda := coalesce(trim(p_busqueda), '');

    return query
    select u.id_usuario, u.nombre, u.email, u.estado_usuario as activo 
    from usuarios u
    where v_busqueda = '' 
       or u.nombre ilike '%' || v_busqueda || '%' 
       or u.email ilike '%' || v_busqueda || '%' 
       or (v_busqueda ~ '^[0-9]+$' and u.id_usuario = v_busqueda::integer)
    order by u.fecha_creacion desc;
end;
$$ language plpgsql;