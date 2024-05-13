/*************************/
/* MODIFICAR TABLA COCHE */
/*************************/
ALTER TABLE dbo.Coches
ADD id INT IDENTITY(1,1)
GO
/**********************/
/* CREACION DE TABLAS */
/**********************/
CREATE TABLE [dbo].[movEntrada](
[id] [int] IDENTITY(1,1) NOT NULL,
[fechaEntrada] [datetime] NOT NULL,
[matricula] [varchar](20) NOT NULL,
[servicioContratado] [char](1) NOT NULL,
[descuento] [smallint] NOT NULL,
[vehiculoEnParking] [bit] NOT NULL,
[enviadoATrafico] [bit] NOT NULL
CONSTRAINT [PK_movEntrada] PRIMARY KEY CLUSTERED)
GO
CREATE TABLE [dbo].[movSalida](
[id] [int] IDENTITY(1,1) NOT NULL,
[idmovEntrada] [int] NOT NULL,
[matricula] [varchar](20) NOT NULL,
[fechaSalida] [datetime] NULL,
[fechaPago] [datetime] NOT NULL,
[duracionReal] [int] NULL,
[costeServicios] [money] NOT NULL,
[clienteConAbono] [bit] NOT NULL,
[enviadoATrafico] [bit] NOT NULL,
[Comentarios] [varchar](100) NOT NULL
CONSTRAINT [PK_movSalida] PRIMARY KEY CLUSTERED)
GO
CREATE TABLE [dbo].[movBarrera](
[matriculaBarreraEntrada] [varchar](20) NOT NULL,
[subirBarreraEntrada] [bit] NOT NULL,
[matriculaBarreraSalida] [varchar](20) NOT NULL,
[subirBarreraSalida] [bit] NOT NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[ocupacion](
[plazasLibresAzules] [int] NULL,
[plazasLibresVerdes] [int] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[tarifaServicios](
[anioMes] [varchar](6) NOT NULL,
[CosteParkingMin] MONEY NOT NULL,
[CosteLimpieza] MONEY NOT NULL,
[CosteKwH] MONEY NOT NULL
)
GO
CREATE TABLE [dbo].[vehiculosEnTransito](
[matricula] [varchar](20) NOT NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[AbonoClientes](
[matricula] [varchar](20) NOT NULL,
[anioMes] [varchar](6) NULL,
[importe] [money] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[tlog](
[id] [int] IDENTITY(1,1) NOT NULL,
[fecha] [datetime] NOT NULL,
[nivel] [varchar](10) NOT NULL,
[matricula] [varchar](20) NOT NULL,
[descripcion] [varchar](500) NOT NULL
CONSTRAINT [PK_tlog] PRIMARY KEY CLUSTERED)
GO
CREATE TABLE datosCoches(
id INT IDENTITY(1,1) NOT NULL,
matricula VARCHAR(7) NOT NULL,
idMatricula INT NOT NULL
)
GO
/*****************************/
/* MODIFICAR TABLA OCUPACIÓN */
/*****************************/
INSERT INTO dbo.ocupacion(plazasLibresAzules, plazasLibresVerdes) VALUES(1500,500)
/**************************/
/* MODIFICAR TABLA TARIFA */
/**************************/
DECLARE @fecha VARCHAR(MAX)=''
DECLARE @kwh MONEY=2
DECLARE @limpieza MONEY=100
DECLARE @parking MONEY=0.12
IF(MONTH(CURRENT_TIMESTAMP))<10 BEGIN
	SET @fecha=(CONVERT(VARCHAR, YEAR(CURRENT_TIMESTAMP))+'0'+CONVERT(VARCHAR, MONTH(CURRENT_TIMESTAMP)))
	INSERT INTO dbo.tarifaServicios(anioMes, CosteKwH, CosteLimpieza, CosteParkingMin)
	VALUES(@fecha, @kwh, @limpieza, @limpieza)
END
	ELSE BEGIN
		SET @fecha=(CONVERT(VARCHAR, YEAR(CURRENT_TIMESTAMP))+''+CONVERT(VARCHAR, MONTH(CURRENT_TIMESTAMP)))
		INSERT INTO dbo.tarifaServicios(anioMes, CosteKwH, CosteLimpieza, CosteParkingMin)
		VALUES(@fecha, @kwh, @limpieza, @limpieza)
	END
GO
/**********/
/* VISTAS */
/**********/
--NÚMERO ALEATORIO
CREATE OR ALTER VIEW numeroMatricula
AS SELECT RAND()*(9999-1000)+1000 numeroGenerarMatricula
GO
CREATE OR ALTER VIEW caracterMatricula
AS SELECT RAND()*(20-1)+1 numeroCaracterMatricula
GO
/*************/
/* FUNCIONES */
/*************/
CREATE OR ALTER FUNCTION generarMatricula()
RETURNS VARCHAR(7)
AS BEGIN
	DECLARE @abecedario VARCHAR(MAX)='BCDFGHJKLMNPQRSTVWXYZ'
	DECLARE @numeroMatricula INT=(SELECT numeroGenerarMatricula FROM numeroMatricula)
	DECLARE @iterar INT=0
	DECLARE @matricula VARCHAR(7)=''+@numeroMatricula
	WHILE(@iterar<3) BEGIN
		DECLARE @posicionRandom INT=(SELECT numeroCaracterMatricula FROM caracterMatricula)
		SET @matricula=@matricula+(SUBSTRING(@abecedario,@posicionRandom,1))
		SET @iterar=@iterar+1
	END
	RETURN @matricula
END
GO
/******************************/
/* AGREGAR MATRÍCULAS A TABLA */
/******************************/
DECLARE @iterar INT=0
WHILE(@iterar<50) BEGIN
	DECLARE @idCoche INT=(RAND()*(2303-1)+1)
	INSERT INTO dbo.datosCoches(matricula, idMatricula)
	VALUES(dbo.generarMatricula(),@idCoche)
	SET @iterar=@iterar+1
END
GO
/*********************************/
/* AGREGAR MATRÍCULAS A ABONADOS */
/*********************************/
DECLARE @iterar INT=1
WHILE(@iterar<=10) BEGIN
	--DATOS INSERTAR--
	DECLARE @matricula VARCHAR(20)=(SELECT matricula FROM dbo.datosCoches WHERE id=@iterar)
	DECLARE @anio VARCHAR(6)=(SELECT anioMes FROM dbo.tarifaServicios)
	DECLARE @importe MONEY=100
	------------------
	--COMPROBAR--
	DECLARE @fecha VARCHAR(MAX)=(SELECT anioMes FROM dbo.tarifaServicios)
	-------------
	IF NOT EXISTS(SELECT * FROM dbo.AbonoClientes WHERE matricula=@matricula AND anioMes=@fecha) BEGIN
		INSERT INTO dbo.AbonoClientes(matricula, anioMes, importe)
		VALUES(@matricula, @anio, @importe)
	END
	SET @iterar=@iterar+1
END
GO
/******************/
/* PROCEDIMIENTOS */
/******************/
--REGISTRAR VEHÍCULOS
CREATE OR ALTER PROCEDURE registrarEnradaVehiculo(
	@matricula VARCHAR(20),
	@servicioContratado CHAR(1)
)
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)='ERROR'
    DECLARE @descripcion VARCHAR(MAX)=''
    --------
    --COMPARACIONES--
    DECLARE @idCoche VARCHAR(MAX)=(SELECT id FROM dbo.datosCoches WHERE matricula=@matricula)
    DECLARE @tipoCoche VARCHAR(MAX)=(SELECT dbo.Coches.Tipo FROM dbo.Coches INNER JOIN dbo.datosCoches ON dbo.Coches.id=dbo.datosCoches.idMatricula WHERE dbo.Coches.id=@idCoche)
    DECLARE @plazasAzules INT=(SELECT plazasLibresAzules FROM dbo.ocupacion)
    DECLARE @plazasVerdes INT=(SELECT plazasLibresVerdes FROM dbo.ocupacion)
    -----------------
    --DATOS A INSERTAR--
    DECLARE @fechaEntrada DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @descuento INT=0;
    DECLARE @entrafico BIT=0;
    DECLARE @enparking BIT=0;
    --------------------

    --COMPROBAMOS SI LA MATRÍCULA EXISTE
    --LA MATRÍCULA EXISTE (CONTINUA)
    IF EXISTS(SELECT matricula FROM dbo.datosCoches WHERE matricula=@matricula) BEGIN
        PRINT 'La matrícula '+@matricula+' existe'
        --COMPROBAMOS QUE LA MATRÍCULA NO ESTÉ EN EL PARKING (CONTINUA)
        IF NOT EXISTS(SELECT matricula FROM dbo.movEntrada WHERE matricula=@matricula) BEGIN
            PRINT 'La matrícula '+@matricula+' no está registrada en el Parking'
            --COMPROBAMOS EL TIPO DE VEHÍCULO QUE ES
            --ES ELÉCTRICO
            IF(UPPER(@tipoCoche) LIKE 'ELECTRICO%') BEGIN
                PRINT 'El Coche con matrícula '+@matricula+' es ELÉCTRICO'
                --COMPROBAMOS EL TIPO DE SERVICIO Y SI HAY PLAZAS DISPONIBLES DE ESE SERVICIO
                --PARKING Y LIMPIEZA
                IF(UPPER(@servicioContratado))IN ('P', 'L') AND (SELECT plazasLibresAzules FROM dbo.ocupacion)>0 BEGIN
                    PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING o LIMPIEZA'
                    SET @enparking=1
                        INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                        VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                END
                    --RECARGA Y TODO
                    ELSE IF(UPPER(@servicioContratado))IN ('R', 'T') AND (SELECT plazasLibresVerdes FROM dbo.ocupacion)>0 BEGIN
                        PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA o TODO'
                        SET @enparking=1
                            INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                            VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                    END
                        --OTRA OPCIÓN (ERROR)
                        ELSE BEGIN
                            PRINT 'No se ha escogido ninguna de las opciones o no hay plazas disponibles'
                            SET @descripcion='No se ha escogido ninguna opción o no hay plazas disponibles'
                                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                                VALUES(@fecha, @nivel, @matricula, @descripcion)
                        END
            END
                --NO ES ELÉCTRICO
                ELSE BEGIN
                    PRINT 'El Coche con matrícula '+@matricula+' no es ELÉCTRICO'
                    SET @entrafico=1
                    --COMPROBAMOS EL TIPO DE SERVICIO Y SI HAY PLAZAS DISPONIBLES DE ESE SERVICIO
                    --PARKING, LIMPIEZA Y TODO
                    IF(UPPER(@servicioContratado))IN ('P', 'L', 'T') AND (SELECT plazasLibresAzules FROM dbo.ocupacion)>0 BEGIN
                        PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING, LIMPIEZA o TODO'
                        SET @enparking=1
                            INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                            VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                    END
                        --OTRA OPCIÓN (ERROR)
                        ELSE BEGIN
                            PRINT 'No se ha escogido ninguna de las opciones o no hay plazas disponibles'
                            SET @descripcion='No se ha escogido ninguna opción o no hay plazas disponibles'
                                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                                VALUES(@fecha, @nivel, @matricula, @descripcion)
                        END
                END
        END
            --COMPROBAMOS QUE SI LA MATRICULA ESTÁ EN EL PARKING PERO YA SE HA IDO QUE PUEDA ENTRAR (CONTINUA)
            ELSE IF EXISTS(SELECT vehiculoEnParking FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=0) AND NOT EXISTS(SELECT matricula FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1) BEGIN
                PRINT 'La matrícula '+@matricula+' se ha ido del Parking, puedes volver a entrar'
                --COMPROBAMOS EL TIPO DE VEHÍCULO QUE ES
                  --ES ELÉCTRICO
                  IF(UPPER(@tipoCoche) LIKE 'ELECTRICO%') BEGIN
                     PRINT 'El Coche con matrícula '+@matricula+' es ELÉCTRICO'
                     --COMPROBAMOS EL TIPO DE SERVICIO Y SI HAY PLAZAS DISPONIBLES DE ESE SERVICIO
                     --PARKING Y LIMPIEZA
                      IF(UPPER(@servicioContratado))IN ('P', 'L') AND (SELECT plazasLibresAzules FROM dbo.ocupacion)>0 BEGIN
                        PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING o LIMPIEZA'
                        SET @enparking=1
                            INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                            VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                      END
                        --RECARGA Y TODO
                         ELSE IF(UPPER(@servicioContratado))IN ('R', 'T') AND (SELECT plazasLibresVerdes FROM dbo.ocupacion)>0 BEGIN
                            PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA o TODO'
                            SET @enparking=1
                                INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                                VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                         END
                            --OTRA OPCIÓN (ERROR)
                            ELSE BEGIN
                                PRINT 'No se ha escogido ninguna de las opciones o no hay plazas disponibles'
                                SET @descripcion='No se ha escogido ninguna opción o no hay plazas disponibles'
                                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                                VALUES(@fecha, @nivel, @matricula, @descripcion)
                            END
                  END
                    --NO ES ELÉCTRICO
                    ELSE BEGIN
                         PRINT 'El Coche con matrícula '+@matricula+' no es ELÉCTRICO'
                          SET @entrafico=1
                          --COMPROBAMOS EL TIPO DE SERVICIO Y SI HAY PLAZAS DISPONIBLES DE ESE SERVICIO
                          --PARKING, LIMPIEZA Y TODO
                          IF(UPPER(@servicioContratado))IN ('P', 'L', 'T') AND (SELECT plazasLibresAzules FROM dbo.ocupacion)>0 BEGIN
                            PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING, LIMPIEZA o TODO'
                            SET @enparking=1
                                INSERT INTO dbo.movEntrada(fechaEntrada, matricula, servicioContratado, descuento, vehiculoEnParking ,enviadoATrafico)
                                VALUES(@fechaEntrada, @matricula ,@servicioContratado, @descuento, @enparking, @entrafico)
                          END
                            --OTRA OPCIÓN (ERROR)
                            ELSE BEGIN
                                PRINT 'No se ha escogido ninguna de las opciones o no hay plazas disponibles'
                                SET @descripcion='No se ha escogido ninguna opción o no hay plazas disponibles'
                                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                                VALUES(@fecha, @nivel, @matricula, @descripcion)
                            END
                    END
            END
                --LA MATRÍCULA YA ESTÁ EN EN PARKING (ERROR)
                ELSE IF EXISTS(SELECT vehiculoEnParking FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1) BEGIN
                     PRINT 'La matrícula '+@matricula+' ya está en el Parking'
                        SET @descripcion='La matrícula ya está en el Parking'
                        INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                        VALUES(@fecha, @nivel, @matricula, @descripcion)
                END
    END
        --LA MATRÍCULA NO EXISTE (ERROR)
        ELSE BEGIN
             PRINT 'La matrícula '+@matricula+' no existe'
                SET @descripcion='La matrícula no existe'
                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                VALUES(@fecha, @nivel, @matricula, @descripcion)
        END
END
GO
DECLARE @matricula VARCHAR(MAX)=(SELECT TOP 1 matricula FROM dbo.datosCoches)
DECLARE @servicio VARCHAR(MAX)='L'
EXEC registrarEnradaVehiculo @matricula, @servicio
GO
--REGISTRAR PAGO VEH�CULOS
CREATE OR ALTER PROCEDURE registrarPagoVehiculo(
	@matricula VARCHAR(20)
)
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)='ERROR'
    DECLARE @descripcion VARCHAR(MAX)=''
    --------
    --DATOS A COMPROBAR--
    DECLARE @fechaEntrada DATETIME=(SELECT fechaEntrada FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1)
    DECLARE @aTrafico BIT=(SELECT enviadoATrafico FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1)
    DECLARE @abonoFecha VARCHAR(MAX)=(SELECT anioMes FROM dbo.tarifaServicios)
    ---------------------
    --DATOS A INSERTAR--
    DECLARE @idEntrada INT=(SELECT id FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1)
    DECLARE @fechaSalida DATETIME=null
    DECLARE @fechaPago DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @duracionReal INT=(DATEDIFF(MINUTE, @fechaEntrada, @fechaPago))
    DECLARE @conAbono BIT=0
    DECLARE @costeServicio MONEY=0
    DECLARE @comentario VARCHAR(MAX)=''
    DECLARE @precio MONEY=0
    --------------------
	--COMPROBAMOS SI LA MATRÍCULA EXISTE
    --EL VEHÍCULO ESTÁ EN EL PARKING (CONTINUA)
    IF EXISTS(SELECT matricula FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1) BEGIN
        PRINT 'El vehículo con la matrícula '+@matricula+' está en el Parking'
        --COMPROBAMOS SI ESTÁ ABONADO
        --ESTÁ ABONADO
        IF EXISTS(SELECT vehiculoEnParking FROM dbo.AbonoClientes INNER JOIN dbo.movEntrada ON dbo.AbonoClientes.matricula=dbo.movEntrada.matricula AND vehiculoEnParking=1 AND dbo.AbonoClientes.anioMes=@abonoFecha)BEGIN
            PRINT 'El vehículo con la matrícula '+@matricula+' está abonado'
            SET @conAbono=1
            --COMPRUEBO EL SERVICIO QUE QUIERE
            --PARKING
            IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN (0,1) AND vehiculoEnParking=1)='P' BEGIN
                PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING'
                SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
            END
                --LIMPIEZA
                ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0,1) AND vehiculoEnParking=1)='L' BEGIN
                    PRINT 'El Coche con matrícula '+@matricula+' ha escogido LIMPIEZA'
                    SET @precio=(SELECT CosteLimpieza FROM dbo.tarifaServicios)
                    SET @costeServicio=@precio
                    SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                    INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                    VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                END
                    --RECARGA
                    ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0) AND vehiculoEnParking=1)='R' BEGIN
                        PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA'
                        SET @precio=0
                        SET @costeServicio=@precio
                        SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                        INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                        VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                    END
                        --TODO ELECTRICO
                        ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico=0 AND vehiculoEnParking=1)='T' BEGIN
                            PRINT 'El Coche con matrícula '+@matricula+' ha escogido TODO'
                            SET @precio=0
                            SET @costeServicio=@precio
                            SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                            INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                            VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                        END
                            --TODO NO ELECTRICO
                            ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico=1 AND vehiculoEnParking=1)='T' BEGIN
                                PRINT 'El Coche con matrícula '+@matricula+' ha escogido TODO'
                                SET @precio=(SELECT CosteLimpieza FROM dbo.tarifaServicios)
                                SET @costeServicio=@precio*CONVERT(MONEY, @duracionReal+60)
                                SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                                INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                                VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                            END
        END
            --NO ESTÁ ABONADO
            ELSE IF NOT EXISTS(SELECT vehiculoEnParking FROM dbo.AbonoClientes INNER JOIN dbo.movEntrada ON dbo.AbonoClientes.matricula=dbo.movEntrada.matricula AND vehiculoEnParking=1 AND dbo.AbonoClientes.anioMes=@abonoFecha) BEGIN
                PRINT 'El vehículo con la matrícula '+@matricula+' no está abonado'
                --COMPRUEBO EL SERVICIO QUE QUIERE
                --PARKING
                IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0,1) AND vehiculoEnParking=1)='P' BEGIN
                    PRINT 'El Coche con matrícula '+@matricula+' ha escogido PARKING'
                    SET @precio=(SELECT CosteParkingMin FROM dbo.tarifaServicios)
                    SET @costeServicio=@precio*CONVERT(MONEY, @duracionReal+60)
                    SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                    INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                    VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                END
                    --LIMPIEZA
                    ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0,1) AND vehiculoEnParking=1)='L' BEGIN
                        PRINT 'El Coche con matrícula '+@matricula+' ha escogido LIMPIEZA'
                        SET @precio=(SELECT CosteLimpieza FROM dbo.tarifaServicios)
                        SET @costeServicio=@precio
                        SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                        INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                        VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                    END
                        --RECARGA
                        ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0) AND vehiculoEnParking=1)='R' BEGIN
                            PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA'
                            SET @precio=0
                            SET @costeServicio=@precio
                            SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                            INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                            VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                        END
                            --TODO ELECTRICO
                            ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(0) AND vehiculoEnParking=1)='T' BEGIN
                                PRINT 'El Coche con matrícula '+@matricula+' ha escogido TODO'
                                SET @precio=0
                                SET @costeServicio=@precio
                                SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                                INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                                VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                            END
                                --TODO NO ELECTRICO
                                ELSE IF(SELECT UPPER(servicioContratado) FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico IN(1) AND vehiculoEnParking=1)='T' BEGIN
                                    PRINT 'El Coche con matrícula '+@matricula+' ha escogido TODO'
                                    SET @precio=(SELECT CosteParkingMin FROM dbo.tarifaServicios)
                                    SET @costeServicio=@precio*CONVERT(MONEY, @duracionReal+60)+(SELECT CosteLimpieza FROM dbo.tarifaServicios)
                                    SET @comentario='El veh�culo con la matr�cula '+@matricula+' ha realizado el pago'
                                    INSERT INTO dbo.movSalida(idmovEntrada, matricula, fechaSalida, fechaPago, duracionReal, costeServicios, clienteConAbono, enviadoATrafico, Comentarios)
                                    VALUES(@idEntrada, @matricula, @fechaSalida, @fechaPago, @duracionReal, @costeServicio, @conAbono, @aTrafico, @comentario)
                                END
            END

    END
        --NO ESTÁ EN EL PARKING (ERROR)
        ELSE BEGIN
            SET @descripcion='El vehículo no está en el Parking'
            INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
            VALUES(@fecha, @nivel, @matricula, @descripcion)
        END
