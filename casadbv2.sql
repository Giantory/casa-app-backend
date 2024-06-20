-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 21-06-2024 a las 01:56:10
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `procesarConsumos` (IN `inPlaca` VARCHAR(20), IN `inHorometrajeActual` DOUBLE, IN `inKilometrajeActual` DOUBLE, IN `inGalones` DOUBLE)   BEGIN
    DECLARE horometrajeDif DOUBLE;
    DECLARE kilometrajeDif DOUBLE;
    DECLARE rendimiento DOUBLE;
    DECLARE estado INT;
    DECLARE currentHorometraje DOUBLE;
    DECLARE currentKilometraje DOUBLE;
    DECLARE mensaje VARCHAR(100); -- Definir la variable para el mensaje de retorno

    -- Obtener los valores actuales de horómetro y kilometraje del vehículo
    SELECT horometraje, kilometraje INTO currentHorometraje, currentKilometraje FROM equipo WHERE placa = inPlaca;

    -- Validación de valores actuales
    IF currentHorometraje >= inHorometrajeActual OR currentKilometraje >= inKilometrajeActual THEN
        -- Crear una tabla temporal con el resultado de valores inválidos
        CREATE TEMPORARY TABLE temp_consumosProcesados AS
        SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
        mo.descripcion AS 'modelo', eq.placa, 
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

        -- Definir el mensaje de retorno
        SET mensaje = 'Los valores ingresados son iguales a los valores actuales';

    ELSE
        -- Calcular las diferencias de horómetros y kilómetros
        SET horometrajeDif = ROUND((inHorometrajeActual - currentHorometraje), 2);
        SET kilometrajeDif = ROUND((inKilometrajeActual - currentKilometraje), 2);

        -- Verificar si se encontraron registros para calcular rendimiento
        IF horometrajeDif IS NULL OR kilometrajeDif IS NULL THEN
            -- Crear una tabla temporal con el resultado indeterminado
            CREATE TEMPORARY TABLE temp_consumosProcesados AS
            SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
            mo.descripcion AS 'modelo', eq.placa, 
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

            -- Definir el mensaje de retorno
            SET mensaje = 'No se pudieron calcular las diferencias de horómetro y/o kilómetro';

        ELSE
            -- Calcular rendimiento
            IF horometrajeDif > 0 AND kilometrajeDif > 0 THEN
                SET rendimiento = ROUND(inGalones / horometrajeDif, 2);
            ELSE
                SET rendimiento = 0;
            END IF;

            -- Crear una tabla temporal con los resultados procesados
            CREATE TEMPORARY TABLE temp_consumosProcesados AS
            SELECT eq.descripcion AS 'equipo', ma.descripcion AS 'marca', inGalones AS galones, 
            mo.descripcion AS 'modelo', eq.placa, 
            inHorometrajeActual AS horometraje, 
            inKilometrajeActual AS kilometraje,
            rendimiento AS rendimiento,
            CASE
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento > -2 THEN 2
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento < -2 THEN 3
                WHEN rendimiento < mo.maxConsum THEN 1
            END AS estadoCodigo,
            CASE
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento > -2 THEN 'Sospechoso'
                WHEN mo.maxConsum - rendimiento < 0 AND mo.maxConsum - rendimiento < -2 THEN 'Desmedido'
                WHEN rendimiento < mo.maxConsum THEN 'Regular'
            END AS estadoDescripcion,
            currentHorometraje AS currentHorometraje,
            currentKilometraje AS currentKilometraje
            FROM equipo eq 
            INNER JOIN marca ma ON eq.idMarca = ma.idMarca
            INNER JOIN modelo mo ON eq.idModelo = mo.idModelo
            WHERE eq.placa = inPlaca;

            -- Definir el mensaje de retorno
            SET mensaje = 'Datos procesados correctamente';
        END IF;
    END IF;

    -- Esta consulta selecciona los datos de la tabla temporal con las columnas adicionales.
    SELECT *, mensaje AS mensaje FROM temp_consumosProcesados;

    -- Eliminar la tabla temporal una vez que se haya utilizado.
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
  `horometraje` int(11) DEFAULT NULL,
  `inHorometraje` int(11) DEFAULT NULL,
  `kilometraje` int(11) DEFAULT NULL,
  `inKilometraje` int(11) DEFAULT NULL,
  `galones` double DEFAULT NULL,
  `rendimiento` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

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
  `estado` int(11) DEFAULT NULL,
  `horometraje` double DEFAULT NULL,
  `kilometraje` double DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `equipo`
