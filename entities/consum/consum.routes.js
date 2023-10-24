import { Router } from 'express';

//controllers
import { getAllConsums, processConsums } from './consum.controller.js';

const router = new Router();

router.get(`/api/consums`, getAllConsums);
router.post(`/api/processConsums`, processConsums);

export default router;