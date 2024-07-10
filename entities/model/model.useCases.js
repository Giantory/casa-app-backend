import db from "../../config/database.js";

class ModelUseCases {
    constructor() { }

    getAllModels(callback) {
        db.query("SELECT ma.descripcion marca, mo.descripcion modelo, mo.*, ma.* FROM modelo mo " +
            "INNER JOIN marca ma ON mo.idMarca = ma.idMarca; ", callback);
    }
    getModelByMarcaId(marcaId, callback) {
        db.query('SELECT * FROM modelo WHERE idMarca = ?', [marcaId], callback);
    }
}

export default ModelUseCases;
