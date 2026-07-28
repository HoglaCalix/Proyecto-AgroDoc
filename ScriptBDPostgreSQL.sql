-- =========================================================
-- SCRIPT DE BASE DE DATOS - AGRODOC (POSTGRESQL)
-- =========================================================

-- 1. Tablas independientes o principales
CREATE TABLE ROL (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE PLAGA_ENFERMEDAD (
    id_plaga SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT
);

CREATE TABLE MODELO_IA (
    id_modelo SERIAL PRIMARY KEY,
    version VARCHAR(30) NOT NULL,
    precision_modelo FLOAT,
    tipo_entrenamiento VARCHAR(50),
    fecha_entrenamiento TIMESTAMP
);

-- Uso de comillas dobles debido a que PLAN es palabra reservada en Postgres
CREATE TABLE "PLAN" (
    id_plan SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    precio FLOAT DEFAULT 0,
    beneficios TEXT
);

-- 2. Tablas que dependen de ROL
CREATE TABLE USUARIO (
    id_usuario SERIAL PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    telefono_verificado BOOLEAN DEFAULT FALSE,
    two_fa_activo BOOLEAN DEFAULT FALSE,
    foto_perfil VARCHAR(255),
    estado VARCHAR(20) DEFAULT 'activo',
    consentimiento_datos BOOLEAN DEFAULT FALSE,
    fecha_registro DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (id_rol) REFERENCES ROL(id_rol)
);

-- 3. Tablas que dependen de USUARIO, PLAGA_ENFERMEDAD o "PLAN"
CREATE TABLE CODIGO_RECUPERACION (
    id_codigo SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    fecha_expiracion TIMESTAMP NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE PREFERENCIA_USUARIO (
    id_preferencia SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    idioma VARCHAR(20) DEFAULT 'es',
    unidad_area VARCHAR(20) DEFAULT 'hectareas',
    unidad_temperatura VARCHAR(20) DEFAULT 'celsius',
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE PREFERENCIA_NOTIFICACION (
    id_preferencia_notif SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    activado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE NOTIFICACION (
    id_notificacion SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    contenido TEXT NOT NULL,
    prioridad VARCHAR(20) DEFAULT 'informativa',
    leido BOOLEAN DEFAULT FALSE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE CULTIVO (
    id_cultivo SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    lote VARCHAR(100) NOT NULL,
    variedad VARCHAR(100) NOT NULL,
    tipo_cultivo VARCHAR(100),
    ubicacion VARCHAR(255) NOT NULL,
    fecha_siembra DATE,
    superficie FLOAT,
    estado VARCHAR(20) DEFAULT 'optimo',
    foto VARCHAR(255),
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE TRATAMIENTO (
    id_tratamiento SERIAL PRIMARY KEY,
    id_plaga INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    dosis VARCHAR(100),
    prioridad VARCHAR(20),
    descripcion TEXT,
    FOREIGN KEY (id_plaga) REFERENCES PLAGA_ENFERMEDAD(id_plaga)
);

CREATE TABLE RECOMENDACION_PREVENCION (
    id_recomendacion SERIAL PRIMARY KEY,
    id_plaga INT NOT NULL,
    contenido TEXT NOT NULL,
    FOREIGN KEY (id_plaga) REFERENCES PLAGA_ENFERMEDAD(id_plaga)
);

CREATE TABLE SUSCRIPCION (
    id_suscripcion SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_plan INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado VARCHAR(20) DEFAULT 'activa',
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
    FOREIGN KEY (id_plan) REFERENCES "PLAN"(id_plan)
);

CREATE TABLE METODO_PAGO (
    id_metodo_pago SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    datos_enmascarados VARCHAR(30),
    predeterminado BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

-- 4. Tablas que dependen de CULTIVO o SUSCRIPCION
CREATE TABLE DIAGNOSTICO (
    id_diagnostico SERIAL PRIMARY KEY,
    id_cultivo INT NOT NULL,
    id_plaga INT,
    foto_diagnostico VARCHAR(255) NOT NULL,
    porcentaje_confianza INT,
    condiciones_climaticas VARCHAR(150),
    clima_favorece_plaga BOOLEAN,
    tipo_acceso VARCHAR(20) DEFAULT 'basico',
    estado VARCHAR(20) DEFAULT 'completado',
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cultivo) REFERENCES CULTIVO(id_cultivo),
    FOREIGN KEY (id_plaga) REFERENCES PLAGA_ENFERMEDAD(id_plaga)
);

CREATE TABLE PAGO (
    id_pago SERIAL PRIMARY KEY,
    id_suscripcion INT NOT NULL,
    id_metodo_pago INT NOT NULL,
    monto FLOAT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'completado',
    FOREIGN KEY (id_suscripcion) REFERENCES SUSCRIPCION(id_suscripcion),
    FOREIGN KEY (id_metodo_pago) REFERENCES METODO_PAGO(id_metodo_pago)
);

-- 5. Tablas finales que dependen de DIAGNOSTICO o PAGO
CREATE TABLE DIAGNOSTICO_TRATAMIENTO (
    id_diag_trat SERIAL PRIMARY KEY,
    id_diagnostico INT NOT NULL,
    id_tratamiento INT NOT NULL,
    FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICO(id_diagnostico),
    FOREIGN KEY (id_tratamiento) REFERENCES TRATAMIENTO(id_tratamiento)
);

CREATE TABLE DATASET_IMAGEN (
    id_dataset_imagen SERIAL PRIMARY KEY,
    id_diagnostico INT NOT NULL,
    id_modelo INT,
    consentimiento BOOLEAN DEFAULT FALSE,
    etiqueta VARCHAR(150),
    prioridad_revision BOOLEAN DEFAULT FALSE,
    origen VARCHAR(50),
    fecha_incorporacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICO(id_diagnostico),
    FOREIGN KEY (id_modelo) REFERENCES MODELO_IA(id_modelo)
);

CREATE TABLE CONSULTA (
    id_consulta SERIAL PRIMARY KEY,
    id_diagnostico INT NOT NULL,
    id_agricultor INT NOT NULL,
    id_agronomo INT,
    estado VARCHAR(20) DEFAULT 'pendiente',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMP,
    respuesta TEXT,
    FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICO(id_diagnostico),
    FOREIGN KEY (id_agricultor) REFERENCES USUARIO(id_usuario),
    FOREIGN KEY (id_agronomo) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE FACTURA (
    id_factura SERIAL PRIMARY KEY,
    id_pago INT NOT NULL,
    url_pdf VARCHAR(255),
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pago) REFERENCES PAGO(id_pago)
);