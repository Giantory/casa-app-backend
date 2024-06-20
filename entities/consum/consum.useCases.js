import db from "../../config/database.js";

class ConsumUseCases {
    constructor() {
    }
    getAllConsums(callback) {
        db.query('SELECT * FROM consumo', callback);
    }

    getConsumoByDispatchId(dispatchId, callback) {
        db.query('SELECT * FROM consumo WHERE idDespacho = ? ', [dispatchId], callback);
    }

    processConsum(consum, callback) {
        db.query('CALL procesarConsumos(?, ?, ?, ?)', [consum.placa, consum.horometraje, consum.kilometraje, consum.galones], callback);
    }
    createConsum(consumos, callback) {
        const query = "INSERT INTO `consumo`(`idDespacho`, `placa`, `idEstadoConsum`, `inHorometraje`, `horometraje`, `inKilometraje`, `kilometraje`, `galones`, `rendimiento`) VALUES ?";
        const values = consumos.map(consum => [
            consum.idDespacho,
            consum.placa,
            consum.estadoCodigo,
            consum.currentHorometraje,
            consum.horometraje,
            consum.currentKilometraje,
            consum.kilometraje,
            consum.galones,
            consum.rendimiento,
        ]);

        db.query(query, [values], (err, results) => {
            if (err) {
                return callback(err);
            }
            callback(null, results);
        });
    }


}

export default ConsumUseCases;