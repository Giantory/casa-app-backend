import db from "../../config/database.js";

class ConsumUseCases {
    constructor(){
    }
    getAllConsums(callback){
        db.query('SELECT * FROM consumo', callback);
    }
 

}

export default ConsumUseCases;