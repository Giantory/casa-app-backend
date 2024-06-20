import db from "../../config/database.js";

class VehicleUseCases {
    constructor() { }

    getAllVehicles(callback) {
        db.query("SELECT eq.placa, eq.descripcion, eq.horometraje, eq.kilometraje, ma.descripcion marca, mo.descripcion modelo, mo.consumProm, mo.maxConsum, mo.minConsum " +
            "FROM equipo eq " +
            "INNER JOIN modelo mo ON eq.idModelo = mo.idModelo " +
            "INNER JOIN marca ma ON eq.idMarca = ma.idMarca", callback);
    }

    getVehicleByCode(code, callback) {
        db.query("SELECT * FROM equipo WHERE placa=?", [code], callback);
    }

    updateVehicleHMKMByCode(code, horometraje, kilometraje, callback) {
        db.query("UPDATE equipo SET horometraje=?, kilometraje=? WHERE placa=?", [horometraje, kilometraje, code], callback);
    }
}

export default VehicleUseCases;
