import db from "../../config/database.js";

class AnalyticsUseCases {
    constructor() {
    }
    getGallonsPerMonth(callback) {
        db.query("SELECT DATE_FORMAT(d.fechaDespacho, '%Y-%m') AS mes, " +
            "SUM(c.galones) AS total_galones FROM consumo c " +
            "JOIN despacho d ON c.idDespacho = d.idDespacho " +
            "WHERE YEAR(d.fechaDespacho) = YEAR(CURDATE()) " +
            "GROUP BY DATE_FORMAT(d.fechaDespacho, '%Y-%m') " +
            "ORDER BY mes;"
            , callback);
    }




}

export default AnalyticsUseCases;