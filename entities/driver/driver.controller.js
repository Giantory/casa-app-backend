import DriverUseCases from "./driver.useCases.js";

const driverUseCases = new DriverUseCases();

export const getAllDrivers = (req, res) => {
    driverUseCases.getAllDrivers((err, results) => {
        if (err) {
            console.error('Error al obtener operadores:', err);
            res.status(500).json({ error: 'Error al obtener operadores' });
        } else {
            res.json(results);
        }
    });
};

export const getDriverById = (req, res) => {
    const driverId=req.params.id;
    driverUseCases.getDriverById(driverId, (err, results) => {
        if (err) {
            console.error('Error al obtener operadores:', err);
            res.status(500).json({ error: 'Error al obtener operadores' });
        } else if (results.length == 0) {
            res.status(400).json({ error: 'No se encontró el conductor' });

        } else {
            res.json(results);
        }
    });
};
