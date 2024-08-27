-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 27-08-2024 a las 19:32:49
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `casadb`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `agregarConsumo` (IN `inPlaca` VARCHAR(10), IN `inOperador` VARCHAR(100), IN `inDespachador` VARCHAR(100), IN `inFechaDespacho` DATETIME, IN `inHorometrajeActual` DOUBLE, IN `inKilometrajeActual` DOUBLE, IN `inGalones` DOUBLE)   BEGIN
    DECLARE horometrajeDif DOUBLE;
    DECLARE kilometrajeDif DOUBLE;
    DECLARE rendimiento DOUBLE;
    DECLARE currentHorometraje DOUBLE DEFAULT NULL;
    DECLARE currentKilometraje DOUBLE DEFAULT NULL;
    DECLARE mensaje VARCHAR(100);

    DECLARE previousHorometraje DOUBLE;
    DECLARE previousKilometraje DOUBLE;
    DECLARE previousGalones DOUBLE;

    DECLARE maxConsum DOUBLE;
    DECLARE minConsum DOUBLE;

    DECLARE newIdDespacho INT;

    -- Obtener los valores actuales de horómetro y kilometraje del vehículo
    SELECT horometraje, kilometraje INTO currentHorometraje, currentKilometraje 
    FROM equipo 
    WHERE placa = inPlaca;

    -- Obtener los valores de consumo máximo y mínimo
    SELECT mo.maxConsum, mo.minConsum INTO maxConsum, minConsum 
    FROM equipo eq
    INNER JOIN modelo mo ON mo.idModelo = eq.idModelo
    WHERE eq.placa = inPlaca;

    -- Validación de valores actuales
    IF currentHorometraje IS NULL OR currentKilometraje IS NULL THEN
        -- Ingresar el nuevo consumo como primer consumo (idEstadoConsum 4)
        INSERT INTO despacho (idOperador, fechaDespacho)
        VALUES (inDespachador, inFechaDespacho);
        SET newIdDespacho = LAST_INSERT_ID();

        INSERT INTO consumo (idDespacho, nombreOperador, placa, idEstadoConsum, horometraje, kilometraje, galones, rendimiento)
        VALUES (newIdDespacho, inOperador, inPlaca, 4, inHorometrajeActual, inKilometrajeActual, inGalones, 0);

        -- Actualizar los valores actuales en la tabla equipo
        UPDATE equipo
        SET horometraje = inHorometrajeActual, kilometraje = inKilometrajeActual
        WHERE placa = inPlaca;

        SET mensaje = 'Primer consumo ingresado correctamente';
    ELSE
        IF currentHorometraje = inHorometrajeActual OR currentKilometraje = inKilometrajeActual THEN
            -- Lanzar error
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Horómetro o kilometraje actual es igual al ingresado';
        ELSE
            -- Verificar si se encuentran registros anteriores
            IF inHorometrajeActual < currentHorometraje OR inKilometrajeActual < currentKilometraje THEN
                -- Obtener los valores del anterior consumo con estadoCodigo 4
                SELECT horometraje, kilometraje, galones INTO previousHorometraje, previousKilometraje, previousGalones 
                FROM consumo
                WHERE placa = inPlaca AND idEstadoConsum = 4 
                ORDER BY horometraje DESC, kilometraje DESC LIMIT 1;

                -- Calcular rendimiento entre el nuevo consumo y el anterior consumo con estadoCodigo 4
                SET horometrajeDif = IFNULL(ROUND(currentHorometraje - inHorometrajeActual, 2), NULL);
                SET kilometrajeDif = IFNULL(ROUND(currentKilometraje - inKilometrajeActual, 2), NULL);

                IF horometrajeDif IS NOT NULL AND horometrajeDif > 0 THEN
                    SET rendimiento = ROUND(previousGalones / horometrajeDif, 2);
                ELSEIF kilometrajeDif IS NOT NULL AND kilometrajeDif > 0 THEN
                    SET rendimiento = ROUND(previousGalones / kilometrajeDif, 2);
                ELSE
                    SET rendimiento = 0;
                END IF;

                -- Actualizar el estado del anterior consumo de estadoCodigo 4 con el rendimiento calculado
                UPDATE consumo
                SET idEstadoConsum = CASE
                    WHEN rendimiento > maxConsum THEN 3
                    WHEN rendimiento < minConsum THEN 3
                    ELSE 1
                END,
                rendimiento = rendimiento
                WHERE placa = inPlaca AND horometraje = previousHorometraje AND kilometraje = previousKilometraje AND idEstadoConsum = 4;

                -- Ingresar el nuevo consumo anterior con estado "Indeterminado" (idEstadoConsum 4)
                INSERT INTO despacho (idOperador, fechaDespacho)
                VALUES (inDespachador, inFechaDespacho);
                SET newIdDespacho = LAST_INSERT_ID();

                INSERT INTO consumo (idDespacho, nombreOperador, placa, idEstadoConsum, horometraje, kilometraje, galones, rendimiento)
                VALUES (newIdDespacho, inOperador, inPlaca, 4, inHorometrajeActual, inKilometrajeActual, inGalones, 0);

                SET mensaje = 'Consumo anterior actualizado y nuevo consumo ingresado correctamente';
            ELSE
                -- Calcular las diferencias de horómetros y kilómetros
                SET horometrajeDif = IFNULL(ROUND(inHorometrajeActual - currentHorometraje, 2), NULL);
                SET kilometrajeDif = IFNULL(ROUND(inKilometrajeActual - currentKilometraje, 2), NULL);

                -- Calcular rendimiento
                IF horometrajeDif IS NOT NULL AND horometrajeDif > 0 THEN
                    SET rendimiento = ROUND(inGalones / horometrajeDif, 2);
                ELSEIF kilometrajeDif IS NOT NULL AND kilometrajeDif > 0 THEN
                    SET rendimiento = ROUND(inGalones / kilometrajeDif, 2);
                ELSE
                    SET rendimiento = 0;
                END IF;

                -- Insertar el nuevo despacho y consumo
                INSERT INTO despacho (idOperador, fechaDespacho)
                VALUES (inDespachador, inFechaDespacho);
                SET newIdDespacho = LAST_INSERT_ID();

                INSERT INTO consumo (idDespacho, nombreOperador, placa, idEstadoConsum, horometraje, kilometraje, galones, rendimiento)
                VALUES (newIdDespacho, inOperador, inPlaca, 
                    CASE
                        WHEN rendimiento > maxConsum THEN 3
                        WHEN rendimiento < minConsum THEN 3
                        ELSE 1
                    END, inHorometrajeActual, inKilometrajeActual, inGalones, rendimiento);

                -- Actualizar los valores actuales si el nuevo consumo es posterior
                IF inHorometrajeActual > currentHorometraje THEN
                    UPDATE equipo
                    SET horometraje = inHorometrajeActual
                    WHERE placa = inPlaca;
                END IF;

                IF inKilometrajeActual > currentKilometraje THEN
                    UPDATE equipo
                    SET kilometraje = inKilometrajeActual
                    WHERE placa = inPlaca;
                END IF;

                SET mensaje = 'Datos procesados correctamente';
            END IF;
        END IF;
    END IF;

    -- Devolver el resultado
    SELECT * FROM consumo WHERE placa = inPlaca ORDER BY horometraje;
    SELECT mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesarConsumos` (IN `inPlaca` VARCHAR(20), IN `inHorometrajeActual` DOUBLE, IN `inKilometrajeActual` DOUBLE, IN `inGalones` DOUBLE, IN `inOperador` TEXT)   BEGIN
    DECLARE horometrajeDif DOUBLE;
    DECLARE kilometrajeDif DOUBLE;
    DECLARE rendimiento DOUBLE;
    DECLARE estado INT;
    DECLARE currentHorometraje DOUBLE;
    DECLARE currentKilometraje DOUBLE;
    DECLARE mensaje VARCHAR(100);

    -- Obtener los valores actuales de horómetro y kilometraje del vehículo
    SELECT horometraje, kilometraje INTO currentHorometraje, currentKilometraje FROM equipo WHERE placa = inPlaca;

    -- Validación de valores actuales
    IF currentHorometraje >= inHorometrajeActual OR currentKilometraje >= inKilometrajeActual THEN
        -- Crear una tabla temporal con el resultado de valores inválidos
        CREATE TEMPORARY TABLE temp_consumosProcesados AS
        SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
        mo.descripcion AS 'modelo', eq.placa, 
        inOperador AS operador,
        inHorometrajeActual AS horometraje, 
        inKilometrajeActual AS kilometraje,
        0 AS rendimiento,
        5 AS estadoCodigo,
        'Inválido' AS estadoDescripcion,
        currentHorometraje AS currentHorometraje,
        currentKilometraje AS currentKilometraje
        FROM equipo eq 
        INNER JOIN marca ma ON eq.idMarca = ma.idMarca
        INNER JOIN modelo mo ON eq.idModelo = mo.idModelo
        WHERE eq.placa = inPlaca;

        SET mensaje = 'Los valores ingresados son iguales a los valores actuales';

    ELSE
        -- Calcular las diferencias de horómetros y kilómetros
        SET horometrajeDif = IFNULL(ROUND((inHorometrajeActual - currentHorometraje), 2), NULL);
        SET kilometrajeDif = IFNULL(ROUND((inKilometrajeActual - currentKilometraje), 2), NULL);

        -- Verificar si se encontraron registros para calcular rendimiento
        IF horometrajeDif IS NULL AND kilometrajeDif IS NULL THEN
            CREATE TEMPORARY TABLE temp_consumosProcesados AS
            SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
            mo.descripcion AS 'modelo', eq.placa, 
            inOperador AS operador,
            inHorometrajeActual AS horometraje, 
            inKilometrajeActual AS kilometraje,
            0 AS rendimiento,
            4 AS estadoCodigo,
            'Indeterminado' AS estadoDescripcion,
            currentHorometraje AS currentHorometraje,
            currentKilometraje AS currentKilometraje
            FROM equipo eq 
            INNER JOIN marca ma ON eq.idMarca = ma.idMarca
            INNER JOIN modelo mo ON eq.idModelo = mo.idModelo
            WHERE eq.placa = inPlaca;

            SET mensaje = 'No se pudieron calcular las diferencias de horómetro y/o kilómetro';

        ELSE
            -- Calcular rendimiento
            IF horometrajeDif IS NOT NULL THEN
                SET rendimiento = ROUND(inGalones / horometrajeDif, 2);
            ELSEIF kilometrajeDif IS NOT NULL THEN
                SET rendimiento = ROUND(inGalones / kilometrajeDif, 2);
            ELSE
                SET rendimiento = 0;
            END IF;

            CREATE TEMPORARY TABLE temp_consumosProcesados AS
            SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
            mo.descripcion AS 'modelo', eq.placa, 
            inOperador AS operador,
            inHorometrajeActual AS horometraje, 
            inKilometrajeActual AS kilometraje,
            rendimiento AS rendimiento,
            CASE
                WHEN rendimiento > mo.maxConsum THEN 3
                WHEN rendimiento < mo.minConsum THEN 3
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento > -2 THEN 2
                WHEN rendimiento < mo.maxConsum THEN 1
            END AS estadoCodigo,
            CASE
                WHEN rendimiento > mo.maxConsum THEN 'Desmedido'
                WHEN rendimiento < mo.minConsum THEN 'Desmedido'
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento > -2 THEN 'Sospechoso'
                WHEN rendimiento < mo.maxConsum THEN 'Regular'
            END AS estadoDescripcion,
            currentHorometraje AS currentHorometraje,
            currentKilometraje AS currentKilometraje
            FROM equipo eq 
            INNER JOIN marca ma ON eq.idMarca = ma.idMarca
            INNER JOIN modelo mo ON eq.idModelo = mo.idModelo
            WHERE eq.placa = inPlaca;

            SET mensaje = 'Datos procesados correctamente';

            -- Actualizar los valores actuales si el nuevo consumo es anterior
            IF inHorometrajeActual < currentHorometraje THEN
                UPDATE equipo
                SET horometraje = inHorometrajeActual
                WHERE placa = inPlaca;
            END IF;

            IF inKilometrajeActual < currentKilometraje THEN
                UPDATE equipo
                SET kilometraje = inKilometrajeActual
                WHERE placa = inPlaca;
            END IF;
        END IF;
    END IF;

    SELECT *, mensaje AS mensaje FROM temp_consumosProcesados;
    DROP TEMPORARY TABLE IF EXISTS temp_consumosProcesados;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `consumo`
--

CREATE TABLE `consumo` (
  `idConsumo` int(11) NOT NULL,
  `idDespacho` int(11) NOT NULL,
  `idOperador` int(11) DEFAULT NULL,
  `placa` varchar(20) NOT NULL,
  `idEstadoConsum` int(11) DEFAULT NULL,
  `nombreOperador` text DEFAULT NULL,
  `horometraje` double DEFAULT NULL,
  `inHorometraje` double DEFAULT NULL,
  `kilometraje` double DEFAULT NULL,
  `inKilometraje` double DEFAULT NULL,
  `galones` double DEFAULT NULL,
  `rendimiento` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `consumo`
--

INSERT INTO `consumo` (`idConsumo`, `idDespacho`, `idOperador`, `placa`, `idEstadoConsum`, `nombreOperador`, `horometraje`, `inHorometraje`, `kilometraje`, `inKilometraje`, `galones`, `rendimiento`) VALUES
(19, 91, NULL, 'ANM-804', 1, '', 13663.66, NULL, 245148.2, NULL, 28.1, 4.27),
(20, 92, NULL, 'ANM-804', 4, 'Beto López', 13657.08, NULL, 244916.2, NULL, 0, 0),
(27, 99, NULL, 'ANM-797', 3, 'Beto López', 14234.6, 14232.35, 272298.6, 272183.6, 20, 8.89),
(28, 99, NULL, 'ANM-804', 1, NULL, 13663.66, 13657.08, 245148.2, 244916.2, 28.1, 4.27),
(29, 99, NULL, 'ANM-805', 4, NULL, 13663.66, NULL, 245148.2, NULL, 28.1, 0),
(30, 99, NULL, 'ANM-806', 4, NULL, 12589.7, NULL, 257832.2, NULL, 12.2, 0),
(31, 99, NULL, 'ANM-803', 4, '', 13663.66, NULL, 245148.2, NULL, 23.2, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `despacho`
--

CREATE TABLE `despacho` (
  `idDespacho` int(11) NOT NULL,
  `idOperador` int(11) NOT NULL,
  `fechaDespacho` datetime DEFAULT NULL,
  `totalDespacho` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `despacho`
--

INSERT INTO `despacho` (`idDespacho`, `idOperador`, `fechaDespacho`, `totalDespacho`) VALUES
(91, 1, '2024-07-09 00:00:00', NULL),
(92, 1, '2024-04-10 00:00:00', NULL),
(99, 1, '2024-07-08 00:00:00', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `equipo`
--

CREATE TABLE `equipo` (
  `placa` varchar(20) NOT NULL,
  `descripcion` varchar(200) DEFAULT NULL,
  `idModelo` int(11) NOT NULL,
  `idMarca` int(11) NOT NULL,
  `idFrente` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1,
  `horometraje` double DEFAULT NULL,
  `kilometraje` double DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `equipo`
--

INSERT INTO `equipo` (`placa`, `descripcion`, `idModelo`, `idMarca`, `idFrente`, `estado`, `horometraje`, `kilometraje`, `updated_at`) VALUES
('´0853', 'FRESADORA', 138, 61, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('0130', 'GRUPO ELÉCTROGENO', 125, 57, NULL, 1, NULL, NULL, '2024-06-28 03:33:23'),
('0405A', 'GRUPO ELÉCTROGENO', 131, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1047', 'RODILLO TANDEM AUTOPORPULSADO', 15, 7, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1057', 'GRUPO ELÉCTROGENO', 29, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1085', 'PILOTEADORA', 108, 46, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1102', 'EXCAVADORA', 43, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1104', 'GRUPO ELÉCTROGENO', 132, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1114', 'RODILLO LISO ', 13, 7, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1124', 'GRUPO ELÉCTROGENO', 130, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('117', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('12', 'TRACTOR AGRICOLA', 140, 67, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1228', 'PAVIMENTADORA SOBRE ORUGAS', 120, 55, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('128', 'CARGADOR FRONTAL', 140, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1327', 'RODILLO LISO AUTOPORPULSADO', 14, 7, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1394', 'GRUPO ELÉCTROGENO', 35, 12, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('14', 'RODILLO LISO DOBLE ROLA', 4, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('143', 'MOTONIVELADORA', 27, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1479', 'TRACTOR SOBRE ORUGA', 79, 29, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1585', 'TRACTOR SOBRE ORUGA', 140, 69, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1637', 'RODILLO TANDEM AUTOPORPULSADO', 76, 28, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('17', 'RODILLO TANDEM AUTOPORPULSADO', 4, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('171', 'PAVIMENTADORA SOBRE ORUGAS', 119, 55, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1718', 'PAVIMENTADORA SOBRE ORUGAS', 133, 55, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1731', 'RODILLO NEUMATICO AUTOPROPULSADO', 5, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('177', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1776', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1804', 'RODILLO', 140, 15, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('1834', 'TRACTOR SOBRE ORUGA', 23, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('194', 'FRESADORA DE ASFALTO', 135, 61, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1980', 'EXCAVADORA SOBRE ORUGAS', 52, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1993', 'MINICARGADOR ', 20, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1995', 'EXCAVADORA', 52, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('1996', 'EXCAVADORA SOBRE ORUGAS', 52, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2080', 'RODILLO NEUMATICO', 140, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('216', 'CARGADOR FRONTAL SOBRE LLANTAS', 49, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('2163', 'RODILLO', 6, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('2167', 'RODILLO LISO VIBRATORIO MANUAL   AF', 3, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2180', 'EXCAVADORA SOBRE ORUGAS', 52, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2196', 'COMPRESORA', 140, 2, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('2197', 'RODILLO LISO AUTOPORPULSADO', 3, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2198', 'RODILLO LISO AUTOPORPULSADO', 3, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2204', 'TRACTOR SOBRE ORUGA', 21, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('2241', 'TORRES DE ILUMINACION', 81, 31, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2244', 'TORRES DE ILUMINACION', 81, 31, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2285', 'EXCAVADORA SOBRE ORUGAS', 52, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2313', 'GRUPO ELÉCTROGENO', 140, 30, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2388', 'MONTACARGA', 67, 21, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('2420', 'GRUPO ELÉCTROGENO', 34, 12, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('2577', 'MOTONIVELADORA', 27, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('258', 'CARGADOR FRONTAL SOBRE LLANTAS', 48, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('2719', 'RODILLO BERMERO', 134, 59, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('29', 'CARGADOR FRONTAL', 140, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('300', 'TRACTOR SOBRE ORUGA', 23, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('3000', 'RETROEXCAVADORA SOBRE LLANTAS', 17, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('3159', 'MOTONIVELADORA', 27, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('316', 'RODILLO TANDEM AUTOPORPULSADO', 66, 20, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('32-EX', 'EXCAVADORA SOBRE ORUGAS', 45, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('32-MO', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('325', 'PAVIMENTADORA SOBRE ORUGAS', 22, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('3482', 'GRUA TELESCOPICA', 65, 19, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('357', 'GRUA CELOSIA', 11, 5, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('3597', 'MOTONIVELADORA', 19, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('3601', 'MOTONIVELADORA', 19, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('368', 'CARGADOR FRONTAL SOBRE LLANTAS', 46, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('370', 'RODILLO LISO AUTOPORPULSADO', 25, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('3772', 'CARGADOR FRONTAL', 47, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('379', 'CARGADOR FRONTAL SOBRE LLANTAS', 50, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('38118010117', 'COMPRESORA', 112, 49, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('3886', 'EXCAVADORA NEUMATICA', 140, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('3993', 'BOMBA DE CONCRETO', 140, 63, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('4057', 'GRUPO ELÉCTROGENO', 140, 44, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('4070', 'RODILLO LISO AUTOPORPULSADO', 26, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4188', 'TORRES DE ILUMINACION', 115, 53, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('420', 'CARGADOR FRONTAL SOBRE LLANTAS', 48, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('4214', 'TORRES DE ILUMINACION', 38, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4215', 'TORRES DE ILUMINACION', 38, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4217', 'TORRES DE ILUMINACION', 38, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4219', 'TORRES DE ILUMINACION', 38, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4293', 'CARGADOR FRONTAL SOBRE LLANTAS', 51, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('4296', 'TORRES DE ILUMINACION', 38, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4377', 'CARGADOR FRONTAL SOBRE LLANTAS', 51, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('438', 'CARGADOR FRONTAL SOBRE LLANTAS', 30, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('4516', 'MOTONIVELADORA', 18, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4536', 'GRUPO ELÉCTROGENO', 97, 40, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('4537', 'GRUPO ELÉCTROGENO', 97, 40, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('454', 'MAQUINA DE HINCAR POSTES', 54, 16, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('461', 'MAQUINA DE HINCAR POSTES', 54, 16, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4672', 'RODILLO BERMERO', 53, 15, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('489', 'RECICLADORA DE ASFALTO', 137, 61, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('4972', 'GRUPO ELÉCTROGENO', 36, 13, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5100', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5113', 'GRUPO ELÉCTROGENO', 124, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('5116', 'GRUPO ELÉCTROGENO', 98, 40, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('518', 'EXCAVADORA', 44, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5306', 'EXCAVADORA SOBRE ORUGAS', 45, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5456', 'EXCAVADORA', 40, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5491', 'EXCAVADORA NEUMATICA', 41, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('55', 'RECICLADORA DE ASFALTO', 136, 61, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5545', 'GRUPO ELÉCTROGENO', 100, 40, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5576', 'MOTONIVELADORA', 78, 29, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5586', 'MINICARGADOR ', 39, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5649', 'MOTONIVELADORA', 140, 29, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('5744', 'EXCAVADORA', 140, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('58', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5858', 'MOTONIVELADORA', 77, 29, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5920', 'MOTONIVELADORA', 78, 29, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('5954', 'GRUPO ELÉCTROGENO', 106, 44, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('6046', 'COMPRESORA NEUMATICA', 7, 2, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('615', 'GRUPO ELÉCTROGENO', 42, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('616', 'CARGADOR FRONTAL SOBRE LLANTAS', 48, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('618', 'TRACTOR SOBRE ORUGA', 24, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('62', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('625', 'PAVIMENTADORA SOBRE ORUGAS', 114, 52, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('642', 'EXCAVADORA SOBRE ORUGAS', 45, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('6637', 'MOTONIVELADORA', 101, 41, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('6799', 'RETROEXCAVADORA SOBRE LLANTAS', 16, 8, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('717', 'EXCAVADORA', 140, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('74', 'MOTOSOLDADORA', 95, 38, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('772', 'RODILLO LISO AUTOPORPULSADO', 1, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('780', 'RODILLO LISO AUTOPORPULSADO', 2, 1, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('9', 'COMPRESORA NEUMATICA', 111, 49, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('A0B-929', 'CAMION BARANDA', 122, 56, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('A0H-858', 'CAMION PIME', 94, 37, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('A0N-841', 'CAMION BARANDA', 122, 56, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('A3H-824', 'CAMION ABASTECEDOR DE COMBUSTIBLE', 93, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('A4L-934', 'CAMIONETA 4X4 CABINA DOBLE', 82, 32, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('A6N-875', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('A8J-906', 'CAMION HORMIGONERO', 86, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AAE-721', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AAE-725', 'CISTERNA DE AGUA', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AAP-767', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AAQ-713', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ACB-770', 'CAMION ABASTECEDOR DE COMBUSTIBLE', 58, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ACK-732', 'CAMION ABASTECEDOR DE COMBUSTIBLE', 58, 18, NULL, 1, NULL, NULL, '2024-06-27 15:30:18'),
('AFA-857', 'CAMION VIGA', 110, 68, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AFN-881', 'CAMION BARANDA', 68, 22, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AFO-802', 'CAMION BARANDA', 68, 22, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AFP-812', 'CAMION BARANDA', 68, 22, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AFP-822', 'CAMION BARANDA', 68, 22, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AHK-856', 'MINIBUS', 103, 42, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AHO-790', 'CAMION VIGA', 140, 68, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AHY-754', 'CAMIÓN BOMBA HORMIGONERO', 123, 56, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('AJS-907', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AKJ-244', 'MINIBUS', 74, 26, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ALF-765', 'COMBI PIME', 55, 17, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMO-903', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMW-828', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMW-835', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AMW-876', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMW-878', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMW-879', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AMW-888', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:19:44'),
('AMW-900', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AMW-914', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:19:44'),
('AMW-917', 'VOLQUETE', 129, 57, NULL, 1, NULL, NULL, '2024-06-27 15:19:44'),
('AMW-918', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AMX-745', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AMX-747', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AMX-882', 'CAMION', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ANF-791', 'CAMIONETA 4X4 CABINA DOBLE', 32, 11, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANM-797', 'VOLQUETE', 127, 57, NULL, 1, 14234.6, 272298.6, '2024-07-10 00:31:24'),
('ANM-798', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANM-800', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:17:54'),
('ANM-801', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANM-802', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANM-803', 'VOLQUETE', 127, 57, NULL, 1, 13663.66, 245148.2, '2024-07-10 00:31:24'),
('ANM-804', 'VOLQUETE', 127, 57, NULL, 1, 13663.66, 245148.2, '2024-07-10 00:31:24'),
('ANM-805', 'VOLQUETE', 127, 57, NULL, 1, 13663.66, 245148.2, '2024-07-10 00:31:24'),
('ANM-806', 'VOLQUETE', 127, 57, NULL, 1, 12589.7, 257832.2, '2024-07-10 00:31:24'),
('ANM-807', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:17:54'),
('ANM-808', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:17:54'),
('ANM-810', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:17:54'),
('ANM-811', 'VOLQUETE', 127, 57, NULL, 1, NULL, NULL, '2024-06-27 15:17:54'),
('ANM-835', 'VOLQUETE', 140, 57, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ANM-891', 'CAMION BARANDA', 68, 22, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ANV-935', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANV-938', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANW-723', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANW-740', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANW-771', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ANW-773', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANW-858', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANW-923', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ANW-935', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANX-726', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANX-727', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANX-756', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANX-892', 'CAMION MIXER', 121, 56, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ANZ-804', 'VOLQUETE', 90, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('APG-894', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('APH-787', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('APH-840', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-754', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-789', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-800', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-846', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-945', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-946', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('API-948', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('APJ-830', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('APJ-883', 'VOLQUETE', 87, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ASF-832', 'CAMION PIME', 140, 65, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('ATF-700', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('ATJ-753', 'CAMION PIME', 73, 26, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('AYT-788', 'CAMIONETA', 140, 11, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('AYU-856', 'CAMIONETA', 33, 11, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('B2J-864', 'CAMION ABASTECEDOR DE COMBUSTIBLE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('B4C-738', 'COMBI PIME', 117, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('B4M-804', 'MICROPAVIMENTADOR', 71, 24, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('B4R-929', 'CAMION PIME', 96, 39, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('B5S-885', 'CAMION', 75, 27, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('B8S-410', 'COMBI PIME', 69, 23, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BFO-748', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BFO-750', 'CAMIONETA 4X4 CABINA DOBLE', 84, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('BFO-843', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BHR-889', 'CAMION', 9, 3, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BJR-899', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BJS-907', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BKE-748', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BKE-928', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BOI-770', 'COMBI PIME', 140, 17, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('BXE-711', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXE-931', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXF-820', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXF-821', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXF-826', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXF-856', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXJ-726', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXJ-853', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXX-717', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('BXX-811', 'CAMIONETA', 140, 34, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('C0C-923', 'CAMION', 139, 62, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C1O-767', 'CAMION PIME', 113, 51, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('C1Y-883', 'CAMION PIME', 113, 51, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('C3K-884', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C7E-736', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('C7G-818', 'TRACTO REMOLCADOR', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C7G-819', 'CAMABAJA', 140, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C7K-486', 'COMBI PIME', 140, 66, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C7R-893', 'CISTERNA DE AGUA', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C8F-841', 'CAMION PIME', 140, 39, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('C8V-342', 'MINIBUS', 74, 26, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('C9Z-909', 'CAMION PIME', 140, 23, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('CALDERO BARBER GREE ', 'PLANTA DE ASFALTO EN CALIENTE', 10, 4, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('CALDERO CIBER', 'CALDERO CIBER', 140, 70, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('CIB-311', 'COMBI PIME', 69, 23, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D3G-928', 'CISTERNA DE AGUA', 91, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D3H-802', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D3H-806', 'CISTERNA DE AGUA', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D3H-812', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D3Z-788', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D3Z-789', 'VOLQUETE', 88, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D4A-726', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D4G-719', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D4N-776', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D4T-873', 'CISTERNA DE AGUA', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D4T-877', 'CISTERNA DE AGUA', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D5M-774', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D5M-775', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D7D-229', 'COMBI PIME', 12, 6, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D7M-755', 'CAMIONETA', 85, 35, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D7V-762', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D7Y-299', 'COMBI PIME', 140, 70, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D7Y-799', 'COMBI PIME', 57, 17, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D7Y-921', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D8F-795', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D8I-750', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D8M-714', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('D8M-926', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D8N-828', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('D8O-897', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('E0453', 'MONTACARGA', 28, 9, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('E1093', 'GRUPO ELÉCTROGENO', 99, 40, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('E1616', 'COMPRESORA NEUMATICA', 8, 2, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('E3556', 'GRUPO ELÉCTROGENO', 105, 43, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('EO615', 'GRUPO ELÉCTROGENO', 37, 14, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('EUD-874', 'AMBULANCIA', 83, 33, NULL, 1, NULL, NULL, '2024-06-27 15:02:25'),
('F0J-930', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F0K-708', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F0K-721', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F0K-744', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F0L-905', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F0N-925', 'CAMIONETA 4X4 CABINA DOBLE', 102, 42, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F0O-841', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2J-738', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F2J-744', 'VOLQUETE', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2J-745', 'CAMION IMPRIMADOR', 58, 18, NULL, 1, NULL, NULL, '2024-06-27 15:30:18'),
('F2M-484', 'MINIBUS', 70, 23, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2M-709', 'TRACTO REMOLCADOR', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2M-719', 'CAMABAJA', 62, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2M-727', 'TRACTO REMOLCADOR', 140, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F2M-729', 'CISTERNA DE AGUA', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2M-745', 'TRACTO REMOLCADOR', 140, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F2M-754', 'TRACTO REMOLCADOR', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F2M-755', 'CAMABAJA', 59, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F2M-769', 'CAMABAJA', 140, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F2M-775', 'CISTERNA DE AGUA', 61, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F3B-836', 'COMBI PIME', 56, 17, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F3L-799', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F4B-848', 'CISTERNA DE AGUA', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F4B-849', 'CAMION IMPRIMADOR', 58, 18, NULL, 1, NULL, NULL, '2024-06-27 15:30:18'),
('F4B-871', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F4B-874', 'CISTERNA DE AGUA', 92, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F4C-763', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F5L-915', 'CAMIONETA 4X4 CABINA DOBLE', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F6P-867', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F7F-889', 'CAMION HORMIGONERO', 63, 18, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('F7P-721', 'CAMION PIME', 113, 51, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9V-719', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9V-852', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9V-855', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9V-859', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9W-832', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9W-852', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9W-871', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9W-894', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9W-899', 'VOLQUETE', 89, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('F9X-723', 'VOLQUETE', 140, 36, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('HIB-726', 'COMBI PIME', 140, 42, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('LAVADO PIEZAS - CAÑE', 'CAÑETE', 31, 10, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('LAVADO PIEZAS - PISC', 'PISCO', 107, 45, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('M4E-893', 'CAMION', 140, 25, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('P4C-911', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('PEA I', 'PEA CALDERO 1', 140, 70, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('PEA II', 'PEA CALDERO 11', 140, 70, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('TAS-819', 'CAMIONETA', 116, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('V5I-772', 'TRACTO REMOLCADOR', 140, 24, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('W2V-189', 'COMBI PIME', 104, 42, NULL, 1, NULL, NULL, '2024-06-27 15:02:27'),
('X5K-956', 'COMBI PIME', 118, 54, NULL, 1, NULL, NULL, '2024-06-27 15:02:26'),
('Z1H-918', 'CAMION BARANDA', 109, 47, NULL, 1, NULL, NULL, '2024-06-27 15:02:26');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estadoconsum`
--

