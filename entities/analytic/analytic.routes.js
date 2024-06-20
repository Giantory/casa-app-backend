import { Router } from 'express';



//controllers
import { getGallonsPerMonth } from './analytic.controller.js';



const router = new Router();

router.get(`/api/analytic/getGallonsPerMonth`, getGallonsPerMonth);


export default router;