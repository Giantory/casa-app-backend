import { Router } from 'express';

//controllers
import { getAllConsums } from './consum.controller.js';

const router = new Router();

router.get(`/api/consums`, getAllConsums);

export default router;