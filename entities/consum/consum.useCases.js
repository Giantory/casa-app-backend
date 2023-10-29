import db from "../../config/database.js";

class ConsumUseCases {
    constructor() {
    }
    getAllConsums(callback) {
        db.query('SELECT * FROM consumo', callback);
    }
    processConsum(consum, callback) {
        db.query('CALL procesarConsumos(?, ?, ?, ?)', [consum.placa, consum.horometraje, consum.kilometraje, consum.galones], callback);
    }


}

export default ConsumUseCases;