--

INSERT INTO `equipo` (`placa`, `descripcion`, `idModelo`, `idMarca`, `idFrente`, `estado`, `horometraje`, `kilometraje`, `updated_at`) VALUES
('0085 / 1718 / 0790', 'PAVIMENTADORA', 56, 31, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('0405A', 'GRUPO EL?CTROGENO', 37, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1047', 'RODILLO LISO ', 67, 35, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1085', 'GRUA', 104, 54, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1104', 'GRUPO EL?CTROGENO', 34, 19, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1114', 'RODILLO LISO ', 65, 35, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1124', 'GRUPO EL?CTROGENO', 38, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('12', 'TRACTOR AGRICOLA', 120, 48, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1228', 'PAVIMENTADORA', 55, 31, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('130', 'GRUPO EL?CTROGENO', 107, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1327', 'RODILLO LISO ', 66, 35, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1394', 'GRUPO EL?CTROGENO', 120, 20, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('14', 'RODILLO LISO DOBLE ROLA', 63, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1479', 'TRACTOR DE ORUGAS', 73, 28, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1637', 'RODILLO LISO ', 70, 36, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('17', 'RODILLO LISO DOBLE ROLA', 63, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('171', 'PAVIMENTADORA', 53, 31, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1731', 'RODILLO NEUMATICO', 64, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1776', 'MOTOSOLDADORA', 106, 56, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1834', 'TRACTOR DE ORUGAS', 74, 62, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('194', 'FRESADORA', 28, 15, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1980', 'EXCAVADORA HIDRAULICA', 102, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1993', 'MINICARGADOR ', 44, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1995', 'EXCAVADORA HIDRAULICA', 25, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('1996', 'EXCAVADORA HIDRAULICA', 25, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2080', 'RODILLO NEUMATICO', 120, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('216', 'CARGADOR FRONTAL', 5, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2167', 'RODILLO LISO ', 62, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2180', 'EXCAVADORA HIDRAULICA', 25, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2197', 'RODILLO LISO ', 62, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2198', 'RODILLO LISO ', 62, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2241', 'LUMINARIA', 41, 24, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2244', 'LUMINARIA', 41, 24, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2285', 'EXCAVADORA HIDRAULICA', 25, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2313', 'GRUPO EL?CTROGENO', 120, 17, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2388', 'MONTACARGA', 115, 59, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2420', 'GRUPO EL?CTROGENO', 36, 20, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2577', 'MOTONIVELADORA', 47, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('258', 'CARGADOR FRONTAL', 4, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('2719', 'RODILLO BERMERO', 60, 33, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('3000', 'RETROEXCAVADORA', 57, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('3159', 'MOTONIVELADORA', 47, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('316', 'RODILLO LISO ', 71, 37, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('32', 'EXCAVADORA HIDRAULICA', 26, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('325', 'T. ASFALTO', 91, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('32MOTO', 'MOTOSOLDADORA', 52, 30, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('357', 'GRUA', 119, 61, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('3597', 'MOTONIVELADORA', 49, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('3601', 'MOTONIVELADORA', 49, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('368', 'CARGADOR FRONTAL', 3, 3, NULL, 1, 123, 123, '2024-06-19 23:06:49'),
('370', 'RODILLO LISO ', 69, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('3772', 'CARGADOR FRONTAL', 3, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('379', 'CARGADOR FRONTAL', 6, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('38118010117', 'COMPRESORA', 114, 58, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4070', 'RODILLO LISO ', 68, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4188', 'LUMINARIA', 40, 23, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('420', 'CARGADOR FRONTAL', 107, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4214', 'LUMINARIA', 39, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4215', 'LUMINARIA', 39, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4217', 'LUMINARIA', 39, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4219', 'LUMINARIA', 39, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4293', 'CARGADOR FRONTAL', 7, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4296', 'LUMINARIA', 39, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4377', 'CARGADOR FRONTAL', 7, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('438', 'CARGADOR FRONTAL', 8, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4516', 'MOTONIVELADORA', 50, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('461', 'INCAPOSTES', 120, 22, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('489', 'RECICLADORA', 59, 15, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('4972', 'GENERADOR', 87, 20, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5100', 'MOTOSOLDADORA', 52, 30, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5113', 'GRUPO EL?CTROGENO', 109, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5116', 'GENERADOR', 88, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('518', 'EXCAVADORA HIDRAULICA', 27, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5306', 'EXCAVADORA HIDRAULICA', 26, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5456', 'EXCAVADORA HIDRAULICA', 100, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5491', 'EXCAVADORA HIDRAULICA', 108, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('55', 'RECICLADORA', 58, 15, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5545', 'GRUPO EL?CTROGENO', 30, 16, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5576', 'MOTONIVELADORA', 48, 28, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5586', 'MINICARGADOR ', 43, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('58', 'MOTOSOLDADORA', 52, 30, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5858', 'MOTONIVELADORA', 48, 28, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5920', 'MOTONIVELADORA', 48, 28, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('5954', 'GRUPO EL?CTROGENO', 29, 16, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('6046', 'COMPRESORA', 22, 14, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('616', 'C. FRONTAL', 89, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('618', 'TRACTOR DE ORUGAS', 72, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('62', 'MOTOSOLDADORA', 52, 30, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('625', 'PAVIMENTADORA', 54, 32, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('642', 'EXCAVADORA HIDRAULICA', 26, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('6637', 'MOTONIVELADORA', 51, 29, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('6799', 'RETROEXCAVADORA', 112, 26, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('772', 'RODILLO LISO ', 61, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('780', 'RODILLO LISO ', 61, 34, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('853', 'FRESADORA', 79, 15, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A0B-929', 'CAMION BARANDA', 10, 2, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A0H-858', 'CAMION PIME', 82, 46, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A0N-841', 'CAMION BARANDA', 10, 2, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A3H-824', 'CAMION MANTENIMIENTO', 12, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A4L-934', 'CAMIONETA', 20, 12, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('A8J-906', 'MIXER', 111, 57, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AAE-721', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ACK-732', 'CAMION MANTENIMIENTO', 13, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AFA-857', 'VOLQUETES (4m3)', 75, 38, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AFN-881', 'CAMION BARANDA', 11, 6, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AFP-812', 'CAMION', 11, 50, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AFP-822', 'CAMION BARANDA', 11, 6, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AHK-856', 'MINIVAN', 113, 11, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AHY-754', 'BOMBA DE CONCRETO', 2, 2, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AKJ-244', 'MINIVAN', 110, 47, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ALF-765', 'COMBI PIME', 99, 41, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMO-903', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-828', 'VOLQUETES (15m3)', 77, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-876', 'VOLQUETES (15m3)', 77, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-878', 'VOLQUETE', 101, 53, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-888', 'VOLQUETE', 105, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-900', 'VOLQUETES (15m3)', 77, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AMW-917', 'VOLQUETES (15m3)', 77, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANF-791', 'CAMIONETA', 17, 9, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-797', 'VOLQUETES (20m3)', 78, 21, NULL, 1, 14232.35, 272183.6, '2024-06-20 23:27:26'),
('ANM-798', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-800', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-801', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-802', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-803', 'VOLQUETES (20m3)', 78, 21, NULL, 1, 13749.48, 268410.5, '2024-06-17 17:42:25'),
('ANM-804', 'VOLQUETES (20m3)', 78, 21, NULL, 1, 13657.08, 244916.2, '2024-06-20 23:34:39'),
('ANM-805', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-20 23:35:10'),
('ANM-806', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-20 23:35:15'),
('ANM-807', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-20 23:35:47'),
('ANM-808', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-810', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANM-811', 'VOLQUETES (20m3)', 78, 21, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANV-935', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANV-938', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-723', 'VOLQUETE', 101, 53, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-740', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-773', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-857', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-858', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANW-935', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANX-726', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANX-727', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANX-756', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANX-892', 'CAMION MIXER', 14, 2, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ANZ-804', 'VOLQUETES (15m3)', 76, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ASF-832', 'CAMION PIME', 120, 40, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('ATJ-753', 'CAMION PIME', 83, 47, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('AYU-856', 'CAMIONETA', 95, 9, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('B4C-738', 'COMBI PIME', 92, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('B4M-804', 'MICROPAVIMENTADOR', 45, 27, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('B4R-929', 'CAMION PIME', 86, 43, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('B5S-885', 'CAMION', 118, 60, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('B8S-410', 'COMBI PIME', 85, 25, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('BFO-750', 'CAMIONETA', 80, 44, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('BOI-770', 'COMBI PIME', 120, 41, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C0C-923', 'CAMION', 94, 49, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C3K-884', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C7E-736', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C7G-818', 'SEMITRAILER TOLVA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C7G-819', 'CAMABAJA', 120, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C7K-486', 'COMBI PIME', 120, 42, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C7R-893', 'CISTERNA DE AGUA', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C8F-841', 'CAMION PIME', 120, 43, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C8V-342', 'MINIVAN', 110, 47, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('C9Z-909', 'CAMION PIME', 120, 39, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('CALDERO CIBER', 'CALDERO CIBER', 90, 62, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('CIB-311', 'COMBI PIME', 85, 25, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D3G-928', 'CISTERNA DE AGUA', 24, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D3H-802', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D3H-806', 'CISTERNA DE AGUA', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D3H-812', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D3Z-789', 'VOLQUETE', 116, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D4N-776', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D4T-873', 'CISTERNA DE AGUA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D4T-877', 'CISTERNA DE AGUA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D5M-774', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D5M-775', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D7D-229', 'COMBI PIME', 81, 45, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D7M-755', 'CAMIONETA', 18, 10, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D7Y-299', 'COMBI PIME', 120, 62, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D7Y-799', 'COMBI PIME', 84, 41, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D8M-926', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('D8N-828', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('E0453', 'MONTACARGA', 46, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('E1057', 'GRUPO EL?CTROGENO', 31, 4, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('E1093', 'GRUPO EL?CTROGENO', 35, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('E1616', 'COMPRESORA', 22, 14, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('E3556', 'GRUPO EL?CTROGENO', 33, 18, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('EO615', 'GRUPO EL?CTROGENO', 32, 3, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('EUD-874', 'AMBULANCIA', 1, 1, NULL, 1, 123, 123, '2024-06-19 20:16:03'),
('F0J-930', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F0K-721', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F0K-744', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F0N-925', 'CAMIONETA', 19, 11, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F0O-841', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2J-744', 'VOLQUETES (15m3)', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2J-745', 'CAMION', 93, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-484', 'MINIVAN', 42, 25, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-709', 'SEMITRAILER TOLVA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-719', 'CAMABAJA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-729', 'CISTERNA DE AGUA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-754', 'TRACTO REMOLCADOR', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F2M-775', 'CISTERNA DE AGUA', 21, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F3B-836', 'COMBI PIME', 96, 41, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F3L-799', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F4B-848', 'CISTERNA DE AGUA', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F4B-849', 'CAMION IMPRIMADOR', 16, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F4B-871', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F4B-874', 'CISTERNA DE AGUA', 23, 7, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F5L-915', 'CAMIONETA', 20, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('F7F-889', 'CAMION MIXER', 15, 8, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('HIB-726', 'COMBI PIME', 120, 11, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('M4E-893', 'CAMION', 120, 55, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('PEA I', 'PEA CALDERO 1', 120, 62, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('PEA II', 'PEA CALDERO 11', 120, 62, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('W2V-189', 'COMBI PIME', 117, 11, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('X5K-956', 'COMBI PIME', 103, 13, NULL, 1, NULL, NULL, '2024-06-17 17:42:25'),
('Z1H-918', 'CAMION', 9, 5, NULL, 1, NULL, NULL, '2024-06-17 17:42:25');

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
(5, 'Inválido');

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
(1, 'MASTER\r'),
(2, 'VOLKSWAGEN\r'),
(3, 'DOOSAN\r'),
(4, 'CATERPILLAR\r'),
(5, 'SHIFENG\r'),
(6, 'HINO\r'),
(7, 'MERCEDES BENZ\r'),
(8, 'FREIGHTLINER\r'),
(9, 'CHEVROLET\r'),
(10, 'MAZDA\r'),
(11, 'NISSAN\r'),
(12, 'MAHINDRA\r'),
(13, 'TOYOTA\r'),
(14, 'ATLAS COPCO\r'),
(15, 'WIRTGEN\r'),
(16, 'PERKINS\r'),
(17, 'JHON DERE\r'),
(18, 'OLYMPIAN\r'),
(19, 'VOLVO PENTA\r'),
(20, 'CUMMINS\r'),
(21, 'VOLVO\r'),
(22, 'FAGA\r'),
(23, 'TOWER LING\r'),
(24, 'MAGNUN\r'),
(25, 'HYUNDAI\r'),
(26, 'CASE\r'),
(27, 'INTERNATIONAL\r'),
(28, 'KOMATSU\r'),
(29, 'NEW HOLLAND\r'),
(30, 'MILLER 2\r'),
(31, 'VOGELE\r'),
(32, 'TEREX\r'),
(33, 'WACKER\r'),
(34, 'AMMANN\r'),
(35, 'BOMAG\r'),
(36, 'JCB\r'),
(37, 'HAMM\r'),
(38, 'SITON\r'),
(39, 'HYUNDAY\r'),
(40, 'JMC\r'),
(41, 'FOTON\r'),
(42, 'KIA\r'),
(43, 'MITSUBISHI\r'),
(44, 'MAXUS\r'),
(45, 'BAW\r'),
(46, 'YUEJIN\r'),
(47, 'JAC\r'),
(48, 'CHASKI\r'),
(49, 'YALLEJIN\r'),
(50, 'HYNO\r'),
(51, 'PISCO\r'),
(52, 'CA?ETE\r'),
(53, 'MB\r'),
(54, 'SANY\r'),
(55, 'ISUZU\r'),
(56, 'MILLER\r'),
(57, 'M. BENZ\r'),
(58, 'SULLAR\r'),
(59, 'ZAPLER\r'),
(60, 'JBC\r'),
(61, 'BAUER\r'),
(62, 'MARCA SIN DETERMINAR\r');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modelo`
--

CREATE TABLE `modelo` (
  `idModelo` int(11) NOT NULL,
  `descripcion` varchar(50) DEFAULT NULL,
  `consumProm` double DEFAULT NULL,
  `maxConsum` double DEFAULT NULL,
  `minConsum` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `modelo`
--

INSERT INTO `modelo` (`idModelo`, `descripcion`, `consumProm`, `maxConsum`, `minConsum`) VALUES
(1, 'RENAULD', 0, 0, 0),
(2, '31320', 0, 0, 0),
(3, 'MEGA 400V', 0, 0, 0),
(4, 'DL300', 0, 0, 0),
(5, 'DL250A', 0, 0, 0),
(6, 'DL420A', 0, 0, 0),
(7, 'MEGA 250V', 0, 0, 0),
(8, '966G', 0, 0, 0),
(9, 'F3 LCV', 0, 0, 0),
(10, '9.15', 0, 0, 0),
(11, 'DUTRO', 0, 0, 0),
(12, '1720/48', 0, 0, 0),
(13, 'M2106', 0, 0, 0),
(14, '31.26', 0, 0, 0),
(15, 'M2-112', 0, 0, 0),
(16, 'M2 106', 0, 0, 0),
(17, 'SIO', 0, 0, 0),
(18, '02.5L DECREW 4', 0, 0, 0),
(19, 'NAVARA', 0, 0, 0),
(20, 'HILUX 4 x 4', 0, 0, 0),
(21, 'FLD120', 0, 0, 0),
(22, 'LE 10-10', 0, 0, 0),
(23, 'LK-2638/40', 0, 0, 0),
(24, 'ACTROS 3335K', 0, 0, 0),
(25, 'SOLAR 340LC-V', 0, 0, 0),
(26, 'DX340 LCA', 0, 0, 0),
(27, 'DX500', 0, 0, 0),
(28, 'W150', 0, 0, 0),
(29, 'MP 350', 0, 0, 0),
(30, 'MP-180', 0, 0, 0),
(31, '350', 0, 0, 0),
(32, 'D1146T -MD95', 0, 0, 0),
(33, 'GEP33-3', 0, 0, 0),
(34, 'RVL-351', 0, 0, 0),
(35, 'XO8371T MD-365', 0, 0, 0),
(36, 'C65-D64', 0, 0, 0),
(37, 'MP360', 0, 0, 0),
(38, 'VL 351-A', 0, 0, 0),
(39, 'LSC', 0, 0, 0),
(40, 'VT8', 0, 0, 0),
(41, 'MLT4060M', 0, 0, 0),
(42, 'H-1', 0, 0, 0),
(43, '450', 0, 0, 0),
(44, 'SR-220', 0, 0, 0),
(45, 'WORK STAR ', 0, 0, 0),
(46, '2PD5000', 0, 0, 0),
(47, '140K', 0, 0, 0),
(48, 'GD-555', 0, 0, 0),
(49, '845', 0, 0, 0),
(50, '865', 0, 0, 0),
(51, 'RG140.B', 0, 0, 0),
(52, 'BIB BLUE 500X', 0, 0, 0),
(53, 'SUPER 1300-2', 0, 0, 0),
(54, 'VDA700', 0, 0, 0),
(55, 'SUPER 1800-2', 0, 0, 0),
(56, 'SUPER 800', 0, 0, 0),
(57, '580-SN', 0, 0, 0),
(58, 'WR2500', 0, 0, 0),
(59, 'WR2500 S', 0, 0, 0),
(60, 'RD27', 0, 0, 0),
(61, 'ASC-150', 0, 0, 0),
(62, 'ASC-170', 0, 0, 0),
(63, 'AV 130X', 0, 0, 0),
(64, 'AP240', 0, 0, 0),
(65, 'BW 213 DH-4', 0, 0, 0),
(66, '216D', 0, 0, 0),
(67, 'BW24', 0, 0, 0),
(68, 'CS533E', 0, 0, 0),
(69, 'CS56', 0, 0, 0),
(70, 'VM166', 0, 0, 0),
(71, '3412HT', 0, 0, 0),
(72, 'D6T STD', 0, 0, 0),
(73, 'D65EX-16', 0, 0, 0),
(74, 'D8T', 0, 0, 0),
(75, 'STQ-31', 0, 0, 0),
(76, 'ACTROS 4144K', 4.28, 5.35, 3.2),
(77, 'FMX 6X4R', 0, 0, 0),
(78, 'FMX 8X4R', 4.54, 5.69, 3.72),
(79, 'W200', 0, 0, 0),
(80, 'T60', 0, 0, 0),
(81, 'INCA', 0, 0, 0),
(82, 'JC', 0, 0, 0),
(83, 'HF', 0, 0, 0),
(84, 'VIEW', 0, 0, 0),
(85, 'GRACE', 0, 0, 0),
(86, 'FE', 0, 0, 0),
(87, 'C350', 0, 0, 0),
(88, 'MODASA', 0, 0, 0),
(89, '300 A', 0, 0, 0),
(90, '3020 P', 0, 0, 0),
(91, 'AP655A', 0, 0, 0),
(92, 'HIACE', 0, 0, 0),
(93, 'M2-106', 0, 0, 0),
(94, '33', 0, 0, 0),
(95, 'GRADE', 0, 0, 0),
(96, 'MPX', 0, 0, 0),
(97, 'PISCO', 0, 0, 0),
(98, 'CA?ETE', 0, 0, 0),
(99, '52', 0, 0, 0),
(100, 'DL 340', 0, 0, 0),
(101, 'ACTROS', 0, 0, 0),
(102, '340', 0, 0, 0),
(103, 'HIRCE', 0, 0, 0),
(104, 'SRISOL', 0, 0, 0),
(105, 'FMX480', 0, 0, 0),
(106, 'BIJ. BLUE', 0, 0, 0),
(107, '300', 0, 0, 0),
(108, 'AX ZIOWA', 0, 0, 0),
(109, 'V2755', 0, 0, 0),
(110, 'REFINE', 0, 0, 0),
(111, '24RH', 0, 0, 0),
(112, '580', 0, 0, 0),
(113, 'NV350', 0, 0, 0),
(114, 'DPQ750H', 0, 0, 0),
(115, 'CASE', 0, 0, 0),
(116, '3344', 0, 0, 0),
(117, 'OMI', 0, 0, 0),
(118, '1030', 0, 0, 0),
(119, 'MC86', 0, 0, 0),
(120, 'MODELO SIN DETERMINAR', 0, 0, 0);

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
  ADD KEY `R_34` (`idModelo`),
  ADD KEY `R_35` (`idFrente`),
  ADD KEY `R_36` (`idMarca`);

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
  ADD PRIMARY KEY (`idModelo`);

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
  MODIFY `idConsumo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT de la tabla `despacho`
--
ALTER TABLE `despacho`
  MODIFY `idDespacho` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63;

--
-- AUTO_INCREMENT de la tabla `estadoconsum`
--
ALTER TABLE `estadoconsum`
  MODIFY `idEstado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `frente`
--
ALTER TABLE `frente`
  MODIFY `idFRente` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `marca`
--
ALTER TABLE `marca`
  MODIFY `idMarca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63;

--
-- AUTO_INCREMENT de la tabla `modelo`
--
ALTER TABLE `modelo`
  MODIFY `idModelo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=121;

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
  ADD CONSTRAINT `R_33` FOREIGN KEY (`placa`) REFERENCES `equipo` (`placa`),
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
  ADD CONSTRAINT `R_34` FOREIGN KEY (`idModelo`) REFERENCES `modelo` (`idModelo`),
  ADD CONSTRAINT `R_35` FOREIGN KEY (`idFrente`) REFERENCES `frente` (`idFRente`),
  ADD CONSTRAINT `R_36` FOREIGN KEY (`idMarca`) REFERENCES `marca` (`idMarca`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
