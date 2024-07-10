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
        vehicleUseCases.updateVehicle(code, (err, results) => {
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
        // Verificar si la placa ya existe
        vehicleUseCases.checkVehicleExists(vehicle.placa, (err, results) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: 'Error al verificar el vehículo' });
            }
            if (results.length > 0) {
                return res.status(400).json({ error: 'El vehículo con esta placa ya existe' });
            }

            // Si la placa no existe, procede a crear el vehículo
            vehicleUseCases.createVehicle(vehicle, (err, results) => {
                if (err) {
                    console.log(err);
                    return res.status(500).json({ error: 'No se pudo crear el vehículo' });
                } else {
                    // Obtener el ID del vehículo recién creado
                    const code = results.placa;
                    // Obtener los datos completos del vehículo creado
                    vehicleUseCases.getVehicleByCode(code, (err, vehicleData) => {
                        if (err) {
                            console.log(err);
                            return res.status(500).json({ error: 'No se pudo obtener el vehículo creado' });
                        } else {
                            return res.status(200).json(vehicleData);
                        }
                    });
                }
            });
        });
    } catch (error) {
        console.error('Error al crear el vehículo', error);
        res.status(500).json({ error: 'Error al crear el vehículo' });
    }
}


export const getVehiclesAmount = (req, res) => {
    vehicleUseCases.getVehiclesAmount((err, results) => {
        if (err) {
            console.error("Error al obtener los vehículos", err);
            res.status(500).json({ error: 'Error al obtener los vehículos' });
        } else {
            res.json(results);
        }
    });
};
