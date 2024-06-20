import DispatchUseCases from "./dispatch.useCases.js";
import ConsumUseCases from "../consum/consum.useCases.js";
import VehicleUseCases from "../vehicle/vehicle.useCases.js";

const dispatchUseCases = new DispatchUseCases();
const consumUseCases = new ConsumUseCases();
const vehicleUseCases = new VehicleUseCases();

export const getAllDispatches = (req, res) => {
    dispatchUseCases.getAllDispatches((err, results) => {
        if (err) {
            console.error('Error al obtener los despachos', err);
            res.status(500).json({ error: 'Error al obtener los depachos' });
        } else if (results.length === 0) {
            console.error('No se encontró ningún registro');
            res.status(404).json({ error: 'No se encontró ningún registro' });

        } else {
            res.json(results);
        }
    });
}

export const createDispatch = (req, res) => {
    const { dispatch, consumos } = req.body;
    dispatchUseCases.createDispatch(dispatch, (err, createdDispatch) => {
        if (err) {
            console.error('Error al crear el despacho', err);
            res.status(500).json({ error: 'Error al crear el despacho' });
        } else {
            consumos.forEach(consum => {
                consum.idDespacho = createdDispatch.idDespacho;
            });

            consumUseCases.createConsum(consumos, async (err, results) => {
                if (err) {
                    console.error('Error al crear los consumos', err);
                    res.status(500).json({ error: 'Error al crear los consumos' });
                } else {
                    try {
                        const updatePromises = consumos.map(consum => {
                            return new Promise((resolve, reject) => {
                                vehicleUseCases.updateVehicleHMKMByCode(
                                    consum.placa,
                                    consum.horometraje,
                                    consum.kilometraje,
                                    (err, result) => {
                                        if (err) {
                                            reject(err);
                                        } else {
                                            resolve(result);
                                        }
                                    }
                                );
                            });
                        });

                        await Promise.all(updatePromises);

                        res.json({
                            message: 'Despacho y consumos creados con éxito',
                            status: 'OK',
                            dispatch: createdDispatch,
                            consumos: results // Los consumos creados
                        });
                    } catch (updateError) {
                        console.error('Error al actualizar los vehículos', updateError);
                        res.status(500).json({ error: 'Error al actualizar los vehículos' });
                    }
                }
            });
        }
    });
};