END
GO
DECLARE @matricula VARCHAR(MAX)=(SELECT TOP 1 matricula FROM dbo.datosCoches)
EXEC registrarPagoVehiculo @matricula
GO
--REGISTRAR SALIDA DE VEH�CULOS
CREATE OR ALTER PROCEDURE registrarSalidaVehiculo(
	@matricula VARCHAR(20)
)
AS BEGIN
	--DATOS COMPROBAR--
	DECLARE @fechaPago DATETIME=(SELECT fechaPago FROM dbo.movSalida WHERE matricula=@matricula AND fechaSalida IS NULL)
	DECLARE @fechaActual DATETIME=(CURRENT_TIMESTAMP)
	DECLARE @diferencia DATETIME=(DATEDIFF(MINUTE, @fechaActual, @fechaPago))
	DECLARE @abonoFecha VARCHAR(MAX)=(SELECT anioMes FROM dbo.tarifaServicios)
	-------------------
		--COMRPOBAMOS QUE SI ES MAYOR DE 15 MINUTOS EL PAGO
        --EL TIEMPO ES MENOR DE 15 MINUTOS
		IF(@diferencia)<15 BEGIN
			PRINT 'El veh�culo con matr�cula '+@matricula+' ha salido del PARKING'
			UPDATE dbo.movSalida
			SET fechaSalida=@fechaActual, matricula=@matricula
			WHERE matricula=@matricula
		END
            --EL TIEMPO ES MAYOR DE 15 MINUTOS
			ELSE BEGIN
                --SI ESTÁ ABONADO LE DEJAMOS SALIR
				IF EXISTS(SELECT matricula FROM dbo.AbonoClientes WHERE matricula=@matricula AND dbo.AbonoClientes.anioMes=@abonoFecha) BEGIN
					PRINT 'El veh�culo con matr�cula '+@matricula+' ha salido del PARKING'
					UPDATE dbo.movSalida
					SET fechaSalida=@fechaActual, matricula=@matricula
					WHERE matricula=@matricula
				END
                    --SI NO ESTÁ ABONADO NO LE DEJAMOS SALIR
					ELSE BEGIN
						PRINT 'Tiempo permitido de salida excedido, Por favor, pase por recepci�n'
						INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
						VALUES(@fechaActual, 'ERROR', @matricula, 'Tiempo permitido de salida excedido, Por favor, pase por recepci�n')
					END
			END
