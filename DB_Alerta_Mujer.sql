create database if not exists bd_alerta_mujer;
use bd_alerta_mujer;

SET FOREIGN_KEY_CHECKS = 0;

create table if not exists politicas_contrasenas (
	id_politica int primary key auto_increment,
    nombre_politica varchar(100) unique not null,
    minlongitud int default 8,
    maxlongitud int default 20,
    requiere_mayusculas tinyint(1) default 1,
    requiere_numeros tinyint(1) default 1,
    requiere_simbolos tinyint(1) default 1,
    caducidad_dias int default 90,
    esta_activa tinyint(1) default 1
);


create table if not exists configuraciones_seguridad (
	id_configuracion int primary key auto_increment,
    nombreconfiguracion varchar(100) unique not null,
    valorconfiguracion varchar(100),
    descripcion varchar(255)
);


create table if not exists usuarios (
	id_usuario int primary key auto_increment,
    nombre varchar(255) unique not null,
    email nvarchar(150) unique,
    contrasena_hash varchar(255) not null,
    fecha_nacimiento datetime not null,
    estado_usuario tinyint(1) default 1,
    fecha_creacion datetime default current_timestamp,
    fecha_actualizacion datetime default current_timestamp on update current_timestamp,
    ultimo_acceso datetime
);

create table if not exists roles (
	id_rol int primary key auto_increment,
    nombre_rol varchar(50) unique not null,
    descripcion varchar(255),
    id_politica INT NULL,
    FOREIGN KEY (id_politica) REFERENCES politicas_contrasenas(id_politica)
);

create table if not exists permisos (
	id_permiso int primary key auto_increment,
    nombre_permiso varchar(50) unique not null,
    descripcion varchar(255)
);


create table if not exists alertas(
	id_alerta int primary key auto_increment,
    id_usuario int,
    fecha datetime default current_timestamp,
    url_imagen varchar(255) null,
    url_audio varchar(255) null,
    mensaje varchar(250) not null,
    estado_alerta varchar(50) default 'ACTIVA',
    foreign key (id_usuario) references usuarios (id_usuario)
);


create table if not exists ubicaciones (
	id_ubicacion BIGINT primary key auto_increment,
    id_alerta int not null,
    latitud decimal(10,7) not null,
    longitud decimal(10,7) not null,
    velocidad decimal(5, 2) NULL, 
    precision_gps decimal(5, 2) NULL,
    fecha_hora_registro DATETIME default current_timestamp,
    foreign key (id_alerta) references alertas(id_alerta)
);

create table if not exists contactos (
    id_contacto int primary key auto_increment,
    nombre varchar(80) not null,
    telefono varchar(15) unique not null
);

create table if not exists unidades_respuestas (
    id_unidad int primary key auto_increment,
    nombre_unidad varchar(250) not null,
    tipounidad varchar(150) not null,
    telefono varchar(30) not null,
    email varchar(150)
);

create table if not exists dispositivos(
    id_dispositivo int primary key auto_increment,
    os_version varchar(50)
);


create table if not exists usuarios_configuraciones (
    id_uc INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_configuracion INT NOT NULL,
    valor_usuario VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_configuracion) REFERENCES configuraciones_seguridad(id_configuracion),
    UNIQUE KEY uq_usuario_config (id_usuario, id_configuracion)
);

create table if not exists usuarios_roles (
    id_ur int primary key auto_increment,
    id_usuario int not null,
    id_rol int not null,
    fechaasignacion datetime default current_timestamp,
    foreign key (id_usuario) references usuarios(id_usuario),
    foreign key (id_rol) references roles(id_rol)
);

create table if not exists eleccion_unidades(
	id_eu int primary key auto_increment,
    id_usuario int,
    id_unidad int,
    foreign key (id_usuario) references usuarios(id_usuario),
    foreign key (id_unidad) references unidades_respuestas(id_unidad)

);
create table if not exists dispositivos_usuarios(
	id_du int primary key auto_increment,
    id_usuario int not null,
    id_dispositivo int not null,
    permisos boolean,
    fecha_ingreso datetime default current_timestamp,
    foreign key (id_usuario) references usuarios (id_usuario),
    foreign key (id_dispositivo) references dispositivos (id_dispositivo)
);

create table if not exists usuarios_contactos(
    id_uc int primary key auto_increment,
    id_usuario int,
    id_contacto int,
	parentesco nvarchar(150),
    foreign key (id_usuario) references usuarios(id_usuario),
    foreign key (id_contacto) references contactos(id_contacto)
);

create table if not exists roles_permisos (
    id_rp int primary key auto_increment,
    id_rol int,
    id_permiso int,
    fechaasignacion datetime default current_timestamp,
    foreign key (id_rol) references roles(id_rol),
    foreign key (id_permiso) references permisos(id_permiso)
);

create table if not exists sesion_usuarios (
    id_sesion int primary key auto_increment,
    id_usuario int,
    fechainicio datetime default current_timestamp,
    fechafin datetime,
    ip_origen varchar(50),
    estadosesion varchar(50),
    foreign key (id_usuario) references usuarios(id_usuario)
);

create table if not exists log_errores (
id_error int primary key auto_increment,
fecha datetime default current_timestamp,
id_usuario int,
    tipoerror varchar(100),
    descripcion varchar(500),
    ip_origen varchar(50),
    foreign key (id_usuario) references usuarios(id_usuario)
);
