import db from "../../config/database.js";

class VehicleUseCases {
    constructor() {

    };

    getAllVehicles(callback) {
        db.query("SELECT * FROM equipo", callback);
    };

    getVehicleByCode(code, callback) {
        db.query("SELECT * FROM equipo WHERE placa=?", [code], callback);
    }
}

export default VehicleUseCases;