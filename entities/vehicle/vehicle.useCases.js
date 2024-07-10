import db from "../../config/database.js";

class VehicleUseCases {
    constructor() { }

    getAllVehicles(callback) {
        db.query("SELECT eq.placa, eq.descripcion, eq.horometraje, eq.kilometraje, eq.idModelo, eq.idMarca, "+
            "ma.descripcion marca, mo.descripcion modelo, mo.consumProm, mo.maxConsum, mo.minConsum " +
            "FROM equipo eq " +
            "INNER JOIN modelo mo ON eq.idModelo = mo.idModelo " +
            "INNER JOIN marca ma ON eq.idMarca = ma.idMarca", callback);
    }

    getVehicleByCode(code, callback) {
        db.query("SELECT * FROM equipo WHERE placa=?", [code], callback);
    }
    getVehicleDetailsByCode(code, callback) {
        db.query("SELECT ec.descripcion AS mensajeEstado, eq.*, co.*, de.* FROM equipo eq "+ 
            "INNER JOIN consumo co ON co.placa = eq.placa "+
            "INNER JOIN despacho de ON de.idDespacho = co.idDespacho " +
            "INNER JOIN estadoconsum ec ON ec.idEstado = co.idEstadoConsum " +
            "WHERE eq.placa=? "+
            "ORDER BY de.fechaDespacho;", [code], callback);
    }

    updateVehicleHMKMByCode(code, horometraje, kilometraje, callback) {
        db.query("UPDATE equipo SET horometraje=?, kilometraje=? WHERE placa=?", [horometraje, kilometraje, code], callback);
    }

    checkVehicleExists(placa, callback) {
        db.query("SELECT * FROM equipo WHERE placa = ?", [placa], callback);
    }
    createVehicle(vehicle, callback) {
        const query = "INSERT INTO equipo (placa, descripcion, horometraje, kilometraje, idMarca, idModelo) VALUES (?, ?, ?, ?, ?, ?)";
        const values = [vehicle.placa, vehicle.descripcion, vehicle.horometraje, vehicle.kilometraje, vehicle.idMarca, vehicle.idModelo];
        db.query(query, values, callback);
    }

    getVehiclesAmount(callback){
        db.query("SELECT (SELECT COUNT(*) FROM equipo) AS total_vehiculos, "+
    "(SELECT COUNT(*) FROM equipo WHERE updated_at >= NOW() - INTERVAL 7 DAY) AS vehiculos_recientes;", callback)
    }
}

export default VehicleUseCases;