END
GO
DECLARE @matricula VARCHAR(MAX)=(SELECT TOP 1 matricula FROM dbo.datosCoches)
EXEC registrarSalidaVehiculo @matricula
GO
--ENVIAR MATR�CULA A TR�FICO CUANDO NO SON EL�CTRICOS
CREATE OR ALTER PROCEDURE enviarMatriculaATrafico
AS BEGIN
	DECLARE @matricula VARCHAR(MAX)=''
	DECLARE cursorenviarTrafico CURSOR FOR
	SELECT matricula
	FROM dbo.movEntrada
	WHERE enviadoATrafico=1
	OPEN cursorenviarTrafico
	FETCH NEXT FROM cursorenviarTrafico INTO @matricula
	WHILE @@FETCH_STATUS=0
	BEGIN
		INSERT INTO dbo.vehiculosEnTransito(matricula)
		VALUES(@matricula)
	FETCH NEXT FROM cursorenviarTrafico INTO @matricula
	END
	CLOSE cursorenviarTrafico
	DEALLOCATE cursorenviarTrafico
END
GO
EXEC enviarMatriculaATrafico
GO
--ENVIAR AVISOS CUANDO SON ABONADOS
CREATE OR ALTER PROCEDURE enviarAvisosAbonados
AS BEGIN
	DECLARE @matricula VARCHAR(MAX)=''
	DECLARE cursorAvisoAbonados CURSOR FOR
	SELECT dbo.AbonoClientes.matricula
	FROM dbo.AbonoClientes
	WHERE CONVERT(INT, dbo.AbonoClientes.anioMes)<CONVERT(INT ,CONVERT(VARCHAR, YEAR(CURRENT_TIMESTAMP))+'0'+CONVERT(VARCHAR, MONTH(CURRENT_TIMESTAMP))) OR CONVERT(INT, dbo.AbonoClientes.anioMes)<CONVERT(INT ,CONVERT(VARCHAR, YEAR(CURRENT_TIMESTAMP))+''+CONVERT(VARCHAR, MONTH(CURRENT_TIMESTAMP)))
	OPEN cursorAvisoAbonados
	FETCH NEXT FROM cursorAvisoAbonados INTO @matricula
	WHILE @@FETCH_STATUS=0
	BEGIN
		INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
		VALUES(CURRENT_TIMESTAMP, 'INFO', @matricula, 'El abono ha caducado')
	FETCH NEXT FROM cursorAvisoAbonados INTO @matricula
	END
	CLOSE cursorAvisoAbonados
	DEALLOCATE cursorAvisoAbonados
