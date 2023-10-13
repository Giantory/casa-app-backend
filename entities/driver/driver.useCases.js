import db from "../../config/database.js";
class DriverUseCases {
    constructor(){
        
    }
    getAllDrivers(callback){
        db.query('SELECT * FROM operador', callback);
    }

    getDriverById(driverId, callback){
        db.query('SELECT * FROM operador WHERE idOperador = ?', [driverId], callback);
    }

}

export default DriverUseCases;