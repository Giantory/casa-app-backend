import db from "../../config/database.js";

class ModelUseCases {
    constructor() { }

    getAllBrands(callback) {
        db.query("SELECT * FROM marca", callback);
    }
    getBrandById(marcaId, callback) {
        db.query('SELECT * FROM operador WHERE idOperador = ?', [marcaId], callback);
    }
}

export default ModelUseCases;