END
GO
EXEC enviarAvisosAbonados
GO
--RECARGA DEL ABONADO MENSUAL
CREATE OR ALTER PROCEDURE realizarRecarga(
@matricula VARCHAR(20)
)
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)=''
    DECLARE @descripcion VARCHAR(MAX)=''
    --------
    --COMPROBAMOS SI LA MATRÍCULA EXISTE
    --LA MATRÍCULA EXISTE
	IF EXISTS(SELECT matricula FROM dbo.movSalida WHERE matricula=@matricula AND dbo.movSalida.fechaSalida IS NULL) BEGIN
        IF EXISTS(SELECT costeServicios FROM dbo.movSalida INNER JOIN dbo.movEntrada ON dbo.movSalida.matricula=dbo.movEntrada.matricula  WHERE dbo.movSalida.matricula=@matricula AND costeServicios=0 AND dbo.movEntrada.vehiculoEnParking=1 AND dbo.movEntrada.enviadoATrafico=0 AND dbo.movEntrada.servicioContratado IN('R', 'T')) BEGIN
           PRINT 'El vehículo con matrícula '+@matricula+' es eléctrico y quiere recarga'
            IF EXISTS(SELECT servicioContratado FROM dbo.movEntrada INNER JOIN dbo.datosCoches ON dbo.movEntrada.matricula=dbo.datosCoches.matricula INNER JOIN dbo.Coches ON dbo.datosCoches.idMatricula=dbo.Coches.id WHERE dbo.movEntrada.matricula=@matricula AND vehiculoEnParking=1 AND enviadoATrafico=0 AND servicioContratado='R' AND UPPER(dbo.Coches.Tipo) LIKE('ELECTRICO%') AND dbo.Coches.Capacidad_de_la_batería_kWh IS NOT NULL) BEGIN
                PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA'
                UPDATE dbo.movSalida
                SET costeServicios=(SELECT CosteKwH FROM dbo.tarifaServicios)*0.8*(SELECT Capacidad_de_la_batería_kWh FROM dbo.Coches INNER JOIN dbo.datosCoches ON dbo.Coches.id=dbo.datosCoches.idMatricula WHERE dbo.datosCoches.matricula=@matricula AND UPPER(dbo.Coches.Tipo) LIKE('ELECTRICO%'))
                WHERE matricula=@matricula AND enviadoATrafico=0
            END
                ELSE IF EXISTS(SELECT servicioContratado FROM dbo.movEntrada INNER JOIN dbo.datosCoches ON dbo.movEntrada.matricula=dbo.datosCoches.matricula INNER JOIN dbo.Coches ON dbo.datosCoches.idMatricula=dbo.Coches.id WHERE dbo.movEntrada.matricula=@matricula AND vehiculoEnParking=1 AND enviadoATrafico=0 AND servicioContratado='T' AND UPPER(dbo.Coches.Tipo) LIKE('ELECTRICO%') AND dbo.Coches.Capacidad_de_la_batería_kWh IS NOT NULL) BEGIN
                    PRINT 'El Coche con matrícula '+@matricula+' ha escogido RECARGA'
                    UPDATE dbo.movSalida
                    SET costeServicios=(SELECT CosteLimpieza FROM dbo.tarifaServicios)+0.8*((SELECT CosteKwH FROM dbo.tarifaServicios)*(SELECT Capacidad_de_la_batería_kWh FROM dbo.Coches INNER JOIN dbo.datosCoches ON dbo.Coches.id=dbo.datosCoches.idMatricula WHERE dbo.datosCoches.matricula=@matricula AND UPPER(dbo.Coches.Tipo) LIKE('ELECTRICO%')))
                     WHERE matricula=@matricula AND enviadoATrafico=0
                END
        

        END
    END
        --LA MATRÍCULA NO EXISTS
        ELSE BEGIN
            SET @nivel='ERROR'
            SET @descripcion='La matrícula no existe'
            INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
            VALUES(@fecha, @nivel, @matricula, @descripcion)
        END