CREATE TABLE `estadoconsum` (
  `idEstado` int(11) NOT NULL,
  `descripcion` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `estadoconsum`
--

INSERT INTO `estadoconsum` (`idEstado`, `descripcion`) VALUES
(1, 'Regular'),
(2, 'Sospechoso'),
(3, 'Desmedido'),
(4, 'Indeterminado'),
(5, 'Inválido'),
(6, 'Nuevo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `frente`
--

CREATE TABLE `frente` (
  `idFRente` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `estado` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `marca`
--

CREATE TABLE `marca` (
  `idMarca` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `marca`
--

INSERT INTO `marca` (`idMarca`, `descripcion`) VALUES
(1, 'AMMANN\r'),
(2, 'ATLAS COPCO\r'),
(3, 'BARANDA\r'),
(4, 'BARBER GREENE\r'),
(5, 'BAUER MACHINE\r'),
(6, 'BAW\r'),
(7, 'BOMAG\r'),
(8, 'CASE\r'),
(9, 'CATERPILLAR\r'),
(10, 'CAÑETE'),
(11, 'CHEVROLET\r'),
(12, 'CUMMINS\r'),
(13, 'CUMMINS \r'),
(14, 'DOOSAN\r'),
(15, 'DYNAPAC\r'),
(16, 'FAGA\r'),
(17, 'FOTON\r'),
(18, 'FREIGHTLINER\r'),
(19, 'GROVE\r'),
(20, 'HAMM\r'),
(21, 'HANGCHA\r'),
(22, 'HINO\r'),
(23, 'HYUNDAI\r'),
(24, 'INTERNATIONAL\r'),
(25, 'ISUZU\r'),
(26, 'JAC\r'),
(27, 'JBC\r'),
(28, 'JCB VIBROMAX\r'),
(29, 'KOMATSU\r'),
(30, 'KOOLER\r'),
(31, 'MAGNUM\r'),
(32, 'MAHINDRA\r'),
(33, 'MASTER\r'),
(34, 'MAXUS\r'),
(35, 'MAZDA\r'),
(36, 'MERCEDES BENZ\r'),
(37, 'YUEJIN\r'),
(38, 'MILLER\r'),
(39, 'MITSUBISHI\r'),
(40, 'MODASA\r'),
(41, 'NEW HOLLAND\r'),
(42, 'NISSAN\r'),
(43, 'OLYMPIAN\r'),
(44, 'PERKINS\r'),
(45, 'PISCO\r'),
(46, 'SANY\r'),
(47, 'SHIFENG\r'),
(48, 'SITON\r'),
(49, 'SULLAIR\r'),
(50, 'SULLAR\r'),
(51, 'TERCERO\r'),
(52, 'TEREX\r'),
(53, 'TOWER LIGHT\r'),
(54, 'TOYOTA\r'),
(55, 'VOGELE\r'),
(56, 'VOLKSWAGEN\r'),
(57, 'VOLVO\r'),
(58, 'V?GELE\r'),
(59, 'WACKER\r'),
(60, 'WIRGTEN\r'),
(61, 'WIRTGEN\r'),
(62, 'YALLEJIN\r'),
(63, 'PUTZMEISTER'),
(65, 'JMC'),
(66, 'KIA'),
(67, 'CHASKI'),
(68, 'SITOM'),
(69, 'D65EX'),
(70, 'no brand');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modelo`
--

CREATE TABLE `modelo` (
  `idModelo` int(11) NOT NULL,
  `idMarca` int(11) DEFAULT NULL,
  `descripcion` varchar(50) DEFAULT NULL,
  `consumProm` double DEFAULT NULL,
  `maxConsum` double DEFAULT NULL,
  `minConsum` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `modelo`
--

INSERT INTO `modelo` (`idModelo`, `idMarca`, `descripcion`, `consumProm`, `maxConsum`, `minConsum`) VALUES
(1, 1, 'ASC 150D\r', NULL, NULL, NULL),
(2, 1, 'ASC 150\r', NULL, NULL, NULL),
(3, 1, 'ASC 170\r', NULL, NULL, NULL),
(4, 1, 'AV 130X\r', NULL, NULL, NULL),
(5, 1, 'AP 240\r', NULL, NULL, NULL),
(6, 1, '170\r', NULL, NULL, NULL),
(7, 2, 'XAS185 JD7\r', NULL, NULL, NULL),
(8, 2, 'XAS186DD C2 EC FB\r', NULL, NULL, NULL),
(9, 3, 'JAC\r', NULL, NULL, NULL),
(10, 4, 'DM55\r', NULL, NULL, NULL),
(11, 5, 'MC86\r', NULL, NULL, NULL),
(12, 6, 'INCA\r', NULL, NULL, NULL),
(13, 7, 'BW 213 DH-4\r', NULL, NULL, NULL),
(14, 7, 'BW 216D-40\r', NULL, NULL, NULL),
(15, 7, 'BW24RH\r', NULL, NULL, NULL),
(16, 8, '580 SN EXT AUX\r', NULL, NULL, NULL),
(17, 8, '580-SN\r', NULL, NULL, NULL),
(18, 8, '865\r', NULL, NULL, NULL),
(19, 8, '845\r', NULL, NULL, NULL),
(20, 8, 'SR-220\r', NULL, NULL, NULL),
(21, 9, 'D6TXL\r', NULL, NULL, NULL),
(22, 9, 'AP655A\r', NULL, NULL, NULL),
(23, 9, 'D8T\r', NULL, NULL, NULL),
(24, 9, 'D6T STD\r', NULL, NULL, NULL),
(25, 9, 'CS56E\r', NULL, NULL, NULL),
(26, 9, 'CS 533E\r', NULL, NULL, NULL),
(27, 9, '140K\r', NULL, NULL, NULL),
(28, 9, '2PD5000\r', NULL, NULL, NULL),
(29, 9, '350\r', NULL, NULL, NULL),
(30, 9, '966G\r', NULL, NULL, NULL),
(31, 10, 'CAÑETE', NULL, NULL, NULL),
(32, 11, 'S10\r', NULL, NULL, NULL),
(33, 11, 'GRADE\r', NULL, NULL, NULL),
(34, 12, 'C65-D64\r', NULL, NULL, NULL),
(35, 12, 'GFC60D60\r', NULL, NULL, NULL),
(36, 13, 'C350D6\r', NULL, NULL, NULL),
(37, 14, 'D1146T -MD95\r', NULL, NULL, NULL),
(38, 14, 'LSC\r', NULL, NULL, NULL),
(39, 14, '450 PLUS\r', NULL, NULL, NULL),
(40, 14, 'DL 340\r', NULL, NULL, NULL),
(41, 14, 'DX210WA\r', NULL, 2.6, 1.93),
(42, 14, 'MP95 - D1146T\r', NULL, NULL, NULL),
(43, 14, '340LCA\r', NULL, NULL, NULL),
(44, 14, 'DX500\r', NULL, NULL, NULL),
(45, 14, 'DX340 LCA\r', NULL, NULL, NULL),
(46, 14, 'MEGA 400-V\r', NULL, 5.28, 4.21),
(47, 14, 'MEGA 400V\r', NULL, NULL, NULL),
(48, 14, 'DL300A\r', NULL, NULL, NULL),
(49, 14, 'DL250A\r', NULL, NULL, NULL),
(50, 14, 'DL420A\r', NULL, 6.84, 5.08),
(51, 14, 'MEGA 250-V\r', NULL, NULL, NULL),
(52, 14, 'SOLAR 340LC-V\r', NULL, 4.27, 3.65),
(53, 15, '1200\r', NULL, NULL, NULL),
(54, 16, '4MHP-500\r', NULL, NULL, NULL),
(55, 17, '52\r', NULL, NULL, NULL),
(56, 17, 'MPX\r', NULL, NULL, NULL),
(57, 17, 'VIEW\r', NULL, NULL, NULL),
(58, 18, 'M2106\r', NULL, 1.49, 1.05),
(59, 18, 'FLD120\r', NULL, NULL, NULL),
(60, 18, 'M2-106\r', NULL, NULL, NULL),
(61, 18, 'FLD 120\r', NULL, NULL, NULL),
(62, 18, 'FLD-120\r', NULL, NULL, NULL),
(63, 18, 'M2 112\r', NULL, 3.05, 2.26),
(64, 18, 'M2 106\r', NULL, NULL, NULL),
(65, 19, 'RT 600E\r', NULL, NULL, NULL),
(66, 20, '3412HT\r', NULL, NULL, NULL),
(67, 21, 'CPCD50 XRXG73\r', NULL, NULL, NULL),
(68, 22, 'DUTRO\r', NULL, 21.01, 18.92),
(69, 23, 'GRACE\r', NULL, NULL, NULL),
(70, 23, 'H-1\r', NULL, NULL, NULL),
(71, 24, '7600 SBA\r', NULL, NULL, NULL),
(72, 25, 'SIN ASIGNAR\r', NULL, NULL, NULL),
(73, 26, 'HF\r', NULL, NULL, NULL),
(74, 26, 'REFINE\r', NULL, NULL, NULL),
(75, 27, '1030\r', NULL, NULL, NULL),
(76, 28, 'VM166\r', NULL, NULL, NULL),
(77, 29, 'GD-555\r', NULL, NULL, NULL),
(78, 29, 'GD555-5\r', NULL, NULL, NULL),
(79, 29, 'D65EX-16\r', NULL, NULL, NULL),
(80, 30, 'SIN ASIGNAR\r', NULL, NULL, NULL),
(81, 31, 'MLT4060M\r', NULL, NULL, NULL),
(82, 32, 'PICK UP\r', NULL, NULL, NULL),
(83, 33, 'RENAULD\r', NULL, NULL, NULL),
(84, 34, 'T60\r', NULL, 32.96, 29.72),
(85, 35, '02.5L DECREW 4\r', NULL, NULL, NULL),
(86, 36, '2726 B/36\r', NULL, 2.06, 1.61),
(87, 36, 'ACTROS 3341K 6X4\r', NULL, 2.96, 1.37),
(88, 36, 'ACTROS 3344K 6X4\r', NULL, NULL, NULL),
(89, 36, 'ACTROS\r', NULL, NULL, NULL),
(90, 36, 'ACTROS 4144K 8X4\r', NULL, 5.35, 3.2),
(91, 36, 'ACTROS 3335K 6X4\r', NULL, 2.96, 1.37),
(92, 36, 'LK 2638/40\r', NULL, 4.18, 2.26),
(93, 36, '1720/48\r', NULL, NULL, NULL),
(94, 37, 'JC\r', NULL, NULL, NULL),
(95, 38, 'BIG BLUE 500X\r', NULL, NULL, NULL),
(96, 39, 'FE\r', NULL, NULL, NULL),
(97, 40, 'MP-30\r', NULL, NULL, NULL),
(98, 40, 'MD-315\r', NULL, NULL, NULL),
(99, 40, 'XO8371T MD-365\r', NULL, NULL, NULL),
(100, 40, 'MP-180\r', NULL, NULL, NULL),
(101, 41, 'RG140B\r', NULL, NULL, NULL),
(102, 42, 'NAVARA\r', NULL, 34.45, 30.78),
(103, 42, 'NV350\r', NULL, NULL, NULL),
(104, 42, 'OMI\r', NULL, NULL, NULL),
(105, 43, 'GEP33CB\r', NULL, NULL, NULL),
(106, 44, 'MP 350\r', NULL, NULL, NULL),
(107, 45, 'PISCO\r', NULL, NULL, NULL),
(108, 46, 'SR 150C\r', NULL, NULL, NULL),
(109, 47, 'F3 LCV\r', NULL, NULL, NULL),
(110, 48, 'STQ-31\r', NULL, NULL, NULL),
(111, 49, '260DPQ\r', NULL, NULL, NULL),
(112, 50, 'DPQ750H\r', NULL, NULL, NULL),
(113, 51, 'TERCERO\r', NULL, NULL, NULL),
(114, 52, 'VDA 700\r', NULL, NULL, NULL),
(115, 53, 'VT8\r', NULL, NULL, NULL),
(116, 54, 'HILUX\r', NULL, 43.23, 24.42),
(117, 54, 'HIACE\r', NULL, NULL, NULL),
(118, 54, 'HIRCE\r', NULL, NULL, NULL),
(119, 55, 'SUPER 1300-2\r', NULL, NULL, NULL),
(120, 55, 'SUPER 800-2\r', NULL, NULL, NULL),
(121, 56, '31.26\r', NULL, NULL, NULL),
(122, 56, 'WORKER', NULL, 0.75, 0.57),
(123, 56, '31-320\r', NULL, NULL, NULL),
(124, 57, 'PENTA - RVS228-C\r', NULL, 2.77, 2.67),
(125, 57, 'LEROY - VL450A\r', NULL, 6.16, 5.49),
(126, 57, 'FMX 8X4R\r', NULL, NULL, NULL),
(127, 57, 'FMX480 8X4\r', 4.54, 5.18, 3.79),
(128, 57, 'FMX 480 6X4\r', NULL, NULL, NULL),
(129, 57, 'FMX 6X4R\r', NULL, 2.73, 1.76),
(130, 57, 'LEROY - VL 351-A\r', NULL, NULL, NULL),
(131, 57, 'MP360\r', NULL, NULL, NULL),
(132, 57, 'RVL-351\r', NULL, 6.62, 5.93),
(133, 55, 'SUPER 800\r', NULL, NULL, NULL),
(134, 59, 'RD27\r', NULL, NULL, NULL),
(135, 61, 'W150\r', NULL, NULL, NULL),
(136, 61, 'WR-2500\r', NULL, NULL, NULL),
(137, 61, 'WR2500 S\r', NULL, NULL, NULL),
(138, 61, 'W200\r', NULL, NULL, NULL),
(139, 62, '33\r', NULL, NULL, NULL),
(140, NULL, 'no model', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `operador`
--

CREATE TABLE `operador` (
  `idOperador` int(11) NOT NULL,
  `numLicencia` char(11) DEFAULT NULL,
  `nombres` varchar(100) DEFAULT NULL,
  `apellidos` varchar(100) DEFAULT NULL,
  `telefono` char(9) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `operador`
--

INSERT INTO `operador` (`idOperador`, `numLicencia`, `nombres`, `apellidos`, `telefono`) VALUES
(1, 'ASDFGHJ123', 'TORY', 'ESPINO', '963852741'),
(2, 'FDGGDFG', 'GIAN', 'ESPINO', '123123');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `consumo`
--
ALTER TABLE `consumo`
  ADD PRIMARY KEY (`idConsumo`,`idDespacho`),
  ADD KEY `R_31` (`idDespacho`),
  ADD KEY `R_32` (`idOperador`),
  ADD KEY `R_33` (`placa`),
  ADD KEY `R_38` (`idEstadoConsum`);

--
-- Indices de la tabla `despacho`
--
ALTER TABLE `despacho`
  ADD PRIMARY KEY (`idDespacho`),
  ADD KEY `R_41` (`idOperador`);

--
-- Indices de la tabla `equipo`
--
ALTER TABLE `equipo`
  ADD PRIMARY KEY (`placa`),
  ADD KEY `R_35` (`idFrente`);

--
-- Indices de la tabla `estadoconsum`
--
ALTER TABLE `estadoconsum`
  ADD PRIMARY KEY (`idEstado`);

--
-- Indices de la tabla `frente`
--
ALTER TABLE `frente`
  ADD PRIMARY KEY (`idFRente`);

--
-- Indices de la tabla `marca`
--
ALTER TABLE `marca`
  ADD PRIMARY KEY (`idMarca`);

--
-- Indices de la tabla `modelo`
--
ALTER TABLE `modelo`
  ADD PRIMARY KEY (`idModelo`),
  ADD KEY `R_41` (`idMarca`);

--
-- Indices de la tabla `operador`
--
ALTER TABLE `operador`
  ADD PRIMARY KEY (`idOperador`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `consumo`
--
ALTER TABLE `consumo`
  MODIFY `idConsumo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT de la tabla `despacho`
--
ALTER TABLE `despacho`
  MODIFY `idDespacho` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100;

--
-- AUTO_INCREMENT de la tabla `estadoconsum`
--
ALTER TABLE `estadoconsum`
  MODIFY `idEstado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `frente`
--
ALTER TABLE `frente`
  MODIFY `idFRente` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `marca`
--
ALTER TABLE `marca`
  MODIFY `idMarca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT de la tabla `modelo`
--
ALTER TABLE `modelo`
  MODIFY `idModelo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=256;

--
-- AUTO_INCREMENT de la tabla `operador`
--
ALTER TABLE `operador`
  MODIFY `idOperador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `consumo`
--
ALTER TABLE `consumo`
  ADD CONSTRAINT `R_31` FOREIGN KEY (`idDespacho`) REFERENCES `despacho` (`idDespacho`),
  ADD CONSTRAINT `R_32` FOREIGN KEY (`idOperador`) REFERENCES `operador` (`idOperador`),
  ADD CONSTRAINT `R_38` FOREIGN KEY (`idEstadoConsum`) REFERENCES `estadoconsum` (`idEstado`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `despacho`
--
ALTER TABLE `despacho`
  ADD CONSTRAINT `R_41` FOREIGN KEY (`idOperador`) REFERENCES `operador` (`idOperador`);

--
-- Filtros para la tabla `equipo`
--
ALTER TABLE `equipo`
  ADD CONSTRAINT `R_35` FOREIGN KEY (`idFrente`) REFERENCES `frente` (`idFRente`);

--
-- Filtros para la tabla `modelo`
--
ALTER TABLE `modelo`
  ADD CONSTRAINT `modelo_ibfk_1` FOREIGN KEY (`idMarca`) REFERENCES `marca` (`idMarca`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
