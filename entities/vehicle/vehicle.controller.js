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

export const getVehicleDetailsByCode = (req, res) => {
    const code = req.params.code;
    vehicleUseCases.getVehicleDetailsByCode(code, (err, results) => {
        if (err) {
            console.error('Error al obtener los detalles vehículo:', err);
            res.status(500).json({ error: 'Error al obtener los detalles del vehículo' });
        } else if (results.length == 0) {
            res.status(400).json({ error: 'No se encontró el vehículo' });
        } else {
            res.json(results);
        }
    });
}

export const updateVehicle = async (req, res) => {
    const code = req.params.code;

    try {
        vehicleUseCases.updateVehicleByCode(code, (err, results) => {
            if (err) {
                console.error('Error al obtener el vehículo:', err);
                res.status(500).json({ error: 'Error al obtener el vehículo' });
            } else if (results.length == 0) {
                res.status(400).json({ error: 'No se encontró el vehículo' });
            } else {
                res.json(results);
            }
        });
    } catch (error) {
        console.error('Error al procesar el consumo', error);
        res.status(500).json({ error: 'Error al procesar el consumo' });
    }

}

export const createVehicle = async (req, res) => {

    const vehicle = req.body;

    try {
        vehicleUseCases.createVehicle(vehicle, (err, results) => {
            if (err) {
                res.status(500).json({ error: 'No se pudo crear el vehículo' })
            } else {
                res.status(200).json(results[0])
            }
        });
    } catch (error) {
        console.error('Error al crear el vehículo', error);
        res.status(500).json({ error: 'Error al crear el vehículo' });
    }

}
