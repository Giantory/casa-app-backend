import { Router } from 'express';

//controllers
import { getAllVehicles, getVehicleByCode } from './vehicle.controller.js';

const router = new Router();

router.get(`/api/vehicles`, getAllVehicles);
router.get(`/api/vehicles/:code/`, getVehicleByCode);

export default router;