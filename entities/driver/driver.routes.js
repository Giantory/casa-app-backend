import { Router } from 'express';

//controllers
import { getAllDrivers, getDriverById } from './driver.controller.js';
const router = new Router();

router.get(`/api/drivers`, getAllDrivers);
router.get(`/api/drivers/:id/`, getDriverById);

export default router;
