import VehicleUseCases from "./vehicle.useCases.js";

const vehicleUseCases = new VehicleUseCases();

export const getAllVehicles = (req, res) => {
    vehicleUseCases.getAllVehicles((err, results) => {
        if (err) {
            console.error("Error al obtener los vehículos", err);
            res.status(500).json({ error: 'Error al obtener los vehículos' });
        } else {
            res.json(results);
        }
    });
};

export const getVehicleByCode = (req, res) => {
    const code = req.params.code;
    vehicleUseCases.getVehicleByCode(code, (err, results) => {
        if (err) {
            console.error('Error al obtener el vehículo:', err);
            res.status(500).json({ error: 'Error al obtener el vehículo' });
        } else if (results.length == 0) {
            res.status(400).json({ error: 'No se encontró el vehículo' });
        } else {
            res.json(results);
        }
    });
}