END
GO
DECLARE @matricula VARCHAR(MAX)=(SELECT TOP 1 matricula FROM dbo.datosCoches)
EXEC realizarRecarga @matricula
GO
/*************/
/* TRIGGERS */
/************/
--ENTRADA DE VEHÍCULO
CREATE OR ALTER TRIGGER altaVehiculo
ON dbo.movEntrada
AFTER INSERT
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)='INFO'
    DECLARE @descripcion VARCHAR(MAX)='Ha entrado un nuevo veh�culo al Parking'
    --------
    DECLARE @matricula VARCHAR(MAX)=(SELECT matricula FROM inserted)
    --COMPROBAMOS SI EL VEHÍCULO ESTÁ EN EL PARKING
    IF EXISTS(SELECT vehiculoEnParking FROM dbo.movEntrada WHERE matricula=@matricula AND vehiculoEnParking=1) BEGIN
        --COMPROBAMOS EL TIPO DE VEHÍCULO QUE ES
        --NO ES ELÉCTRICO
        IF EXISTS(SELECT enviadoATrafico FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico=0 AND vehiculoEnParking=1) BEGIN
            PRINT 'El vehículo con matrícula '+@matricula+' es eléctrico'
            --COMPROBAMOS EL SERVICIO CONTRATADO
            --PARKING Y LIMPIEZA
            IF(SELECT UPPER(servicioContratado) FROM inserted WHERE matricula=@matricula) IN ('P', 'L') BEGIN
                PRINT 'Ocupando una plaza Azul'
                UPDATE dbo.ocupacion
                SET plazasLibresAzules=plazasLibresAzules-1
                INSERT INTO dbo.movBarrera(matriculaBarreraEntrada, subirBarreraEntrada, matriculaBarreraSalida, subirBarreraSalida)
                VALUES(@matricula, 1, '???', 0)
                WAITFOR DELAY '00:00:03'
                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                VALUES(@fecha, @nivel, @matricula, @descripcion)
            END
                --RECARGA Y TODO
                ELSE IF(SELECT UPPER(servicioContratado) FROM inserted WHERE matricula=@matricula) IN ('R', 'T')  BEGIN
                    PRINT 'Ocupando una plaza Verde'
                    UPDATE dbo.ocupacion
                    SET plazasLibresVerdes=plazasLibresVerdes-1
                    INSERT INTO dbo.movBarrera(matriculaBarreraEntrada, subirBarreraEntrada, matriculaBarreraSalida, subirBarreraSalida)
                    VALUES(@matricula, 1, '???', 0)
                    WAITFOR DELAY '00:00:03'
                    INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                    VALUES(@fecha, @nivel, @matricula, @descripcion)
                END
        END
            --ES ELÉCTRICO
            ELSE IF EXISTS(SELECT enviadoATrafico FROM dbo.movEntrada WHERE matricula=@matricula AND enviadoATrafico=1 AND vehiculoEnParking=1) BEGIN
                PRINT 'El vehículo con matrícula '+@matricula+' no es eléctrico'
                --COMPROBAMOS EL SERVICIO CONTRATADO
                --PARKING, LIMPIEZA Y TODO
                IF(SELECT UPPER(servicioContratado) FROM inserted WHERE matricula=@matricula) IN ('P', 'L', 'T') BEGIN
                    PRINT 'Ocupando una plaza Azul'
                    UPDATE dbo.ocupacion
                    SET plazasLibresAzules=plazasLibresAzules-1
                    INSERT INTO dbo.movBarrera(matriculaBarreraEntrada, subirBarreraEntrada, matriculaBarreraSalida, subirBarreraSalida)
                    VALUES(@matricula, 1, '???', 0)
                    WAITFOR DELAY '00:00:03'
                    INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                    VALUES(@fecha, @nivel, @matricula, @descripcion)
                END
            END
    END
