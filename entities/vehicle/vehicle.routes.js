import { Router } from 'express';

//controllers
import { getAllVehicles, getVehicleByCode, createVehicle, getVehicleDetailsByCode, getVehiclesAmount, updateVehicle } from './vehicle.controller.js';

const router = new Router();

router.get(`/api/vehicles`, getAllVehicles);
router.get(`/api/vehiles/vehiclesAmount`, getVehiclesAmount);
router.get(`/api/vehicles/:code/`, getVehicleByCode);
router.get(`/api/vehicle-details/:code/`, getVehicleDetailsByCode);
router.post(`/api/vehicles`, createVehicle);
router.put(`/api/vehicles/:code`, updateVehicle);


export default router;