END
GO
--SALIDA VEHÍCULO
CREATE OR ALTER TRIGGER bajaVehiculo
ON dbo.movSalida
AFTER UPDATE
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)=''
    DECLARE @descripcion VARCHAR(MAX)=''
    --------
    --DATOS A COMPARAR--
    DECLARE @matricula VARCHAR(MAX)=(SELECT top 1 inserted.matricula FROM inserted ORDER BY fechaSalida DESC)
    DECLARE @servicio VARCHAR(MAX)=(SELECT servicioContratado FROM dbo.movEntrada INNER JOIN inserted ON dbo.movEntrada.matricula=inserted.matricula AND dbo.movEntrada.vehiculoEnParking=1)
    --------------------
    --COMPROBAMOS QUE EL VEHÍCULO EXISTS
    --EL VEHÍCULO ESTÁ EN EL PARKING
    IF(SELECT costeServicios FROM inserted WHERE matricula=@matricula)>0 BEGIN
        IF EXISTS(SELECT matricula FROM dbo.movSalida WHERE matricula=@matricula) BEGIN
        PRINT 'El vehículo con matrícula '+@matricula+' está en el Parking'
        --COMPROBAMOS EL TIPO DE VEHÍCULO QUE ES
        --ES ELÉCTRICO
        IF EXISTS(SELECT enviadoATrafico FROM dbo.movSalida WHERE matricula=@matricula AND enviadoATrafico=0) BEGIN
            --COMPROBAMOS EL SERVICIO QUE HA ELEGIDO
            --PARKING Y LIMPIEZA
            IF (UPPER(@servicio))IN ('P', 'L') BEGIN
                SET @nivel='INFO'
                SET @descripcion='Ha salido un veh�culo'
                UPDATE dbo.ocupacion
                SET plazasLibresAzules=plazasLibresAzules+1
                UPDATE dbo.movEntrada
				SET vehiculoEnParking=0
                WHERE matricula=@matricula
                INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                VALUES(@fecha, @nivel, @matricula, @descripcion)
                UPDATE dbo.movBarrera
                SET subirBarreraSalida=1
                WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
                WAITFOR DELAY '00:00:03'
				UPDATE dbo.movBarrera
                SET subirBarreraSalida=0, subirBarreraEntrada=0
                WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
            END
                --RECARGA Y TODO
                ELSE IF(UPPER(@servicio)) IN('R', 'T') BEGIN
                    SET @nivel='INFO'
                    SET @descripcion='Ha salido un veh�culo'
                    UPDATE dbo.ocupacion
                    SET plazasLibresVerdes=plazasLibresVerdes+1
                    UPDATE dbo.movEntrada
				    SET vehiculoEnParking=0
                    WHERE matricula=@matricula
                    INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                    VALUES(@fecha, @nivel, @matricula, @descripcion)
                    UPDATE dbo.movBarrera
                    SET subirBarreraSalida=1
                    WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
                    WAITFOR DELAY '00:00:03'
					UPDATE dbo.movBarrera
					SET subirBarreraSalida=0, subirBarreraEntrada=0
					WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
                END
        END
            --NO ES ELÉCTRICO
            ELSE IF EXISTS(SELECT enviadoATrafico FROM dbo.movSalida WHERE matricula=@matricula AND enviadoATrafico=1) BEGIN
                --COMPROBAMOS EL SERVICIO QUE HA ELEGIDO
                --PARKING, LIMPIEZA Y TODO
                IF(UPPER(@servicio)) IN('P', 'L', 'T') BEGIN
                    SET @nivel='INFO'
                    SET @descripcion='Ha salido un veh�culo'
                    UPDATE dbo.ocupacion
                    SET plazasLibresAzules=plazasLibresAzules+1
                    UPDATE dbo.movEntrada
				    SET vehiculoEnParking=0
                    WHERE matricula=@matricula
                    INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
                    VALUES(@fecha, @nivel, @matricula, @descripcion)
                    UPDATE dbo.movBarrera
                    SET subirBarreraSalida=1
                    WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
                    WAITFOR DELAY '00:00:03'
					UPDATE dbo.movBarrera
					SET subirBarreraSalida=0, subirBarreraEntrada=0
					WHERE matriculaBarreraSalida=@matricula AND subirBarreraSalida=0
                END
            END
    END
        --EL VEHÍCULO NO ESTÁ EN EL PARKING
        ELSE BEGIN
            PRINT 'El vehículo con matrícula '+@matricula+' no está en el Parking'
            SET @nivel='ERROR'
            SET @descripcion='El vehículo no está en el Parking'
            INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
            VALUES(@fecha, @nivel, @matricula, @descripcion)
        END
    END
END
GO
--TLOG CUANDO SE ENVIA A TR�FICO
CREATE OR ALTER TRIGGER aTrafico
ON dbo.vehiculosEnTransito
AFTER INSERT
AS BEGIN
    --TLOG--
    DECLARE @fecha DATETIME=(CURRENT_TIMESTAMP)
    DECLARE @nivel VARCHAR(MAX)='INFO'
    DECLARE @matricula VARCHAR(MAX)=(SELECT matricula FROM inserted)
    DECLARE @descripcion VARCHAR(MAX)='Se ha movido un veh�culo a tr�fico'
    --------
    INSERT INTO dbo.tlog(fecha, nivel, matricula, descripcion)
	VALUES(@fecha, @nivel, @matricula, @descripcion)
END
/**************/
/* VER TABLAS */
/**************/
SELECT * FROM dbo.Coches
SELECT * FROM dbo.datosCoches
SELECT * FROM dbo.ocupacion
SELECT * FROM dbo.AbonoClientes
SELECT * FROM dbo.tarifaServicios
--DATOS--
SELECT * FROM dbo.vehiculosEnTransito
SELECT * FROM dbo.movBarrera
SELECT * FROM dbo.movEntrada
SELECT * FROM dbo.movSalida
------
SELECT * FROM dbo.tlog
/****************/
/* BACKUP DATOS */
/****************/
UPDATE dbo.ocupacion
SET plazasLibresAzules=1500
UPDATE dbo.ocupacion
SET plazasLibresVerdes=500
TRUNCATE TABLE dbo.vehiculosEnTransito
TRUNCATE TABLE dbo.movBarrera
TRUNCATE TABLE dbo.movEntrada
TRUNCATE TABLE dbo.movSalida
TRUNCATE TABLE dbo.tlog